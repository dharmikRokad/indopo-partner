import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    hide LocalStorage, AuthState;
import 'core/constants/app_strings.dart';
import 'core/network/api_client.dart';
import 'core/network/token_manager.dart';
import 'core/network_copy/local_storage.dart';
import 'core/router/router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/app_config_repo.dart';
import 'data/repositories/auth_repo.dart';
import 'data/repositories/dropdown_repo.dart';
import 'data/repositories/profile_repo.dart';
import 'data/repositories/request_repo.dart';
import 'data/repositories/service_repo.dart';
import 'data/repositories/supabase_chat_repo.dart';
import 'presentation/auth/bloc/auth_bloc.dart';
import 'presentation/auth/bloc/auth_event.dart';
import 'presentation/auth/bloc/auth_state.dart';
import 'core/presentation/widgets/app_snackbar.dart';
import 'presentation/notifications/bloc/notification_bloc.dart';
import 'presentation/notifications/bloc/notification_event.dart';
import 'presentation/notifications/view/notification_overlay_wrapper.dart';
import 'package:indopo_partner/core/services/push_notification_service.dart';
import 'core/deeplink/cubit/deep_link_cubit.dart';
import 'core/deeplink/cubit/deep_link_state.dart';
import 'core/deeplink/models/deep_link_data.dart';
import 'core/deeplink/services/deep_link_service.dart';
import 'core/constants/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 0. Load environment variables from .env
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('[Main] Warning: Could not load .env asset file: $e');
  }

  // 0.5 Initialize Supabase SDK for real-time chat
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
      print('[Main] Supabase initialized successfully');
    } catch (e) {
      print('[Main] Supabase initialization error: $e');
    }
  } else {
    print('[Main] Supabase credentials missing in .env file');
  }

  // 1. Initialize SharedPreferences & LocalStorage service
  final prefs = await SharedPreferences.getInstance();
  final localStorage = LocalStorage(prefs);

  // 1.5 Initialize Push Notification Service
  await PushNotificationService.instance.initialize();

  // 1.6 Initialize Deep Link Service
  await DeepLinkService.instance.initialize();

  // 2. Initialize API Client
  final apiClient = ApiClient();

  // 3. Create repository instances
  final authRepository = AuthRepository(apiClient, localStorage);
  final profileRepository = ProfileRepository(apiClient);
  final requestRepository = RequestRepository(apiClient);
  final serviceRepository = ServiceRepository(apiClient);
  final dropdownRepository = DropdownRepository(apiClient);
  final appConfigRepository = AppConfigRepository();
  final supabaseChatRepository = SupabaseChatRepository(apiClient: apiClient);

  // Trigger dropdown values load immediately when the user opens the app
  dropdownRepository.fetchDropdownValues();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<LocalStorage>.value(value: localStorage),
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<ProfileRepository>.value(value: profileRepository),
        RepositoryProvider<RequestRepository>.value(value: requestRepository),
        RepositoryProvider<ServiceRepository>.value(value: serviceRepository),
        RepositoryProvider<DropdownRepository>.value(value: dropdownRepository),
        RepositoryProvider<AppConfigRepository>.value(
          value: appConfigRepository,
        ),
        RepositoryProvider<SupabaseChatRepository>.value(
          value: supabaseChatRepository,
        ),
      ],
      child: const IndopoPartnerApp(),
    ),
  );
}

class IndopoPartnerApp extends StatefulWidget {
  const IndopoPartnerApp({super.key});

  @override
  State<IndopoPartnerApp> createState() => _IndopoPartnerAppState();
}

class _IndopoPartnerAppState extends State<IndopoPartnerApp> {
  late AuthBloc _authBloc;
  late NotificationBloc _notificationBloc;
  late DeepLinkCubit _deepLinkCubit;
  late AppRouter _appRouter;
  StreamSubscription? _sessionExpirySubscription;

  @override
  void initState() {
    super.initState();
    // 4. Initialize Core Root BLoCs
    _authBloc = AuthBloc(
      authRepository: context.read<AuthRepository>(),
      localStorage: context.read<LocalStorage>(),
    );

    _notificationBloc = NotificationBloc()..add(InitNotifications());
    _deepLinkCubit = DeepLinkCubit();

    // 5. Initialize GoRouter Router configuration
    _appRouter = AppRouter(_authBloc);

    // 6. Listen to global token refresh failures to auto-logout the user
    _sessionExpirySubscription = TokenManager.instance.sessionExpiryStream
        .listen((_) {
          _authBloc.add(LogoutRequested());
        });
  }

  @override
  void dispose() {
    _sessionExpirySubscription?.cancel();
    _authBloc.close();
    _notificationBloc.close();
    _deepLinkCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<NotificationBloc>.value(value: _notificationBloc),
        BlocProvider<DeepLinkCubit>.value(value: _deepLinkCubit),
      ],
      child: BlocListener<DeepLinkCubit, DeepLinkState>(
        listener: (context, state) {
          final link = state.pendingDeepLink;
          if (link != null) {
            if (link.type == DeepLinkType.resetPassword) {
              final token = link.token;
              if (token != null && token.isNotEmpty) {
                _appRouter.router.go(
                  '${AppRoutes.resetPassword}?token=${Uri.encodeComponent(token)}',
                );
              } else {
                _appRouter.router.go(AppRoutes.login);
                AppSnackBar.showError(
                  context,
                  'Something went wrong: Invalid or missing password reset token.',
                );
              }
            }
            _deepLinkCubit.consumeDeepLink();
          }
        },
        child: MaterialApp.router(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          routerConfig: _appRouter.router,
          builder: (context, child) {
            return BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state.status == AuthBlocStatus.accountSuspended) {
                  AppSnackBar.showError(
                    context,
                    state.errorMessage ?? 'Account suspended',
                  );
                }
              },
              child: NotificationOverlayWrapper(child: child!),
            );
          },
        ),
      ),
    );
  }
}
