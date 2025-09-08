
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:tickit/models/task.dart';

class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _titleController = TextEditingController();
  DateTime? _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime = TimeOfDay.now();

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return AlertDialog(
      backgroundColor: theme.dialogTheme.backgroundColor,
      title: Text('Add Task', style: theme.textTheme.titleLarge?.copyWith(color: textColor)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Title',
              labelStyle: TextStyle(color: textColor.withAlpha((0.7 * 255).round())),
            ),
            style: TextStyle(color: textColor),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date',
                      labelStyle: TextStyle(color: textColor.withAlpha((0.7 * 255).round())),
                    ),
                    child: Text(
                      _selectedDate != null
                          ? DateFormat.yMMMd().format(_selectedDate!)
                          : 'Select Date',
                      style: TextStyle(color: textColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _selectTime(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Time',
                      labelStyle: TextStyle(color: textColor.withAlpha((0.7 * 255).round())),
                    ),
                    child: Text(
                      _selectedTime != null
                          ? _selectedTime!.format(context)
                          : 'Select Time',
                      style: TextStyle(color: textColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: theme.colorScheme.primary)),
        ),
        TextButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty &&
                _selectedDate != null &&
                _selectedTime != null) {
              final currentUserId = Supabase.instance.client.auth.currentUser?.id;
              if (currentUserId == null) {
                // Handle case where user is not authenticated, e.g., show an error message
                // For now, we'll just return without adding the task.
                // In a real app, you might want to navigate to login or show a snackbar.
                return;
              }

              final deadline = DateTime(
                _selectedDate!.year,
                _selectedDate!.month,
                _selectedDate!.day,
                _selectedTime!.hour,
                _selectedTime!.minute,
              );
              Navigator.of(context).pop(
                Task(title: _titleController.text, deadline: deadline, userId: currentUserId),
              );
            }
          },
          child: Text('Add', style: TextStyle(color: theme.colorScheme.primary)),
        ),
      ],
    );
  }
}
