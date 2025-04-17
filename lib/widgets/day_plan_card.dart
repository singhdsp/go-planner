import 'package:flutter/material.dart';
import 'package:go_planner/models/itinerary.dart';
import 'package:go_planner/widgets/activity_card.dart';
import 'package:go_planner/services/image_service.dart';

class DayPlanCard extends StatelessWidget {
  final DayPlan dayPlan;
  final int dayIndex;
  final Function(int) onAddActivity;
  final Function(Activity) onEditActivity;
  final Function(DayPlan, Activity) onDeleteActivity;
  final Function() onDataChanged;
  final String destination;
  final ImageService imageService;

  const DayPlanCard({
    Key? key,
    required this.dayPlan,
    required this.dayIndex,
    required this.onAddActivity,
    required this.onEditActivity,
    required this.onDeleteActivity,
    required this.onDataChanged,
    required this.destination,
    required this.imageService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey(dayPlan.day),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      const Icon(Icons.calendar_today, size: 16, color: Colors.white),
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
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Add Activity',
                  onPressed: () => onAddActivity(dayIndex),
                ),
                const Icon(Icons.drag_handle),
              ],
            ),
            const Divider(height: 24),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dayPlan.activities.length,
              onReorder: (oldIndex, newIndex) {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final activity = dayPlan.activities.removeAt(oldIndex);
                dayPlan.activities.insert(newIndex, activity);
                onDataChanged();
              },
              itemBuilder: (context, index) {
                final activity = dayPlan.activities[index];
                return ActivityCard(
                  key: ValueKey(activity.id),
                  activity: activity,
                  dayPlan: dayPlan,
                  onEdit: onEditActivity,
                  onDelete: onDeleteActivity,
                  onDataChanged: onDataChanged,
                  destination: destination,
                  imageService: imageService,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}