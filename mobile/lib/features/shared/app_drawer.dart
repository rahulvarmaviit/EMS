import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../attendance/attendance_screen.dart';
import '../leave/leave_screen.dart';
import '../todo/todo_screen.dart';
import '../documents/documents_screen.dart';
import '../profile/profile_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      horizontalTitleGap: 0,
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    // final attendanceProvider = context.watch<AttendanceProvider>(); // Not used in drawer
    final user = authProvider.user;

    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E003E),
              Colors.black,
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              child: InkWell(
                onTap: () => _navigateToProfile(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        (user?.fullName.isNotEmpty == true)
                            ? user!.fullName.substring(0, 1).toUpperCase()
                            : 'A',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'AKH Dashboard',
                      style: AppTextStyles.titleLarge
                          .copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.dashboard,
              title: 'Dashboard',
              onTap: () {
                Navigator.pop(context); // Already on Dashboard
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.check_circle_outline,
              title: 'Attendance',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AttendanceScreen()),
                );
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.calendar_today,
              title: 'Leave',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LeaveScreen()),
                );
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.checklist,
              title: "To Do's",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TodoScreen()),
                );
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.folder,
              title: 'Documents',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DocumentsScreen()),
                );
              },
            ),
            // Added Logout for convenience since we removed it from AppBar
          ],
        ),
      ),
    );
  }
}
