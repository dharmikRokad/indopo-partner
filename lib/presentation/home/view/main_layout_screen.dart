import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/partner_type.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../chat_list/view/chats_list_screen.dart';
import '../../profile/view/profile_screen.dart';
import '../../requests/view/medical_requests_screen.dart';
import '../../requests/view/request_list_screen.dart';
import '../../../core/presentation/bloc/value_cubit.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  final _navigationCubit = ValueCubit<int>(0);

  @override
  void dispose() {
    _navigationCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is! AuthSuccess) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final partner = authState.partner;
    final isMedical = partner.role == PartnerType.medical;

    // Dynamically build screens & items based on role
    final List<Widget> screens = [
      isMedical ? const MedicalRequestsScreen() : const RequestListScreen(),
      if (isMedical) const ChatsListScreen(),
      const ProfileScreen(),
    ];

    final List<BottomNavigationBarItem> items = [
      BottomNavigationBarItem(
        icon: Icon(isMedical ? Icons.medication_outlined : Icons.assignment_outlined),
        activeIcon: Icon(isMedical ? Icons.medication_rounded : Icons.assignment_rounded),
        label: isMedical ? 'Prescriptions' : 'Requests',
      ),
      if (isMedical)
        const BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline_rounded),
          activeIcon: Icon(Icons.chat_bubble_rounded),
          label: 'Chats',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline_rounded),
        activeIcon: Icon(Icons.person_rounded),
        label: 'Profile',
      ),
    ];

    return BlocBuilder<ValueCubit<int>, int>(
      bloc: _navigationCubit,
      builder: (context, currentIndex) {
        return Scaffold(
          body: IndexedStack(
            index: currentIndex,
            children: screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.surface.withValues(alpha: 0.8),
                  width: 1,
                ),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (index) {
                _navigationCubit.update(index);
              },
              backgroundColor: AppColors.surface,
              selectedItemColor: AppColors.blue1,
              unselectedItemColor: AppColors.textMuted,
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              items: items,
            ),
          ),
        );
      },
    );
  }
}
