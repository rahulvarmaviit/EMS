import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class DailyWorkLogDialog extends StatefulWidget {
  const DailyWorkLogDialog({super.key});

  @override
  State<DailyWorkLogDialog> createState() => _DailyWorkLogDialogState();
}

class _DailyWorkLogDialogState extends State<DailyWorkLogDialog> {
  final _formKey = GlobalKey<FormState>();
  final _workDoneController = TextEditingController();
  final _meetingsController = TextEditingController();
  final _todoController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedProject;

  // Mock projects for now
  final List<String> _projects = [
    'Connected Living ',
    'Wolfronix',
    'Website Redesign',
    'AI Model Development',
    'TMS',
    'Internal Tools',
    'Other',
  ];

  @override
  void dispose() {
    _workDoneController.dispose();
    _meetingsController.dispose();
    _todoController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final data = {
        'work_done': _workDoneController.text,
        'project_name': _selectedProject,
        'meetings': _meetingsController.text,
        'todo_updates': _todoController.text,
        'notes': _notesController.text,
      };

      Navigator.of(context).pop(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.glassBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daily Work Log',
                    style: AppTextStyles.titleLarge,
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.glassBorder),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Before you check out, please fill in your activities for the day.',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildLabel('Work Done*'),
                      TextFormField(
                        controller: _workDoneController,
                        maxLines: 3,
                        style: AppTextStyles.bodyLarge,
                        decoration: _inputDecoration(
                            'e.g., Completed the login page UI...'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter work done';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildLabel('Project Worked On*'),
                      DropdownButtonFormField<String>(
                        value: _selectedProject,
                        dropdownColor: AppColors.surface,
                        style: AppTextStyles.bodyLarge,
                        decoration: _inputDecoration('Select a project'),
                        items: _projects.map((project) {
                          return DropdownMenuItem(
                            value: project,
                            child: Text(project),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedProject = value),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a project';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildLabel('Meetings Attended'),
                      TextFormField(
                        controller: _meetingsController,
                        style: AppTextStyles.bodyLarge,
                        decoration: _inputDecoration(
                            'e.g., Daily Standup, Project Sync'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildLabel('To-do Updates'),
                      TextFormField(
                        controller: _todoController,
                        maxLines: 2,
                        style: AppTextStyles.bodyLarge,
                        decoration: _inputDecoration(
                            'e.g., Next up: Implement user profile...'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildLabel('Reminders / Notes'),
                      TextFormField(
                        controller: _notesController,
                        style: AppTextStyles.bodyLarge,
                        decoration: _inputDecoration('Any notes for tomorrow?'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.glassBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: Text('Cancel',
                          style: AppTextStyles.labelLarge
                              .copyWith(color: AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Submit & Check Out',
                          style: AppTextStyles.labelLarge),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        label,
        style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
      filled: true,
      fillColor: AppColors.glassWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      contentPadding: const EdgeInsets.all(AppSpacing.md),
    );
  }
}
