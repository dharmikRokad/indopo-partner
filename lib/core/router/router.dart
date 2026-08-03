import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/auth/bloc/auth_bloc.dart';
import '../../presentation/auth/bloc/auth_state.dart';
import '../../presentation/auth/view/login_screen.dart';
import '../../presentation/auth/view/reset_password_screen.dart';
import '../../presentation/chat/view/chat_screen.dart';
import '../../presentation/profile_setup/view/profile_setup_screen.dart';
import '../../presentation/schedule_setup/view/schedule_setup_screen.dart';
import '../../presentation/requests/view/request_detail_screen.dart';
import '../../data/models/request_model.dart';
import '../../presentation/home/view/main_layout_screen.dart';
import '../../presentation/splash/view/splash_view.dart';
import '../../presentation/services/view/services_screen.dart';
import '../constants/app_routes.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  final AuthBloc authBloc;

  AppRouter(this.authBloc);

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (BuildContext context, GoRouterState state) {
      final authState = authBloc.state;
      final currentLoc = state.matchedLocation;

      // 1. Initial State -> Allow splash screen initialization
      if (authState.status == AuthBlocStatus.initial) {
        if (currentLoc == AppRoutes.splash) {
          return null;
        }
        return AppRoutes.splash;
      }

      // 2. Not Authenticated / Auth-screen-only States
      const _unauthenticatedStatuses = {
        AuthBlocStatus.unauthenticated,
        AuthBlocStatus.roleChosen,
        AuthBlocStatus.error,
        AuthBlocStatus.accountSuspended,
        AuthBlocStatus.forgotPasswordLoading,
        AuthBlocStatus.forgotPasswordSuccess,
        AuthBlocStatus.forgotPasswordFailure,
        AuthBlocStatus.resetPasswordLoading,
        AuthBlocStatus.resetPasswordSuccess,
        AuthBlocStatus.resetPasswordFailure,
      };

      if (_unauthenticatedStatuses.contains(authState.status)) {
        if (currentLoc == AppRoutes.login ||
            currentLoc == AppRoutes.resetPassword) {
          return null;
        }
        return AppRoutes.login;
      }

      // 3. Authenticated State
      if (authState.status == AuthBlocStatus.authenticated &&
          authState.partner != null) {
        final partner = authState.partner!;
        final isSetupConfigured = partner.isProfileConfigured;

        if (!isSetupConfigured) {
          // If profile setup is not completed, force user to profile setup screen
          if (currentLoc == AppRoutes.profileSetup) {
            return null;
          }
          return AppRoutes.profileSetup;
        } else {
          // Check if working days and times are set
          final hasSchedule =
              partner.workingDays != null &&
              partner.workingDays!.isNotEmpty &&
              partner.openTime != null &&
              partner.openTime!.isNotEmpty &&
              partner.closeTime != null &&
              partner.closeTime!.isNotEmpty;

          if (!hasSchedule) {
            if (currentLoc == AppRoutes.scheduleSetup) {
              return null;
            }
            return AppRoutes.scheduleSetup;
          }

          // If profile setup and schedule are completed, user cannot visit login, profile setup, or schedule setup
          final isRestrictedRoute =
              currentLoc == AppRoutes.login ||
              currentLoc == AppRoutes.profileSetup ||
              currentLoc == AppRoutes.scheduleSetup ||
              currentLoc == AppRoutes.splash;
          if (isRestrictedRoute) {
            return AppRoutes.requestList;
          }
          return null;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashView(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileSetup,
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.requestList,
        builder: (context, state) => const MainLayoutScreen(),
      ),
      GoRoute(
        path: AppRoutes.requestDetail,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final request = state.extra as RequestModel?;
          return RequestDetailScreen(id: id, request: request);
        },
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ChatScreen(id: id);
        },
      ),
      GoRoute(
        path: AppRoutes.services,
        builder: (context, state) => const ServicesScreen(),
      ),
      GoRoute(
        path: AppRoutes.scheduleSetup,
        builder: (context, state) => const ScheduleSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) {
          final token =
              state.uri.queryParameters['token'] ??
              (state.extra is String ? state.extra as String : null);
          return ResetPasswordScreen(token: token);
        },
      ),
    ],
  );
}
