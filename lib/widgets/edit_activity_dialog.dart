import 'package:flutter/material.dart';
import 'package:go_planner/models/itinerary.dart';

class EditActivityDialog extends StatefulWidget {
  final Activity activity;
  final Function(Activity) onSave;

  const EditActivityDialog({
    Key? key,
    required this.activity,
    required this.onSave,
  }) : super(key: key);

  @override
  State<EditActivityDialog> createState() => _EditActivityDialogState();
}

class _EditActivityDialogState extends State<EditActivityDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _timeController;
  late TextEditingController _costController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.activity.title);
    _descriptionController = TextEditingController(text: widget.activity.description);
    _timeController = TextEditingController(text: widget.activity.time);
    _costController = TextEditingController(text: widget.activity.cost);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _timeController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Activity'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _timeController,
              decoration: const InputDecoration(
                labelText: 'Time',
                border: OutlineInputBorder(),
                hintText: 'e.g. 9:00 AM',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _costController,
              decoration: const InputDecoration(
                labelText: 'Approximate Cost',
                border: OutlineInputBorder(),
                hintText: 'e.g. \$10-20, Free',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
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
          onPressed: () {
            widget.activity.title = _titleController.text;
            widget.activity.description = _descriptionController.text;
            widget.activity.time = _timeController.text;
            widget.activity.cost = _costController.text;
            widget.onSave(widget.activity);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}