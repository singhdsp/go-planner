import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_planner/models/itinerary.dart';
import 'package:go_planner/services/gemini_service.dart';
import 'package:go_planner/services/image_service.dart';
import 'package:go_planner/services/storage_service.dart';
import 'package:go_planner/widgets/day_plan_card.dart';
import 'package:uuid/uuid.dart';

class ItineraryViewScreen extends StatefulWidget {
  final Itinerary itinerary;

  const ItineraryViewScreen({Key? key, required this.itinerary})
    : super(key: key);

  @override
  State<ItineraryViewScreen> createState() => _ItineraryViewScreenState();
}

class _ItineraryViewScreenState extends State<ItineraryViewScreen> {
  final ImageService _imageService = ImageService();
  final StorageService _storageService = StorageService();
  final GeminiService _geminiService = GeminiService();
  late Itinerary _currentItinerary;
  bool _isEdited = false;
  bool _isSaving = false;
  bool _isUpdating = false;
  final TextEditingController _updatePromptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Create a deep copy of the itinerary to safely edit
    _currentItinerary = _deepCopyItinerary(widget.itinerary);
  }

  Itinerary _deepCopyItinerary(Itinerary source) {
    // Create a copy using the fromJson/toJson pattern
    return Itinerary.fromJson(Map<String, dynamic>.from(source.toJson()));
  }

  void _markDataChanged() {
    setState(() {
      _isEdited = true;
    });
  }

  void _addCustomActivity(int dayIndex) {
    final newActivity = Activity(
      id: const Uuid().v4(),
      title: 'New Activity',
      description: 'Add your description here',
      time: '12:00',
      isMustVisit: false,
      cost: 'Free',
    );

    setState(() {
      _currentItinerary.daysPlans[dayIndex].activities.add(newActivity);
      _isEdited = true;
    });
  }

  void _handleEditActivity(Activity activity) {
    setState(() {
      _isEdited = true;
    });
  }

  void _deleteActivity(DayPlan dayPlan, Activity activity) {
    setState(() {
      dayPlan.activities.remove(activity);
      _isEdited = true;
    });
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // First remove the old itinerary
      await _storageService.removeItinerary(widget.itinerary.id);

      // Then save the updated one
      await _storageService.saveItinerary(_currentItinerary);

      setState(() {
        _isEdited = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Itinerary updated successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving itinerary: ${e.toString()}')),
        );
      }
    }
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Itinerary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Describe the changes you need to make:'),
            const SizedBox(height: 16),
            TextField(
              controller: _updatePromptController,
              decoration: InputDecoration(
                hintText: 'e.g., "I missed my flight, need to reschedule Day 1"',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateItinerary();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateItinerary() async {
    if (_updatePromptController.text.isEmpty) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final response = await _geminiService.updateItinerary(
        _currentItinerary,
        _updatePromptController.text,
      );

      // Extract JSON from response if it comes with markdown code blocks
      String jsonStr = response;
      if (response.contains('```json')) {
        jsonStr = response.split('```json')[1].split('```')[0].trim();
      } else if (response.contains('```')) {
        jsonStr = response.split('```')[1].split('```')[0].trim();
      }

      final jsonData = jsonDecode(jsonStr);

      final updatedItinerary = Itinerary(
        id: _currentItinerary.id, // Keep the same ID
        destination: jsonData['destination'],
        days: jsonData['days'],
        daysPlans:
            (jsonData['daysPlans'] as List)
                .map((day) => DayPlan.fromJson(day))
                .toList(),
      );

      // Fetch images for any new activities that don't have images
      final futures = <Future>[];
      for (final day in updatedItinerary.daysPlans) {
        for (final activity in day.activities) {
          if (activity.imageUrl == null || activity.imageUrl!.isEmpty) {
            futures.add(_loadImageForActivity(activity, updatedItinerary.destination));
          }
        }
      }
      await Future.wait(futures);

      setState(() {
        _currentItinerary = updatedItinerary;
        _isUpdating = false;
        _isEdited = true;
      });

      _updatePromptController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Itinerary updated based on your request!')),
      );
    } catch (e) {
      setState(() => _isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating itinerary: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadImageForActivity(Activity activity, String destination) async {
    final imageUrl = await _imageService.fetchImage(
      '$destination ${activity.title}',
    );
    if (imageUrl != null) {
      activity.imageUrl = imageUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isEdited) {
          final result = await _showUnsavedChangesDialog();
          return result ?? false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentItinerary.destination),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _showUpdateDialog,
              tooltip: 'Update with AI',
            ),
            if (_isEdited)
              IconButton(
                icon:
                    _isSaving
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.save),
                onPressed: _isSaving ? null : _saveChanges,
                tooltip: 'Save Changes',
              ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildItineraryHeader(),
                  const SizedBox(height: 24),
                  Text(
                    'Your Itinerary',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Drag to reorder days and activities',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _currentItinerary.daysPlans.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        _currentItinerary.reorderDays(oldIndex, newIndex);
                        _isEdited = true;
                      });
                    },
                    itemBuilder: (context, index) {
                      final dayPlan = _currentItinerary.daysPlans[index];
                      return DayPlanCard(
                        key: ValueKey(dayPlan.day),
                        dayPlan: dayPlan,
                        dayIndex: index,
                        onAddActivity: _addCustomActivity,
                        onEditActivity: _handleEditActivity,
                        onDeleteActivity: _deleteActivity,
                        onDataChanged: _markDataChanged,
                        destination: _currentItinerary.destination,
                        imageService: _imageService,
                      );
                    },
                  ),
                ],
              ),
            ),
            if (_isUpdating)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          const Text(
                            'Updating your itinerary...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Applying changes: "${_updatePromptController.text}"',
                            style: const TextStyle(fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showUpdateDialog,
          icon: const Icon(Icons.auto_fix_high),
          label: const Text('Update with AI'),
        ),
      ),
    );
  }

  Widget _buildItineraryHeader() {
    return Card(
      color: Theme.of(context).colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _currentItinerary.destination,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            InkWell(
              child: Row(
                children: [
                  Text(
                    '${_currentItinerary.days} Days Journey',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showUnsavedChangesDialog() async {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Unsaved Changes'),
            content: const Text(
              'You have unsaved changes. Do you want to save them before leaving?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Discard'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _saveChanges();
                  if (mounted) {
                    Navigator.of(context).pop(true);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }
  
  @override
  void dispose() {
    _updatePromptController.dispose();
    super.dispose();
  }
}