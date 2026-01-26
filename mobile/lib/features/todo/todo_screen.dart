import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/components/glass_components.dart';
import 'todo_provider.dart';
import '../../models/todo.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  @override
  void initState() {
    super.initState();
    final userId = context.read<AuthProvider>().user?.id;
    if (userId != null) {
      Future.microtask(() => context.read<TodoProvider>().loadTodos(userId));
    }
  }

  void _showTodoDialog({Todo? todoToEdit}) {
    final bool isEditing = todoToEdit != null;
    final titleController =
        TextEditingController(text: todoToEdit?.title ?? '');
    final descriptionController =
        TextEditingController(text: todoToEdit?.description ?? '');
    DateTime? selectedDate = todoToEdit?.dueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              side: const BorderSide(color: AppColors.glassBorder)),
          title: Text(isEditing ? 'Edit Task' : 'Add New Task',
              style: AppTextStyles.titleMedium),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing
                      ? 'Update your task details'
                      : 'Create a new task for yourself',
                  style:
                      AppTextStyles.bodySmall.copyWith(color: Colors.white54),
                ),
                const SizedBox(height: AppSpacing.md),
                GlassTextField(
                  controller: titleController,
                  label: 'Title',
                  hint: 'Task title',
                ),
                const SizedBox(height: AppSpacing.md),
                GlassTextField(
                  controller: descriptionController,
                  label: 'Description',
                  hint: 'Task description (optional)',
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.md),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppColors.primary,
                              onPrimary: Colors.white,
                              surface: Color(0xFF1E1E1E),
                              onSurface: Colors.white,
                            ),
                            dialogBackgroundColor: const Color(0xFF1E1E1E),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      setState(() {
                        selectedDate = date;
                      });
                    }
                  },
                  child: AbsorbPointer(
                    child: GlassTextField(
                      controller: TextEditingController(
                          text: selectedDate != null
                              ? DateFormat('dd-MM-yyyy').format(selectedDate!)
                              : ''),
                      label: 'Due Date',
                      hint: 'dd-mm-yyyy',
                      suffixIcon: const Icon(Icons.calendar_today,
                          color: Colors.white70),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            GlassButton(
              text: isEditing ? 'Save Changes' : 'Add Task',
              onPressed: () {
                if (titleController.text.isEmpty) return;

                if (isEditing) {
                  context.read<TodoProvider>().updateTodo(
                        todoToEdit.copyWith(
                          title: titleController.text,
                          description: descriptionController.text,
                          dueDate: selectedDate,
                        ),
                      );
                } else {
                  context.read<TodoProvider>().addTodo(
                        title: titleController.text,
                        description: descriptionController.text,
                        dueDate: selectedDate,
                      );
                }
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todoProvider = context.watch<TodoProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("My To-dos"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTodoDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
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
                // Summary Cards
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Total',
                          todoProvider.todos.length.toString(),
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildSummaryCard(
                          'Pending',
                          todoProvider.pendingTodos.length.toString(),
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildSummaryCard(
                          'Done',
                          todoProvider.completedTodos.length.toString(),
                          AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tabs
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        const TabBar(
                          tabs: [
                            Tab(text: 'Pending'),
                            Tab(text: 'Completed'),
                          ],
                          indicatorColor: AppColors.primary,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white54,
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildTodoList(todoProvider.pendingTodos, false),
                              _buildTodoList(todoProvider.completedTodos, true),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String count, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.sm),
      color: color.withOpacity(0.1),
      borderColor: color.withOpacity(0.3),
      child: Column(
        children: [
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoList(List<Todo> todos, bool isCompleted) {
    if (todos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCompleted ? Icons.task_alt : Icons.assignment_outlined,
              size: 48,
              color: Colors.white24,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              isCompleted ? 'No completed tasks' : 'No pending tasks',
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: todos.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final todo = todos[index];
        return Dismissible(
          key: Key(todo.id),
          background: Container(
            color: AppColors.error.withOpacity(0.5),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (_) {
            context.read<TodoProvider>().deleteTodo(todo.id);
          },
          child: GlassContainer(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Transform.scale(
                  scale: 1.2,
                  child: Checkbox(
                    value: todo.isCompleted,
                    activeColor: AppColors.primary,
                    side: const BorderSide(color: Colors.white54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (_) {
                      context.read<TodoProvider>().toggleTodo(todo.id);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo.title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          decoration: todo.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color:
                              todo.isCompleted ? Colors.white54 : Colors.white,
                        ),
                      ),
                      if (todo.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          todo.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (todo.dueDate != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 12, color: AppColors.secondary),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d, yyyy').format(todo.dueDate!),
                              style: const TextStyle(
                                  color: AppColors.secondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Actions
                if (!isCompleted)
                  IconButton(
                    icon:
                        const Icon(Icons.edit, color: Colors.white70, size: 20),
                    onPressed: () => _showTodoDialog(todoToEdit: todo),
                  ),
                if (isCompleted)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.error, size: 20),
                    onPressed: () {
                      // Confirm delete
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Colors.black.withOpacity(0.9),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              side: const BorderSide(
                                  color: AppColors.glassBorder)),
                          title: const Text('Delete Task?',
                              style: TextStyle(color: Colors.white)),
                          content: const Text(
                              'Are you sure you want to delete this task?',
                              style: TextStyle(color: Colors.white70)),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel')),
                            TextButton(
                              child: const Text('Delete',
                                  style: TextStyle(color: AppColors.error)),
                              onPressed: () {
                                context
                                    .read<TodoProvider>()
                                    .deleteTodo(todo.id);
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
