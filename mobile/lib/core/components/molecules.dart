// Atomic Components - Molecules
// Composite components: cards, list tiles, status indicators

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import 'atoms.dart';
import '../../models/attendance.dart';
import '../../models/user.dart';

enum StatusType { success, warning, error, neutral }

/// Welcome Header Card
class WelcomeHeader extends StatelessWidget {
  final String userName;
  final String? teamName;
  final VoidCallback? onProfileTap;

  const WelcomeHeader({
    super.key,
    required this.userName,
    this.teamName,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(now);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome, $userName', style: AppTextStyles.titleLarge),
                  if (teamName != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Team: $teamName',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text(dateStr, style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
            if (onProfileTap != null)
              IconButton(
                onPressed: onProfileTap,
                icon: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                tooltip: 'Profile',
              ),
          ],
        ),
      ),
    );
  }
}

/// Attendance History List Tile
class AttendanceListTile extends StatelessWidget {
  final Attendance attendance;
  final VoidCallback? onTap;

  const AttendanceListTile({
    super.key,
    required this.attendance,
    this.onTap,
  });

  StatusType get statusType {
    switch (attendance.status) {
      case 'PRESENT':
        return StatusType.success;
      case 'LATE':
        return StatusType.warning;
      case 'ABSENT':
        return StatusType.error;
      default:
        return StatusType.neutral;
    }
  }

  String get formattedCheckIn {
    return DateFormat('h:mm a').format(attendance.checkInTime);
  }

  String? get formattedCheckOut {
    if (attendance.checkOutTime == null) return null;
    return DateFormat('h:mm a').format(attendance.checkOutTime!);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Date icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Date and time info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('MMM dd, yyyy').format(attendance.date),
                        style: AppTextStyles.bodyLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'In: $formattedCheckIn${formattedCheckOut != null ? ' • Out: $formattedCheckOut' : ''}',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),

              // Status badge
              StatusBadge(
                label: attendance.statusDisplay,
                color: statusType == StatusType.success
                    ? AppColors.success.withOpacity(0.1)
                    : statusType == StatusType.warning
                        ? AppColors.warning.withOpacity(0.1)
                        : statusType == StatusType.error
                            ? AppColors.error.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                textColor: statusType == StatusType.success
                    ? AppColors.success
                    : statusType == StatusType.warning
                        ? AppColors.warning
                        : statusType == StatusType.error
                            ? AppColors.error
                            : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Team Member List Tile
class TeamMemberTile extends StatelessWidget {
  final User user;
  final bool isPresent;
  final bool isLate;
  final String? checkInTime;
  final VoidCallback? onTap;

  const TeamMemberTile({
    super.key,
    required this.user,
    this.isPresent = false,
    this.isLate = false,
    this.checkInTime,
    this.onTap,
  });

  StatusType get statusType {
    if (!isPresent) return StatusType.error;
    if (isLate) return StatusType.warning;
    return StatusType.success;
  }

  String get statusLabel {
    if (!isPresent) return 'Absent';
    if (isLate) return 'Late';
    return 'Present';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Avatar with status dot
              Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: Text(
                      user.fullName.isNotEmpty
                          ? user.fullName[0].toUpperCase()
                          : '?',
                      style: AppTextStyles.titleLarge
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: StatusDot(type: statusType, size: 14),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),

              // Name and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName, style: AppTextStyles.bodyLarge),
                    if (checkInTime != null)
                      Text(
                        'Checked in: $checkInTime',
                        style: AppTextStyles.bodyMedium,
                      ),
                  ],
                ),
              ),

              // Status badge
              StatusBadge(
                label: statusLabel,
                color: statusType == StatusType.success
                    ? AppColors.success.withOpacity(0.1)
                    : statusType == StatusType.warning
                        ? AppColors.warning.withOpacity(0.1)
                        : statusType == StatusType.error
                            ? AppColors.error.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                textColor: statusType == StatusType.success
                    ? AppColors.success
                    : statusType == StatusType.warning
                        ? AppColors.warning
                        : statusType == StatusType.error
                            ? AppColors.error
                            : Colors.grey,
              ),

              // Arrow
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusDot extends StatelessWidget {
  final StatusType type;
  final double size;

  const StatusDot({super.key, required this.type, required this.size});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (type) {
      case StatusType.success:
        color = AppColors.success;
        break;
      case StatusType.warning:
        color = AppColors.warning;
        break;
      case StatusType.error:
        color = AppColors.error;
        break;
      case StatusType.neutral:
        color = Colors.grey;
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface, width: 2),
      ),
    );
  }
}

/// Stats Summary Card
class StatsSummaryCard extends StatelessWidget {
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int totalCount;

  const StatsSummaryCard({
    super.key,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Present', presentCount, AppColors.success),
            _divider(),
            _buildStatItem('Late', lateCount, AppColors.warning),
            _divider(),
            _buildStatItem('Absent', absentCount, AppColors.error),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: AppTextStyles.displayMedium.copyWith(color: color),
        ),
        Text(label, style: AppTextStyles.bodyMedium),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.glassBorder,
    );
  }
}

/// Check-In Action Card
class CheckInActionCard extends StatelessWidget {
  final bool isCheckedIn;
  final bool isCheckedOut;
  final bool isLoading;
  final bool isGettingLocation;
  final String? checkInTime;
  final String? checkOutTime;
  final String? locationError;
  final VoidCallback? onCheckIn;
  final VoidCallback? onCheckOut;

  const CheckInActionCard({
    super.key,
    this.isCheckedIn = false,
    this.isCheckedOut = false,
    this.isLoading = false,
    this.isGettingLocation = false,
    this.checkInTime,
    this.checkOutTime,
    this.locationError,
    this.onCheckIn,
    this.onCheckOut,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading || isGettingLocation) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: AppSpacing.md),
              Text(
                isGettingLocation
                    ? 'Getting your location...'
                    : 'Please wait...',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    // Completed state
    if (isCheckedIn && isCheckedOut) {
      return Card(
        color: AppColors.success.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Icon(Icons.check_circle,
                  size: 48, color: AppColors.success),
              const SizedBox(height: AppSpacing.md),
              const Text('Day Complete!', style: AppTextStyles.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'In: $checkInTime • Out: $checkOutTime',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    // Checked in, need to check out
    if (isCheckedIn && !isCheckedOut) {
      return Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: AppColors.success),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Checked In',
                            style: AppTextStyles.bodyLarge),
                        if (checkInTime != null)
                          Text('At $checkInTime',
                              style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  ),
                  const StatusBadge(
                      label: 'Active',
                      color: Colors.transparent,
                      textColor: AppColors.success),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DangerButton(
            label: 'CHECK OUT',
            icon: Icons.logout,
            onPressed: onCheckOut ?? () {},
          ),
        ],
      );
    }

    // Not checked in yet
    return Column(
      children: [
        if (locationError != null) ...[
          Card(
            color: AppColors.error.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  const Icon(Icons.location_off, color: AppColors.error),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child:
                        Text(locationError!, style: AppTextStyles.bodyMedium),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        SuccessButton(
          label: 'CHECK IN',
          icon: Icons.login,
          onPressed: onCheckIn ?? () {},
        ),
      ],
    );
  }
}

// Added missing components
class LoadingOverlay extends StatelessWidget {
  final String message;

  const LoadingOverlay({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          Text(message, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: AppTextStyles.titleLarge
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
