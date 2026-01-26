import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/components/glass_components.dart';
import '../profile/profile_screen.dart';
import 'attendance_provider.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  bool _isGettingLocation = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAttendance();
    });
  }

  Future<void> _loadAttendance() async {
    await context.read<AttendanceProvider>().fetchHistory();
  }

  Future<Position?> _getCurrentPosition() async {
    setState(() {
      _isGettingLocation = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Location services are disabled. Please enable GPS.';
          _isGettingLocation = false;
        });
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Location permissions are denied.';
            _isGettingLocation = false;
          });
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError =
              'Location permissions are permanently denied. Please enable in settings.';
          _isGettingLocation = false;
        });
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() => _isGettingLocation = false);
      return position;
    } catch (e) {
      setState(() {
        _locationError = 'Failed to get location. Please try again.';
        _isGettingLocation = false;
      });
      return null;
    }
  }

  Future<void> _handleCheckIn() async {
    final position = await _getCurrentPosition();
    if (position == null) return;

    if (!mounted) return;
    final attendanceProvider = context.read<AttendanceProvider>();
    final success = await attendanceProvider.checkIn(
      position.latitude,
      position.longitude,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Checked in successfully!'
              : attendanceProvider.error ?? 'Check-in failed'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleCheckOut() async {
    final position = await _getCurrentPosition();
    if (position == null) return;

    if (!mounted) return;
    final attendanceProvider = context.read<AttendanceProvider>();
    final success = await attendanceProvider.checkOut(
      position.latitude,
      position.longitude,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Checked out successfully!'
              : attendanceProvider.error ?? 'Check-out failed'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();
    final user = authProvider.user;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('AKH Dashboard'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: _navigateToProfile,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2E003E),
                  Colors.black,
                  Colors.black,
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadAttendance,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Welcome Header
                    GlassContainer(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            user?.fullName ?? 'User',
                            style: AppTextStyles.displayMedium.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                          if (user?.teamName != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              user!.teamName!,
                              style: AppTextStyles.bodyLarge,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Actions
                    if (_locationError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: GlassContainer(
                          color: AppColors.error.withOpacity(0.1),
                          borderColor: AppColors.error.withOpacity(0.3),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppColors.error),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  _locationError!,
                                  style:
                                      const TextStyle(color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (attendanceProvider.isCheckedIn)
                      if (attendanceProvider.isCheckedOut)
                        GlassButton(
                          text: 'Day Complete',
                          icon: Icons.check_circle,
                          isLoading: false,
                          onPressed: () {}, // Disabled action
                        )
                      else
                        GlassButton(
                          text: 'Check Out',
                          icon: Icons.logout,
                          isLoading: attendanceProvider.isLoading ||
                              _isGettingLocation,
                          onPressed: _handleCheckOut,
                        )
                    else
                      GlassButton(
                        text: 'Check In',
                        icon: Icons.login,
                        isLoading:
                            attendanceProvider.isLoading || _isGettingLocation,
                        onPressed: _handleCheckIn,
                      ),

                    const SizedBox(height: AppSpacing.xl),
                    Text('History', style: AppTextStyles.titleLarge),
                    const SizedBox(height: AppSpacing.md),

                    // List
                    if (attendanceProvider.history.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Center(
                          child: Text(
                            'No attendance history found',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      )
                    else
                      ...attendanceProvider.history.take(5).map((attendance) {
                        final isPresent = attendance.status == 'PRESENT';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: GlassContainer(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: isPresent
                                        ? AppColors.success.withOpacity(0.1)
                                        : AppColors.warning.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isPresent
                                        ? Icons.check_circle
                                        : Icons.warning,
                                    color: isPresent
                                        ? AppColors.success
                                        : AppColors.warning,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        DateFormat('MMM dd, yyyy')
                                            .format(attendance.date),
                                        style: AppTextStyles.labelLarge,
                                      ),
                                      Text(
                                        'In: ${DateFormat('h:mm a').format(attendance.checkInTime)}',
                                        style: AppTextStyles.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                if (attendance.checkOutTime != null)
                                  Text(
                                    'Out: ${DateFormat('h:mm a').format(attendance.checkOutTime!)}',
                                    style: AppTextStyles.bodyMedium,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
