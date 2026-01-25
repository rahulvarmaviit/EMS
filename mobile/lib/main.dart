import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/auth/auth_provider.dart';
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
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
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
    // Check if user is already logged in
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
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time_filled, size: 64, color: Colors.blue),
                  SizedBox(height: 16),
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
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
          return const LoginScreen();
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
