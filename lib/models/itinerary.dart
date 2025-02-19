class Itinerary {
  final String id;
  final String destination;
  final int days;
  List<DayPlan> daysPlans;
  final DateTime createdAt;

  Itinerary({
    required this.id,
    required this.destination,
    required this.days,
    required this.daysPlans,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    return Itinerary(
      id: json['id'],
      destination: json['destination'],
      days: json['days'],
      daysPlans: (json['daysPlans'] as List)
          .map((e) => DayPlan.fromJson(e))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'destination': destination,
        'days': days,
        'daysPlans': daysPlans.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };
      
  void reorderDays(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final DayPlan item = daysPlans.removeAt(oldIndex);
    daysPlans.insert(newIndex, item);
    
    for (int i = 0; i < daysPlans.length; i++) {
      daysPlans[i] = DayPlan(
        day: i + 1,
        activities: daysPlans[i].activities,
      );
    }
  }
}

class DayPlan {
  final int day;
  final List<Activity> activities;

  DayPlan({required this.day, required this.activities});

  factory DayPlan.fromJson(Map<String, dynamic> json) {
    return DayPlan(
      day: json['day'],
      activities: (json['activities'] as List)
          .map((e) => Activity.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'activities': activities.map((e) => e.toJson()).toList(),
      };
}

class Activity {
  final String title;
  final String description;
  String? imageUrl;
  final String time;
  final bool isMustVisit;

  Activity({
    required this.title,
    required this.description,
    this.imageUrl,
    required this.time,
    this.isMustVisit = true,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      title: json['title'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      time: json['time'],
      isMustVisit: json['isMustVisit'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'time': time,
        'isMustVisit': isMustVisit,
      };
}