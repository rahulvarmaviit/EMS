import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/api/api_client.dart';
import '../../models/attendance.dart';
import '../../models/user.dart';
import '../attendance/employee_home_screen.dart';

class LeadDashboard extends StatefulWidget {
  const LeadDashboard({super.key});

  @override
  State<LeadDashboard> createState() => _LeadDashboardState();
}

class _LeadDashboardState extends State<LeadDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _apiClient = ApiClient();
  List<Attendance> _teamAttendance = [];
  List<User> _teamMembers = [];
  bool _isLoading = true;
  String? _teamId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTeamData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTeamData() async {
    setState(() => _isLoading = true);
    
    try {
      // Get team info first
      final teamsResponse = await _apiClient.get('/api/teams');
      if (teamsResponse['success'] == true) {
        final teams = teamsResponse['data']['teams'] as List;
        final user = context.read<AuthProvider>().user;
        
        // Find the team where user is lead
        for (var team in teams) {
          if (team['lead_id'] == user?.id) {
            _teamId = team['id'];
            break;
          }
        }
      }
      
      if (_teamId != null) {
        // Get team members (filter by team_id)
        final usersResponse = await _apiClient.get('/api/users');
        if (usersResponse['success'] == true) {
          _teamMembers = (usersResponse['data']['users'] as List)
              .map((json) => User.fromJson(json))
              .where((user) => user.teamId == _teamId)
              .toList();
        }
        
        // Get today's attendance
        final today = DateTime.now().toIso8601String().split('T')[0];
        final attendanceResponse = await _apiClient.get(
          '/api/attendance/team/$_teamId?date=$today'
        );
        if (attendanceResponse['success'] == true) {
          _teamAttendance = (attendanceResponse['data']['attendance'] as List)
              .map((json) => Attendance.fromJson(json))
              .toList();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Lead Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Team'),
            Tab(text: 'My Attendance'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTeamView(),
          const EmployeeHomeScreen(),
        ],
      ),
    );
  }

  Widget _buildTeamView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadTeamData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Today's Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today - ${DateFormat('MMMM d, yyyy').format(DateTime.now())}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          'Present',
                          _teamAttendance.where((a) => a.status == 'PRESENT').length,
                          Colors.green,
                        ),
                        _buildSummaryItem(
                          'Late',
                          _teamAttendance.where((a) => a.status == 'LATE').length,
                          Colors.orange,
                        ),
                        _buildSummaryItem(
                          'Absent',
                          _teamMembers.length - _teamAttendance.length,
                          Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Team Members
            const Text(
              'Team Members',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._teamMembers.map((member) => _buildMemberCard(member)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }

  Widget _buildMemberCard(User member) {
    // Safely find attendance record for this member
    final attendanceRecords = _teamAttendance.where(
      (a) => a.userName == member.fullName,
    );
    final attendance = attendanceRecords.isNotEmpty ? attendanceRecords.first : null;
    
    final isPresent = attendance != null;
    final status = attendance?.status ?? 'ABSENT';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPresent
              ? (status == 'PRESENT' ? Colors.green : Colors.orange)
              : Colors.red,
          child: Text(
            member.fullName.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(member.fullName),
        subtitle: isPresent
            ? Text('In: ${DateFormat('h:mm a').format(attendance!.checkInTime)}')
            : const Text('Not checked in'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isPresent
                ? (status == 'PRESENT' ? Colors.green : Colors.orange)
                : Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isPresent ? (status == 'PRESENT' ? 'Present' : 'Late') : 'Absent',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
