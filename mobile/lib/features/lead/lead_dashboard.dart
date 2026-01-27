import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/components/components.dart';
import '../../models/attendance.dart';
import '../../models/user.dart';
import '../attendance/employee_home_screen.dart';
import '../profile/profile_screen.dart';
import '../shared/app_drawer.dart';
import '../admin/user_details_screen.dart';

class LeadDashboard extends StatefulWidget {
  const LeadDashboard({super.key});

  @override
  State<LeadDashboard> createState() => _LeadDashboardState();
}

class _LeadDashboardState extends State<LeadDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _apiClient = ApiClient();
  List<Attendance> _teamAttendance = [];
  List<User> _teamMembers = [];
  bool _isLoading = true;
  String? _error;
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
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get team info first
      final teamsResponse = await _apiClient.get('/api/teams');
      if (teamsResponse['success'] == true) {
        final teams = teamsResponse['data']['teams'] as List;
        if (!mounted) return;
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
        // Get team members
        final usersResponse = await _apiClient.get('/api/users');
        if (usersResponse['success'] == true) {
          if (!mounted) return;
          final currentUser = context.read<AuthProvider>().user;
          _teamMembers = (usersResponse['data']['users'] as List)
              .map((json) => User.fromJson(json))
              .where((user) =>
                  user.teamId == _teamId && user.id != currentUser?.id)
              .toList();
        }

        // Get today's attendance
        final today = DateTime.now().toIso8601String().split('T')[0];
        final attendanceResponse =
            await _apiClient.get('/api/attendance/team/$_teamId?date=$today');
        if (attendanceResponse['success'] == true) {
          _teamAttendance = (attendanceResponse['data']['attendance'] as List)
              .map((json) => Attendance.fromJson(json))
              .toList();
        }
      }
    } catch (e) {
      _error = 'Failed to load team data';
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  int get _presentCount =>
      _teamAttendance.where((a) => a.status == 'PRESENT').length;
  int get _lateCount => _teamAttendance.where((a) => a.status == 'LATE').length;
  int get _absentCount => _teamMembers.length - _teamAttendance.length;

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('AKH Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: _navigateToProfile,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Team'),
            Tab(icon: Icon(Icons.access_time), text: 'My Attendance'),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Background - Consistent with Employee Home
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

          // Tab Content
          TabBarView(
            controller: _tabController,
            children: [
              _buildTeamView(),
              const EmployeeHomeScreen(isEmbedded: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamView() {
    if (_isLoading) {
      return const LoadingOverlay(message: 'Loading team data...');
    }

    if (_error != null) {
      return ErrorState(
        message: _error!,
        onRetry: _loadTeamData,
      );
    }

    if (_teamId == null) {
      return const EmptyState(
        icon: Icons.group_off,
        title: 'No Team Assigned',
        subtitle: 'You are not assigned as lead to any team.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTeamData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                style: AppTextStyles.bodyMedium,
              ),
            ),

            // Stats Summary
            StatsSummaryCard(
              presentCount: _presentCount,
              lateCount: _lateCount,
              absentCount: _absentCount,
              totalCount: _teamMembers.length,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Team Members
            SectionHeader(
              title: 'Team Members (${_teamMembers.length})',
            ),
            const SizedBox(height: AppSpacing.sm),

            if (_teamMembers.isEmpty)
              const EmptyState(
                icon: Icons.person_off,
                title: 'No team members',
                subtitle: 'Ask admin to assign employees to your team.',
              )
            else
              ...List.generate(_teamMembers.length, (index) {
                final member = _teamMembers[index];
                final attendance = _teamAttendance.firstWhere(
                  (a) => a.userId == member.id,
                  orElse: () => Attendance.empty(),
                );

                final isPresent = attendance.id.isNotEmpty;
                final isLate = attendance.status == 'LATE';
                final checkInTime = isPresent
                    ? DateFormat('h:mm a')
                        .format(attendance.checkInTime.toLocal())
                    : null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: TeamMemberTile(
                    user: member,
                    isPresent: isPresent,
                    isLate: isLate,
                    checkInTime: checkInTime,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminUserDetailsScreen(user: member),
                        ),
                      );
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
