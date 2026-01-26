import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/components/glass_components.dart';
import '../profile/profile_screen.dart';
import 'attendance_provider.dart';
import 'widgets/daily_work_log_dialog.dart';

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
              ? 'checked in successfull'
              : attendanceProvider.error ?? 'Check-in failed'),
          backgroundColor: success ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleCheckOut() async {
    final position = await _getCurrentPosition();
    if (position == null) return;

    if (!mounted) return;

    // Show Daily Work Log Dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const DailyWorkLogDialog(),
    );

    if (result == null) return; // Users cancelled

    if (!mounted) return;
    final attendanceProvider = context.read<AttendanceProvider>();
    final success = await attendanceProvider.checkOut(
      position.latitude,
      position.longitude,
      workLog: result,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'checked out successfull'
              : attendanceProvider.error ?? 'Check-out failed'),
          backgroundColor: success ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
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

  Widget _buildAttendanceCard(AttendanceProvider provider) {
    bool isWorking = provider.isCheckedIn && !provider.isCheckedOut;
    // If not checked in today at all
    bool isNotCheckedIn = !provider.isCheckedIn;

    String statusText = isWorking
        ? 'Currently Working'
        : (provider.isCheckedOut ? 'Day Complete' : 'Not Checked In');
    Color statusColor = isWorking
        ? AppColors.success
        : (provider.isCheckedOut ? AppColors.success : AppColors.warning);

    // Status Icon
    IconData statusIcon = isWorking
        ? Icons.access_time_filled
        : (provider.isCheckedOut ? Icons.check_circle : Icons.timer_off);

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.access_time,
                  color: AppColors.primary.withOpacity(0.8)),
              const SizedBox(width: AppSpacing.sm),
              Text(
                "Today's Attendance",
                style: AppTextStyles.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, size: 40, color: statusColor),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  statusText,
                  style: AppTextStyles.titleLarge,
                ),
                if (provider.todayAttendance != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Checked in at ${DateFormat('h:mm a').format(provider.todayAttendance!.checkInTime.toLocal())}',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.primary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (isWorking)
            GlassButton(
              text: 'Check Out',
              icon: Icons.logout,
              isLoading: provider.isLoading || _isGettingLocation,
              color: AppColors.error,
              onPressed: _handleCheckOut,
            )
          else if (isNotCheckedIn)
            GlassButton(
              text: 'Check In',
              icon: Icons.login,
              isLoading: provider.isLoading || _isGettingLocation,
              onPressed: _handleCheckIn,
            )
          else
            GlassButton(
              text: 'Day Complete',
              icon: Icons.check,
              isLoading: false,
              color: AppColors.success,
              onPressed: () {},
            ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventsCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today,
                  color: AppColors.secondary.withOpacity(0.8)),
              const SizedBox(width: AppSpacing.sm),
              Text(
                "Upcoming Events",
                style: AppTextStyles.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Column(
              children: [
                Icon(Icons.event_busy, size: 48, color: Colors.white24),
                const SizedBox(height: AppSpacing.md),
                Text(
                  "No upcoming events",
                  style:
                      AppTextStyles.bodyMedium.copyWith(color: Colors.white54),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
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

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();
    final user = authProvider.user;

    return Scaffold(
      drawer: Drawer(
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
              _buildDrawerItem(
                icon: Icons.dashboard,
                title: 'Dashboard',
                onTap: () {
                  Navigator.pop(context); // Already on Dashboard
                },
              ),
              _buildDrawerItem(
                icon: Icons.check_circle_outline,
                title: 'Attendance',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to Attendance
                },
              ),
              _buildDrawerItem(
                icon: Icons.calendar_today,
                title: 'Leave',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to Leave
                },
              ),
              _buildDrawerItem(
                icon: Icons.checklist,
                title: "To Do's",
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to To Do's
                },
              ),
              _buildDrawerItem(
                icon: Icons.folder,
                title: 'Documents',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to Documents
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text('AKH Dashboard'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: _navigateToProfile,
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
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back, ${user?.fullName ?? "User"}!',
                            style: AppTextStyles.displaySmall
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          const Text(
                            "Here's what's happening with your work today.",
                            style:
                                TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ],
                      ),
                    ),

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

                    // Main Layout
                    // On Mobile, we stack them.
                    _buildAttendanceCard(attendanceProvider),
                    const SizedBox(height: AppSpacing.lg),
                    _buildUpcomingEventsCard(),
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
