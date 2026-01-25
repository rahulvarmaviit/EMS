import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../core/auth/auth_provider.dart';
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
    _loadAttendance();
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
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Location services are disabled. Please enable GPS.';
          _isGettingLocation = false;
        });
        return null;
      }

      // Check permissions
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
          _locationError = 'Location permissions are permanently denied. Please enable in settings.';
          _isGettingLocation = false;
        });
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _isGettingLocation = false;
      });

      return position;
    } catch (e) {
      setState(() {
        _locationError = 'Failed to get location: ${e.toString()}';
        _isGettingLocation = false;
      });
      return null;
    }
  }

  Future<void> _handleCheckIn() async {
    final position = await _getCurrentPosition();
    if (position == null) return;

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
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _handleCheckOut() async {
    final position = await _getCurrentPosition();
    if (position == null) return;

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
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EMS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAttendance,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${user?.fullName ?? "User"}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (user?.teamName != null)
                        Text(
                          'Team: ${user!.teamName}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Check In/Out Button
              if (attendanceProvider.isLoading || _isGettingLocation)
                const Center(child: CircularProgressIndicator())
              else if (!attendanceProvider.isCheckedIn)
                _buildCheckInButton()
              else if (!attendanceProvider.isCheckedOut)
                _buildCheckOutButton(attendanceProvider)
              else
                _buildCompletedCard(attendanceProvider),

              // Location Error
              if (_locationError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _locationError!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 24),

              // Attendance History
              const Text(
                'Recent Attendance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...attendanceProvider.history.take(7).map((attendance) =>
                  _buildHistoryItem(attendance)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckInButton() {
    return ElevatedButton.icon(
      onPressed: _handleCheckIn,
      icon: const Icon(Icons.login, size: 32),
      label: const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text('CHECK IN', style: TextStyle(fontSize: 24)),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildCheckOutButton(AttendanceProvider provider) {
    final checkInTime = provider.todayAttendance?.checkInTime;
    return Column(
      children: [
        Card(
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 32),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Checked in at', style: TextStyle(color: Colors.grey)),
                    Text(
                      checkInTime != null
                          ? DateFormat('h:mm a').format(checkInTime)
                          : '--:--',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _handleCheckOut,
          icon: const Icon(Icons.logout, size: 32),
          label: const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('CHECK OUT', style: TextStyle(fontSize: 24)),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedCard(AttendanceProvider provider) {
    final attendance = provider.todayAttendance!;
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.blue, size: 48),
            const SizedBox(height: 8),
            const Text(
              'Attendance Complete',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text('Check In', style: TextStyle(color: Colors.grey)),
                    Text(
                      DateFormat('h:mm a').format(attendance.checkInTime),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('Check Out', style: TextStyle(color: Colors.grey)),
                    Text(
                      attendance.checkOutTime != null
                          ? DateFormat('h:mm a').format(attendance.checkOutTime!)
                          : '--:--',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('Status', style: TextStyle(color: Colors.grey)),
                    Text(
                      attendance.statusDisplay,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: attendance.status == 'PRESENT' 
                            ? Colors.green 
                            : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(attendance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: attendance.status == 'PRESENT'
              ? Colors.green
              : attendance.status == 'LATE'
                  ? Colors.orange
                  : Colors.red,
          child: const Icon(Icons.calendar_today, color: Colors.white),
        ),
        title: Text(attendance.date),
        subtitle: Text(
          'In: ${DateFormat('h:mm a').format(attendance.checkInTime)}' +
              (attendance.checkOutTime != null
                  ? ' | Out: ${DateFormat('h:mm a').format(attendance.checkOutTime!)}'
                  : ''),
        ),
        trailing: Text(
          attendance.statusDisplay,
          style: TextStyle(
            color: attendance.status == 'PRESENT'
                ? Colors.green
                : Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
