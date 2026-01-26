import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/components/glass_components.dart';
import '../../models/team.dart';
import '../../models/user.dart';
import 'user_details_screen.dart';

class TeamDetailsScreen extends StatefulWidget {
  final Team team;

  const TeamDetailsScreen({super.key, required this.team});

  @override
  State<TeamDetailsScreen> createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends State<TeamDetailsScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic>? _teamDetails;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _todayAttendance = [];

  @override
  void initState() {
    super.initState();
    _loadTeamDetails();
  }

  Future<void> _loadTeamDetails() async {
    setState(() => _isLoading = true);

    try {
      // Fetch team details with members
      final teamResponse = await _apiClient.get('/api/teams/${widget.team.id}');

      // Fetch today's attendance for the team
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final attendanceResponse = await _apiClient
          .get('/api/attendance/team/${widget.team.id}?date=$today');

      if (teamResponse['success'] == true) {
        setState(() {
          _teamDetails = teamResponse['data']['team'];
          _members = List<Map<String, dynamic>>.from(
              teamResponse['data']['members'] ?? []);
        });
      }

      if (attendanceResponse['success'] == true) {
        setState(() {
          _todayAttendance = List<Map<String, dynamic>>.from(
              attendanceResponse['data']['attendance'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error loading team details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isMemberPresent(String userId) {
    final isPresent = _todayAttendance.any((attendance) {
      debugPrint(
          'Checking attendance userId: ${attendance['user_id']} against member: $userId');
      return attendance['user_id'] == userId;
    });
    debugPrint('Member $userId present: $isPresent');
    return isPresent;
  }

  Map<String, dynamic>? _getMemberAttendance(String userId) {
    try {
      return _todayAttendance
          .firstWhere((attendance) => attendance['user_id'] == userId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.team.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTeamDetails,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Team Header
                    _buildTeamHeader(),
                    const SizedBox(height: AppSpacing.lg),

                    // Team Lead Section
                    if (_teamDetails?['lead_name'] != null) ...[
                      _buildSectionTitle('Team Lead'),
                      const SizedBox(height: AppSpacing.sm),
                      _buildLeadCard(),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Today's Attendance Section
                    _buildSectionTitle('Today\'s Attendance'),
                    const SizedBox(height: AppSpacing.sm),
                    _buildAttendanceSummary(),
                    const SizedBox(height: AppSpacing.lg),

                    // Team Members Section
                    _buildSectionTitle('Team Members (${_members.length})'),
                    const SizedBox(height: AppSpacing.sm),
                    if (_members.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: Text(
                            'No members in this team',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      )
                    else
                      ..._members.map((member) => _buildMemberCard(member)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTeamHeader() {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.groups,
              color: AppColors.secondary,
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.team.name,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_members.length} ${_members.length == 1 ? 'Member' : 'Members'}',
                  style: const TextStyle(color: Colors.white60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.titleMedium.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildLeadCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.orange,
            child: Text(
              (_teamDetails!['lead_name'] as String)
                  .substring(0, 1)
                  .toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _teamDetails!['lead_name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _teamDetails!['lead_mobile'] ?? '',
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.5)),
            ),
            child: const Text(
              'LEAD',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSummary() {
    final presentCount = _todayAttendance.length;
    final totalMembers = _members.length;
    final absentCount = totalMembers - presentCount;

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildAttendanceStat('Present', presentCount, AppColors.success),
          Container(height: 40, width: 1, color: Colors.white24),
          _buildAttendanceStat('Absent', absentCount, AppColors.error),
        ],
      ),
    );
  }

  Widget _buildAttendanceStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final isPresent = _isMemberPresent(member['id']);
    final attendance = _getMemberAttendance(member['id']);
    final role = member['role'] ?? 'EMPLOYEE';

    Color roleColor = Colors.green;
    if (role == 'LEAD') roleColor = Colors.orange;
    if (role == 'ADMIN') roleColor = Colors.purple;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GestureDetector(
        onTap: () {
          // Navigate to user details screen
          final user = User(
            id: member['id'],
            mobileNumber: member['mobile_number'] ?? '',
            fullName: member['full_name'],
            role: role,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminUserDetailsScreen(user: user),
            ),
          );
        },
        child: GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Avatar with status indicator
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: roleColor,
                    child: Text(
                      (member['full_name'] as String)
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isPresent ? AppColors.success : AppColors.error,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.background, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member['full_name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      member['mobile_number'] ?? '',
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                    if (isPresent && attendance != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'In: ${DateFormat('h:mm a').format(DateTime.parse(attendance['check_in_time']).toLocal())}',
                        style:
                            const TextStyle(color: Colors.green, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: roleColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      role,
                      style: TextStyle(
                        color: roleColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isPresent ? AppColors.success : AppColors.error)
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isPresent ? 'Present' : 'Absent',
                      style: TextStyle(
                        color: isPresent ? AppColors.success : AppColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
