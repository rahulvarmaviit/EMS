import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/api/api_client.dart';
import '../../models/team.dart';
import '../../models/user.dart';
import '../admin/location_management_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ApiClient _apiClient = ApiClient();
  List<Team> _teams = [];
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final teamsResponse = await _apiClient.get('/api/teams');
      final usersResponse = await _apiClient.get('/api/users');

      if (teamsResponse['success'] == true) {
        _teams = (teamsResponse['data']['teams'] as List)
            .map((json) => Team.fromJson(json))
            .toList();
      }

      if (usersResponse['success'] == true) {
        _users = (usersResponse['data']['users'] as List)
            .map((json) => User.fromJson(json))
            .toList();
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
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            tooltip: 'Manage Locations',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const LocationManagementScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Users',
                            _users.length.toString(),
                            Icons.people,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Teams',
                            _teams.length.toString(),
                            Icons.groups,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Teams Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Teams',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.add_circle, color: Colors.blue),
                          onPressed: () => _showCreateTeamDialog(),
                        ),
                      ],
                    ),
                    ..._teams.map((team) => _buildTeamCard(team)),

                    const SizedBox(height: 24),

                    // Users Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Users',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.person_add, color: Colors.blue),
                          onPressed: () => _showCreateUserDialog(),
                        ),
                      ],
                    ),
                    ..._users.map((user) => _buildUserCard(user)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCard(Team team) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.groups, color: Colors.white),
        ),
        title: Text(team.name),
        subtitle: Text(team.leadName != null
            ? 'Lead: ${team.leadName}'
            : 'No lead assigned'),
        trailing: Text('${team.memberCount ?? 0} members'),
      ),
    );
  }

  Widget _buildUserCard(User user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => _showAssignTeamDialog(user),
        leading: CircleAvatar(
          backgroundColor: user.isAdmin
              ? Colors.purple
              : user.isLead
                  ? Colors.orange
                  : Colors.green,
          child: Text(
            user.fullName.isNotEmpty
                ? user.fullName.substring(0, 1).toUpperCase()
                : 'U',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(user.fullName),
        subtitle: Text('${user.role} | ${user.teamName ?? "No team"}'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  void _showAssignTeamDialog(User user) {
    String? selectedTeamId = user.teamId;
    bool makeLead = user.isLead;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Manage ${user.fullName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phone: ${user.mobileNumber}',
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  'Current Role: ${user.role}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),

                // Team Assignment
                DropdownButtonFormField<String?>(
                  value: selectedTeamId,
                  decoration: const InputDecoration(
                    labelText: 'Assign to Team',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('No Team'),
                    ),
                    ..._teams.map((team) => DropdownMenuItem(
                          value: team.id,
                          child: Text(team.name),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedTeamId = value;
                      if (value == null) makeLead = false;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Make Team Lead checkbox (only show if team is selected and not admin)
                if (selectedTeamId != null && !user.isAdmin)
                  CheckboxListTile(
                    title: const Text('Make Team Lead'),
                    subtitle: const Text('Promotes user to LEAD role'),
                    value: makeLead,
                    onChanged: (value) {
                      setState(() => makeLead = value ?? false);
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _apiClient.patch('/api/users/${user.id}/assign-team', {
                    'team_id': selectedTeamId,
                    'is_lead': makeLead,
                  });
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Team assignment updated'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTeamDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Team'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Team Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                try {
                  await _apiClient.post('/api/teams', {
                    'name': nameController.text,
                  });
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _loadData();
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showCreateUserDialog() {
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'EMPLOYEE';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: mobileController,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                    hintText: '+1234567890',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'EMPLOYEE', child: Text('Employee')),
                    DropdownMenuItem(value: 'LEAD', child: Text('Team Lead')),
                    DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                  ],
                  onChanged: (value) {
                    setState(() => selectedRole = value!);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    mobileController.text.isNotEmpty &&
                    passwordController.text.isNotEmpty) {
                  try {
                    await _apiClient.post('/api/auth/register', {
                      'full_name': nameController.text,
                      'mobile_number': mobileController.text,
                      'password': passwordController.text,
                      'role': selectedRole,
                    });
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _loadData();
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
