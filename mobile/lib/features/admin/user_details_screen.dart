import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/components/glass_components.dart';
import '../../models/user.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminUserDetailsScreen extends StatefulWidget {
  final User user;

  const AdminUserDetailsScreen({super.key, required this.user});

  @override
  State<AdminUserDetailsScreen> createState() => _AdminUserDetailsScreenState();
}

class _AdminUserDetailsScreenState extends State<AdminUserDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;
  List<Map<String, dynamic>> _attendanceHistory = [];
  List<Map<String, dynamic>> _leaveHistory = [];
  List<Map<String, dynamic>> _documents = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchAttendance(),
        _fetchLeaves(),
        _fetchDocuments(),
      ]);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchAttendance() async {
    try {
      final response =
          await _apiClient.get('/api/attendance/user/${widget.user.id}');
      if (response['success'] == true) {
        setState(() {
          _attendanceHistory =
              List<Map<String, dynamic>>.from(response['data']['attendance']);
        });
      }
    } catch (e) {
      debugPrint('Error fetching attendance: $e');
    }
  }

  Future<void> _fetchLeaves() async {
    try {
      final response =
          await _apiClient.get('/api/leaves/user/${widget.user.id}');
      if (response['success'] == true) {
        setState(() {
          _leaveHistory =
              List<Map<String, dynamic>>.from(response['data']['leaves']);
        });
      }
    } catch (e) {
      debugPrint('Error fetching leaves: $e');
    }
  }

  Future<void> _fetchDocuments() async {
    try {
      final response =
          await _apiClient.get('/api/documents/user/${widget.user.id}');
      if (response['success'] == true) {
        setState(() {
          _documents = List<Map<String, dynamic>>.from(
              response['data']['documents'] ?? []);
          debugPrint('Documents fetched: ${_documents.length}');
        });
      }
    } catch (e) {
      debugPrint('Error fetching documents: $e');
    }
  }

  Future<void> _downloadDocument(String docId, String title) async {
    try {
      final token = await _apiClient.getToken();
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication error')),
          );
        }
        return;
      }

      // Construct URL with query token
      final url =
          '${ApiClient.baseUrl}/api/documents/download/$docId?token=$token';
      debugPrint('Launching URL: $url');

      final uri = Uri.parse(url);
      try {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          throw 'Could not launch $url';
        }
      } catch (e) {
        debugPrint('Launch failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open document')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error downloading document: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.user.fullName,
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'reset_password') {
                _showResetPasswordDialog();
              } else if (value == 'change_mobile') {
                _showChangeMobileDialog();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'reset_password',
                child: Row(
                  children: [
                    Icon(Icons.lock_reset, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Reset Password'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'change_mobile',
                child: Row(
                  children: [
                    Icon(Icons.phone_android, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Change Mobile Number'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient
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

          SafeArea(
            child: Column(
              children: [
                _buildProfileHeader(),
                const SizedBox(height: AppSpacing.md),
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  tabs: const [
                    Tab(text: 'Attendance'),
                    Tab(text: 'Leaves'),
                    Tab(text: 'Documents'),
                  ],
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildAttendanceTab(),
                            _buildLeavesTab(),
                            _buildDocumentsTab(),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final avatarColor = widget.user.isAdmin
        ? Colors.purple
        : widget.user.isLead
            ? Colors.orange
            : Colors.green;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: GlassContainer(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: avatarColor,
              child: Text(
                widget.user.fullName.isNotEmpty
                    ? widget.user.fullName.substring(0, 1).toUpperCase()
                    : 'U',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.fullName,
                    style: AppTextStyles.titleLarge.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.user.role} • ${widget.user.teamName ?? "No Team"}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 14, color: Colors.white54),
                      const SizedBox(width: 4),
                      Text(
                        widget.user.mobileNumber,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceTab() {
    if (_attendanceHistory.isEmpty) {
      return Center(
        child: Text(
          'No attendance records found',
          style: AppTextStyles.bodyLarge.copyWith(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _attendanceHistory.length,
      itemBuilder: (context, index) {
        final record = _attendanceHistory[index];
        final date = DateTime.parse(record['date']);
        final checkIn = DateTime.parse(record['check_in_time']).toLocal();
        final checkOut = record['check_out_time'] != null
            ? DateTime.parse(record['check_out_time']).toLocal()
            : null;
        final status = record['status'];

        Color statusColor = AppColors.success;
        if (status == 'LATE') statusColor = AppColors.warning;
        if (status == 'ABSENT') statusColor = AppColors.error;
        if (status == 'HALF_DAY') statusColor = Colors.orange;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: GestureDetector(
            onTap: () {
              // Show work log dialog
              final hasWorkData = record['work_done'] != null &&
                  record['work_done'].toString().isNotEmpty;

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1E1E1E),
                  title: Text(
                    DateFormat('MMM dd, yyyy').format(date),
                    style: const TextStyle(color: Colors.white),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Check-in/out times
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Check In',
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 12),
                                ),
                                Text(
                                  DateFormat('h:mm a').format(checkIn),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Check Out',
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 12),
                                ),
                                Text(
                                  checkOut != null
                                      ? DateFormat('h:mm a').format(checkOut)
                                      : 'Not yet',
                                  style: TextStyle(
                                      color: checkOut != null
                                          ? Colors.white
                                          : Colors.white30,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 24),

                        if (!hasWorkData) ...[
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'No work log available.\nEmployee hasn\'t checked out yet.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                          ),
                        ] else ...[
                          _buildDetailRow('Project', record['project_name']),
                          const SizedBox(height: 8),
                          _buildDetailRow('Work Done', record['work_done']),
                          const SizedBox(height: 8),
                          _buildDetailRow('Meetings', record['meetings']),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                              'Next Day Plan', record['todo_updates']),
                          const SizedBox(height: 8),
                          _buildDetailRow('Notes', record['notes']),
                        ],
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close',
                          style: TextStyle(color: Colors.white60)),
                    ),
                  ],
                ),
              );
            },
            child: GlassContainer(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMM dd, yyyy').format(date),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'In: ${DateFormat('h:mm a').format(checkIn)}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                      if (checkOut != null)
                        Text(
                          'Out: ${DateFormat('h:mm a').format(checkOut)}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        )
                      else
                        const Text(
                          '-- : --',
                          style: TextStyle(color: Colors.white30, fontSize: 13),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
              color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildLeavesTab() {
    if (_leaveHistory.isEmpty) {
      return Center(
        child: Text(
          'No leave requests found',
          style: AppTextStyles.bodyLarge.copyWith(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _leaveHistory.length,
      itemBuilder: (context, index) {
        final leave = _leaveHistory[index];
        final startDate = DateTime.parse(leave['start_date']);
        final endDate = DateTime.parse(leave['end_date']);
        final status = leave['status'];
        final leaveId = leave['id'];

        Color statusColor = AppColors.warning;
        if (status == 'APPROVED') statusColor = AppColors.success;
        if (status == 'REJECTED') statusColor = AppColors.error;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: GlassContainer(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${DateFormat('MMM dd').format(startDate)} - ${DateFormat('MMM dd').format(endDate)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  leave['reason'] ?? 'No reason provided',
                  style: const TextStyle(color: Colors.white70),
                ),
                if (status == 'PENDING') ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () =>
                            _updateLeaveStatus(leaveId, 'REJECTED'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        child: const Text('Reject'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () =>
                            _updateLeaveStatus(leaveId, 'APPROVED'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Approve'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateLeaveStatus(String leaveId, String status) async {
    try {
      final response = await _apiClient
          .patch('/api/leaves/$leaveId/status', {'status': status});

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Leave request ${status.toLowerCase()}'),
              backgroundColor:
                  status == 'APPROVED' ? AppColors.success : AppColors.error,
            ),
          );
          _loadData(); // Refresh list
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildDocumentsTab() {
    if (_documents.isEmpty) {
      return Center(
        child: Text(
          'No documents found',
          style: AppTextStyles.bodyLarge.copyWith(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _documents.length,
      itemBuilder: (context, index) {
        final doc = _documents[index];
        final uploadedAt = DateTime.parse(doc['uploaded_at']).toLocal();

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: GlassContainer(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc['title'] ?? 'Untitled',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy • h:mm a').format(uploadedAt),
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _downloadDocument(doc['id'], doc['title']),
                  icon: const Icon(Icons.download, color: AppColors.secondary),
                  tooltip: 'Download',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showResetPasswordDialog() {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title:
            const Text('Reset Password', style: TextStyle(color: Colors.white)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter a new password for this user.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                _resetCredentials(password: passwordController.text);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showChangeMobileDialog() {
    final mobileController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title:
            const Text('Change Mobile', style: TextStyle(color: Colors.white)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter a new mobile number for this user.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: mobileController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'New Mobile Number',
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length < 10) {
                    return 'Enter a valid mobile number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                _resetCredentials(mobileNumber: mobileController.text);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _resetCredentials(
      {String? password, String? mobileNumber}) async {
    setState(() => _isLoading = true);
    try {
      final body = <String, dynamic>{};
      if (password != null) body['password'] = password;
      if (mobileNumber != null) body['mobile_number'] = mobileNumber;

      final response = await _apiClient.patch(
        '/api/users/${widget.user.id}/reset-credentials',
        body,
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Credentials updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          // Reload data if needed, or update local state if mobile changed
          // For now just stay on page
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(response['error'] ?? 'Failed to update credentials'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
