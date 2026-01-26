import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/auth/auth_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/attendance/attendance_provider.dart';
import 'features/login/auth_screen.dart';
import 'features/attendance/employee_home_screen.dart';
import 'features/dashboard/admin_dashboard.dart';
import 'features/lead/lead_dashboard.dart';

void main() {
  runApp(const EmsApp());
}

class EmsApp extends StatelessWidget {
  const EmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
      ],
      child: MaterialApp(
        title: 'EMS - Geo Attendance',
        debugShowCheckedModeBanner: false,
        theme: createAppTheme(),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<AuthProvider>().checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        // Show loading screen while checking auth status
        if (auth.status == AuthStatus.initial ||
            auth.status == AuthStatus.loading) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time_filled,
                      size: 64, color: AppColors.primary),
                  const SizedBox(height: AppSpacing.md),
                  CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: AppSpacing.md),
                  Text('Loading...', style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
          );
        }

        // Show auth screen (login/signup) if not authenticated
        if (!auth.isAuthenticated) {
          return const AuthScreen();
        }

        // Route based on user role
        final user = auth.user;
        if (user == null) {
          return const AuthScreen();
        }

        switch (user.role) {
          case 'ADMIN':
            return const AdminDashboard();
          case 'LEAD':
            return const LeadDashboard();
          case 'EMPLOYEE':
          default:
            return const EmployeeHomeScreen();
        }
      },
    );
  }
}
