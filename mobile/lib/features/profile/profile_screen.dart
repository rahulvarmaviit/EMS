import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/api/api_client.dart';
import '../../models/user.dart';
import '../../models/team.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiClient _apiClient = ApiClient();
  User? _teamLead;
  Team? _team;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = context.read<AuthProvider>().user;
      
      if (user?.teamId != null) {
        // Get team info from teams API (accessible to all users)
        final teamsResponse = await _apiClient.get('/api/teams');
        if (teamsResponse['success'] == true) {
          final teams = (teamsResponse['data']['teams'] as List)
              .map((json) => Team.fromJson(json))
              .toList();
          
          // Safely find team
          final teamRecords = teams.where((t) => t.id == user!.teamId);
          _team = teamRecords.isNotEmpty ? teamRecords.first : null;
          
          // Team lead name is included in team data (lead_name field)
          if (_team?.leadName != null) {
            _teamLead = User(
              id: _team!.leadId ?? '',
              mobileNumber: '',
              fullName: _team!.leadName!,
              role: 'LEAD',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile Avatar
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue,
                      child: Text(
                        (user?.fullName.isNotEmpty == true) 
                            ? user!.fullName.substring(0, 1).toUpperCase() 
                            : 'U',
                        style: const TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Name
                    Text(
                      user?.fullName ?? 'User',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Role Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getRoleColor(user?.role),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        user?.role ?? 'EMPLOYEE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Info Cards
                    _buildInfoCard(
                      icon: Icons.phone,
                      title: 'Mobile Number',
                      value: user?.mobileNumber ?? 'N/A',
                    ),
                    
                    if (_team != null)
                      _buildInfoCard(
                        icon: Icons.groups,
                        title: 'Team',
                        value: _team!.name,
                      ),
                    
                    if (_teamLead != null && user?.role == 'EMPLOYEE')
                      _buildInfoCard(
                        icon: Icons.person,
                        title: 'My Team Lead',
                        value: _teamLead!.fullName,
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => authProvider.logout(),
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'ADMIN':
        return Colors.purple;
      case 'LEAD':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
