import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/components/glass_components.dart';
import 'leave_provider.dart';
import '../../models/leave_request.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    // Fetch leave history on init
    Future.microtask(() => context.read<LeaveProvider>().fetchLeaveHistory());
  }

  bool _isDayEnabled(DateTime day) {
    // Enable today and future dates
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDay = DateTime(day.year, day.month, day.day);
    return !checkDay.isBefore(today);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!_isDayEnabled(selectedDay)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot select past dates')),
      );
      return;
    }

    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _rangeStart = null; // Clear range if single day selected
        _rangeEnd = null;
      });
    }
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    if (start != null && !_isDayEnabled(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot select past dates')),
      );
      return;
    }

    setState(() {
      _selectedDay = null;
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
    });
  }

  Future<void> _showTakeLeaveDialog() async {
    final start = _rangeStart ?? _selectedDay;
    final end = _rangeEnd ?? _selectedDay;

    if (start == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date or range first')),
      );
      return;
    }

    // Double check (though UI should prevent it)
    if (!_isDayEnabled(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot request leave for past dates')),
      );
      return;
    }

    final reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.black
                  .withOpacity(0.9), // Slightly darker for better visibility
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.glassBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Request Leave', style: AppTextStyles.titleMedium),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Date: ${DateFormat('MMM d').format(start)} ${end != null && end != start ? '- ${DateFormat('MMM d').format(end)}' : ''}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: AppSpacing.md),
                GlassTextField(
                  controller: reasonController,
                  label: 'Reason',
                  hint: 'Enter check reason...',
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    GlassButton(
                      text: 'Submit',
                      onPressed: () async {
                        if (reasonController.text.isEmpty) return;

                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        final leaveProvider = context.read<LeaveProvider>();

                        navigator.pop();

                        final success = await leaveProvider.applyForLeave(
                          startDate: start,
                          endDate: end ?? start,
                          reason: reasonController.text,
                        );

                        if (!mounted) return;

                        if (success) {
                          messenger.showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Leave request submitted successfully')),
                          );
                        } else {
                          final error = leaveProvider.error;
                          messenger.showSnackBar(
                            SnackBar(
                                content:
                                    Text(error ?? 'Failed to submit request')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leaveProvider = context.watch<LeaveProvider>();
    final leaves = leaveProvider.leaves;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Leave Calendar'),
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
                  // Calendar Card
                  GlassContainer(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      children: [
                        TableCalendar(
                          firstDay: DateTime.utc(2024, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          calendarFormat: _calendarFormat,
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDay, day),
                          rangeStartDay: _rangeStart,
                          rangeEndDay: _rangeEnd,
                          rangeSelectionMode: RangeSelectionMode.toggledOn,
                          enabledDayPredicate: _isDayEnabled,
                          onDaySelected: _onDaySelected,
                          onRangeSelected: _onRangeSelected,
                          onFormatChanged: (format) {
                            if (_calendarFormat != format) {
                              setState(() {
                                _calendarFormat = format;
                              });
                            }
                          },
                          onPageChanged: (focusedDay) {
                            _focusedDay = focusedDay;
                          },
                          // Style
                          calendarStyle: const CalendarStyle(
                            defaultTextStyle: TextStyle(color: Colors.white),
                            weekendTextStyle: TextStyle(color: Colors.white70),
                            outsideTextStyle: TextStyle(color: Colors.white24),
                            selectedDecoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            rangeStartDecoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            rangeEndDecoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            rangeHighlightColor:
                                Color(0x339D4EDD), // Semi-transparent purple
                            todayDecoration: BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                            ),
                          ),
                          headerStyle: const HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            leftChevronIcon:
                                Icon(Icons.chevron_left, color: Colors.white),
                            rightChevronIcon:
                                Icon(Icons.chevron_right, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GlassButton(
                              text: 'Take Leave',
                              icon: Icons.add,
                              onPressed: _showTakeLeaveDialog,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // History Header
                  const Text(
                    'My Leave Requests',
                    style: AppTextStyles.titleMedium,
                  ),
                  Text(
                    'A history of your past leave requests.',
                    style:
                        AppTextStyles.bodySmall.copyWith(color: Colors.white54),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // History List
                  Expanded(
                    child: leaveProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : leaves.isEmpty
                            ? const Center(
                                child: Text(
                                  "You haven't made any leave requests yet.",
                                  style: TextStyle(color: Colors.white54),
                                ),
                              )
                            : ListView.separated(
                                itemCount: leaves.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: AppSpacing.sm),
                                itemBuilder: (context, index) {
                                  final leave = leaves[index];
                                  return _buildLeaveCard(leave);
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

  Widget _buildLeaveCard(LeaveRequest leave) {
    Color statusColor;
    switch (leave.status) {
      case 'APPROVED':
        statusColor = AppColors.success;
        break;
      case 'REJECTED':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = Colors.orange;
    }

    final dateStr = DateFormat('MMM d').format(leave.startDate) +
        (leave.startDate != leave.endDate
            ? ' - ${DateFormat('MMM d').format(leave.endDate)}'
            : '');

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      radius: AppRadius.sm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
                ),
                child: Text(
                  leave.status,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            leave.reason,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
