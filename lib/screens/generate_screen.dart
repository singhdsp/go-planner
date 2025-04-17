import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_planner/models/itinerary.dart';
import 'package:go_planner/services/gemini_service.dart';
import 'package:go_planner/services/image_service.dart';
import 'package:go_planner/services/storage_service.dart';
import 'package:go_planner/widgets/day_plan_card.dart';
import 'package:uuid/uuid.dart';

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _promptController = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  final ImageService _imageService = ImageService();
  final StorageService _storageService = StorageService();
  bool _isGenerating = false;
  Itinerary? _currentItinerary;
  bool _isSaved = false;

  @override
  bool get wantKeepAlive => true;

  Future<void> _generateItinerary() async {
    if (_promptController.text.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _currentItinerary = null;
      _isSaved = false;
    });

    try {
      final response = await _geminiService.generateItinerary(
        _promptController.text,
      );
      final jsonData = jsonDecode(response.split('```json')[1].split('```')[0]);

      final itinerary = Itinerary(
        id: const Uuid().v4(),
        destination: jsonData['destination'],
        days: jsonData['days'],
        daysPlans:
            (jsonData['daysPlans'] as List)
                .map((day) => DayPlan.fromJson(day))
                .toList(),
      );

      for (final day in itinerary.daysPlans) {
        for (final activity in day.activities) {
          if (activity.cost.isEmpty) {
            activity.cost = 'Free';
          }
        }
      }
      
      final futures = <Future>[];
      for (final day in itinerary.daysPlans) {
        for (final activity in day.activities) {
          futures.add(_loadImageForActivity(activity, itinerary.destination));
        }
      }
      await Future.wait(futures);

      setState(() {
        _currentItinerary = itinerary;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
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

  Future<void> _saveItinerary() async {
    if (_currentItinerary == null) return;

    try {
      await _storageService.saveItinerary(_currentItinerary!);
      setState(() => _isSaved = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Itinerary saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving itinerary: ${e.toString()}')),
      );
    }
  }

  void _addCustomActivity(int dayIndex) {
    if (_currentItinerary == null) return;

    final newActivity = Activity(
      id: const Uuid().v4(),
      title: 'New Activity',
      description: 'Add your description here',
      time: '12:00',
      isMustVisit: false,
      cost: 'Free',
    );

    setState(() {
      _currentItinerary!.daysPlans[dayIndex].activities.add(newActivity);
      _isSaved = false;
    });
  }

  void _handleEditActivity(Activity activity) {
    setState(() {
      _isSaved = false;
    });
  }

  void _deleteActivity(DayPlan dayPlan, Activity activity) {
    setState(() {
      dayPlan.activities.remove(activity);
      _isSaved = false;
    });
  }

  void _markDataChanged() {
    setState(() {
      _isSaved = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Your Trip'),
        centerTitle: true,
        actions: [
          if (_currentItinerary != null)
            IconButton(
              icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border),
              onPressed: _saveItinerary,
              tooltip: 'Save Itinerary',
            ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Where would you like to go?',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _promptController,
                      decoration: InputDecoration(
                        labelText: 'Describe your trip',
                        hintText:
                            'e.g. "3-day trip in Italy focused on food and art"',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor:
                            isDarkMode
                                ? Theme.of(context).inputDecorationTheme.fillColor
                                : Colors.grey[50],
                      ),
                      maxLines: 3,
                      onSubmitted: (_) => _generateItinerary(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isGenerating ? null : _generateItinerary,
                        icon:
                            _isGenerating
                                ? Container(
                                  width: 24,
                                  height: 24,
                                  padding: const EdgeInsets.all(2.0),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.flight_takeoff),
                        label: Text(
                          _isGenerating
                              ? 'Creating Your Plan...'
                              : 'Generate Itinerary',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_currentItinerary != null) ...[
              const SizedBox(height: 24),
              _buildItinerary(_currentItinerary!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItinerary(Itinerary itinerary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
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
                                itinerary.destination,
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
                        '${itinerary.days} Days Journey',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),                                      
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
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
          itemCount: itinerary.daysPlans.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              itinerary.reorderDays(oldIndex, newIndex);
              _isSaved = false;
            });
          },
          itemBuilder: (context, index) {
            final dayPlan = itinerary.daysPlans[index];
            return DayPlanCard(
              key: ValueKey(dayPlan.day),
              dayPlan: dayPlan,
              dayIndex: index,
              onAddActivity: _addCustomActivity,
              onEditActivity: _handleEditActivity,
              onDeleteActivity: _deleteActivity,
              onDataChanged: _markDataChanged,
              destination: itinerary.destination,
              imageService: _imageService,
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}