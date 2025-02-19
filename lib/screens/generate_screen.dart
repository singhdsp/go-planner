import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_planner/models/itinerary.dart';
import 'package:go_planner/services/gemini_service.dart';
import 'package:go_planner/services/image_service.dart';
import 'package:go_planner/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  final TextEditingController _promptController = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  final ImageService _imageService = ImageService();
  final StorageService _storageService = StorageService();
  bool _isGenerating = false;
  Itinerary? _currentItinerary;
  bool _isSaved = false;

  Future<void> _generateItinerary() async {
    if (_promptController.text.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _currentItinerary = null;
      _isSaved = false;
    });

    try {
      final response = await _geminiService.generateItinerary(_promptController.text);
      final jsonData = jsonDecode(response.split('```json')[1].split('```')[0]);

      final itinerary = Itinerary(
        id: const Uuid().v4(),
        destination: jsonData['destination'],
        days: jsonData['days'],
        daysPlans: (jsonData['daysPlans'] as List)
            .map((day) => DayPlan.fromJson(day))
            .toList(),
      );

      for (final day in itinerary.daysPlans) {
        for (final activity in day.activities) {
          final imageUrl = await _imageService.fetchImage('${itinerary.destination} ${activity.title}');
          if (imageUrl != null) {
            activity.imageUrl = imageUrl;
          }
        }
      }

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

  @override
  Widget build(BuildContext context) {
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
                        hintText: 'e.g. "3-day trip in Italy focused on food and art"',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDarkMode 
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
                        icon: _isGenerating 
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
                          _isGenerating ? 'Creating Your Plan...' : 'Generate Itinerary',
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
        Row(
          children: [
            Expanded(
              child: Card(
                color: Theme.of(context).colorScheme.primary,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
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
                      const SizedBox(height: 8),
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
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Your Itinerary',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Drag to reorder days',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itinerary.daysPlans.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              itinerary.reorderDays(oldIndex, newIndex);
            });
          },
          itemBuilder: (context, index) {
            final dayPlan = itinerary.daysPlans[index];
            return _buildDayCard(dayPlan, index);
          },
        ),
      ],
    );
  }

  Widget _buildDayCard(DayPlan dayPlan, int index) {
    return Card(
      key: ValueKey(dayPlan.day),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Day ${dayPlan.day}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Icon(Icons.drag_handle),
              ],
            ),
            const Divider(height: 24),
            ...dayPlan.activities.map((activity) {
              return _buildActivityCard(activity);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(Activity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black12
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activity.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                activity.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 140,
                  color: Colors.grey.shade300,
                  child: Icon(
                    Icons.image_not_supported,
                    size: 50,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        activity.time,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (activity.isMustVisit)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 12,
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Must Visit',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onErrorContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.description,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade300
                        : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}