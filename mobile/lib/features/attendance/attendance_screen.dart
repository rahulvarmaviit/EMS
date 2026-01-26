import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/components/glass_components.dart';
import '../../models/attendance.dart';
import 'attendance_provider.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedMonth = DateFormat('MMMM yyyy').format(DateTime.now());
  final List<String> _months = [];

  @override
  void initState() {
    super.initState();
    _generateMonths();
    // Fetch data if needed, but provider might already have it from home screen
    // Refreshing just in case
    Future.microtask(() => context.read<AttendanceProvider>().fetchHistory());
  }

  void _generateMonths() {
    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      _months.add(DateFormat('MMMM yyyy').format(date));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Attendance> _filterAttendance(List<Attendance> history) {
    String query = _searchController.text.toLowerCase();

    return history.where((attendance) {
      // 1. Filter by Month
      final attendanceMonth = DateFormat('MMMM yyyy').format(attendance.date);
      if (attendanceMonth != _selectedMonth) return false;

      // 2. Filter by Search Query (not much to search in attendance, maybe status?)
      if (query.isNotEmpty) {
        // Simple search on status or date string
        String dateStr =
            DateFormat('MMM d, yyyy').format(attendance.date).toLowerCase();
        String statusStr = attendance.status.toLowerCase();
        return dateStr.contains(query) || statusStr.contains(query);
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = context.watch<AttendanceProvider>();
    final history = attendanceProvider.history;
    final filteredHistory = _filterAttendance(history);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Attendance Records',
                              style: AppTextStyles.titleLarge,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'View your attendance history',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GlassButton(
                        text: 'Export CSV',
                        icon: Icons.download,
                        color: Colors.blueAccent,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Export functionality coming soon')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Filters
                  GlassContainer(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      children: [
                        // Search
                        GlassTextField(
                          controller: _searchController,
                          label: 'Search',
                          hint: 'Search by date or status...',
                          prefixIcon: Icons.search,
                          // Trigger rebuild on change
                          // onChanged: (_) => setState(() {}), // GlassTextField doesn't expose onChanged directly
                          // We might need to modify GlassTextField or just rely on controller listener if we want instant search
                          // For now, let's assume user types and hits execute or we wrap it.
                          // GlassTextField in glass_components uses TextFormField.
                          // To keep it simple, I'll attach listener.
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Month Dropdown (Custom Glass styling)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.glassWhite,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedMonth,
                              dropdownColor: const Color(0xFF1E1E1E),
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down,
                                  color: Colors.white),
                              style: AppTextStyles.bodyMedium,
                              items: _months.map((String month) {
                                return DropdownMenuItem<String>(
                                  value: month,
                                  child: Text(month),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedMonth = newValue;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // List Header
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 2,
                            child: Text('Date',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 12))),
                        Expanded(
                            flex: 2,
                            child: Text('Check In',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 12))),
                        Expanded(
                            flex: 2,
                            child: Text('Check Out',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 12))),
                        Expanded(
                            flex: 2,
                            child: Text('Duration',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 12))),
                        Expanded(
                            flex: 2,
                            child: Center(
                                child: Text('Status',
                                    style: TextStyle(
                                        color: Colors.white54, fontSize: 12)))),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // List
                  Expanded(
                    child: attendanceProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : filteredHistory.isEmpty
                            ? Center(
                                child: Text(
                                  'No records found for $_selectedMonth',
                                  style: const TextStyle(color: Colors.white54),
                                ),
                              )
                            : ListView.separated(
                                itemCount: filteredHistory.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: AppSpacing.sm),
                                itemBuilder: (context, index) {
                                  final attendance = filteredHistory[index];
                                  return _buildAttendanceRow(attendance);
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceRow(Attendance attendance) {
    final dateStr = DateFormat('MMM d').format(attendance.date.toLocal());
    final checkInStr =
        DateFormat('h:mm a').format(attendance.checkInTime.toLocal());
    final checkOutStr = attendance.checkOutTime != null
        ? DateFormat('h:mm a').format(attendance.checkOutTime!.toLocal())
        : '-';

    Color statusColor;
    String statusText = attendance.status;

    // Logic for "In Progress" if today and not checked out
    final isToday =
        DateUtils.isSameDay(attendance.date.toLocal(), DateTime.now());
    if (isToday && attendance.checkOutTime == null) {
      statusText = 'In Progress';
      statusColor = Colors.blueAccent;
    } else {
      // Backend status colors
      switch (attendance.status.toUpperCase()) {
        case 'PRESENT':
          statusColor = AppColors.success;
          break;
        case 'LATE':
          statusColor = AppColors.warning;
          break;
        case 'ABSENT':
          statusColor = AppColors.error;
          break;
        case 'HALF_DAY':
          statusColor = Colors.orange;
          break;
        default:
          statusColor = Colors.grey;
      }
    }

    // Calculate Duration
    String durationStr = '-';
    if (attendance.checkOutTime != null) {
      final duration =
          attendance.checkOutTime!.difference(attendance.checkInTime);
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      durationStr = '${hours}h ${minutes}m';
    } else if (isToday) {
      durationStr = 'In progress';
    }

    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      radius: AppRadius.sm,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(dateStr,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          Expanded(
            flex: 2,
            child: Text(checkInStr,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70)),
          ),
          Expanded(
            flex: 2,
            child: Text(checkOutStr,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70)),
          ),
          Expanded(
            flex: 2,
            child: Text(durationStr,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withOpacity(0.5)),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  statusText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
