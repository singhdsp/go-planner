import 'package:flutter/material.dart';
import 'package:go_planner/models/itinerary.dart';
import 'package:go_planner/screens/itinerary_view_screen.dart';
import 'package:go_planner/services/storage_service.dart';
import 'package:intl/intl.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final StorageService _storageService = StorageService();
  List<Itinerary> _savedItineraries = [];
  bool _isLoading = true;
  Map<String, bool> _activeStatus = {}; // Track active status for each itinerary

  @override
  void initState() {
    super.initState();
    _loadSavedItineraries();
    _loadActiveStatuses();
  }

  Future<void> _loadSavedItineraries() async {
    setState(() => _isLoading = true);
    try {
      final itineraries = await _storageService.getSavedItineraries();
      setState(() {
        _savedItineraries = itineraries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading saved itineraries: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadActiveStatuses() async {
    try {
      final statuses = await _storageService.getActiveStatuses();
      setState(() {
        _activeStatus = statuses;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading active statuses: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteItinerary(String id) async {
    try {
      await _storageService.removeItinerary(id);
      await _loadSavedItineraries();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Itinerary deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting itinerary: ${e.toString()}')),
      );
    }
  }

  Future<void> _toggleActive(String id) async {
    final newStatus = !(_activeStatus[id] ?? false);
    try {
      await _storageService.saveActiveStatus(id, newStatus);
      setState(() {
        _activeStatus[id] = newStatus;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus 
            ? 'Itinerary activated. Alerts enabled.' 
            : 'Itinerary deactivated. Alerts disabled.'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: ${e.toString()}')),
      );
    }
  }

  void _showAlerts(Itinerary itinerary) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AlertsScreen(itinerary: itinerary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Itineraries'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedItineraries.isEmpty
              ? _buildEmptyState()
              : _buildItineraryList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.bookmark_border,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No saved itineraries yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create new itineraries and save them to view here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ), 
        ],
      ),
    );
  }

  Widget _buildItineraryList() {
    return RefreshIndicator(
      onRefresh: _loadSavedItineraries,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _savedItineraries.length,
        itemBuilder: (context, index) {
          final itinerary = _savedItineraries[index];
          return _buildItineraryCard(itinerary);
        },
      ),
    );
  }

  Widget _buildItineraryCard(Itinerary itinerary) {
    final formattedDate = DateFormat('MMM d, yyyy').format(itinerary.createdAt);
    final isActive = _activeStatus[itinerary.id] ?? false;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              itinerary.destination,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.notifications_active, size: 14, color: Colors.green[700]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Active',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${itinerary.days} Days • Created on $formattedDate',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteConfirmation(itinerary.id);
                    } else if (value == 'active') {
                      _toggleActive(itinerary.id);
                    } else if (value == 'alerts') {
                      _showAlerts(itinerary);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'active',
                      child: Row(
                        children: [
                          Icon(
                            isActive ? Icons.toggle_on : Icons.toggle_off,
                            color: isActive ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isActive ? 'Active (ON)' : 'Active (OFF)',
                            style: TextStyle(
                              color: isActive ? Colors.green : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'alerts',
                      enabled: isActive,
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: isActive ? Colors.orange : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'View Alerts',
                            style: TextStyle(
                              color: isActive ? Colors.black : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: itinerary.daysPlans.length,
                itemBuilder: (context, index) {
                  final dayPlan = itinerary.daysPlans[index];
                  return Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Day ${dayPlan.day}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${dayPlan.activities.length} Activities',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ItineraryViewScreen(itinerary: itinerary),
                    ),
                  ).then((_) {
                    _loadSavedItineraries();
                  });
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('View Full Itinerary'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Itinerary'),
        content: const Text('Are you sure you want to delete this itinerary? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteItinerary(id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// New screen for alerts
class AlertsScreen extends StatefulWidget {
  final Itinerary itinerary;

  const AlertsScreen({super.key, required this.itinerary});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  bool _isLoading = true;
  List<Alert> _alerts = [];

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  Future<void> _fetchAlerts() async {
    setState(() => _isLoading = true);
    
    try {
      // Simulate fetching alerts based on itinerary activities
      // In a real app, you would use an API service to get real alerts
      await Future.delayed(const Duration(seconds: 1));
      
      // Generate random alerts for the itinerary activities
      final generatedAlerts = _generateRandomAlerts();
      
      setState(() {
        _alerts = generatedAlerts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching alerts: ${e.toString()}')),
      );
    }
  }

  List<Alert> _generateRandomAlerts() {
    final List<Alert> alerts = [];
    final List<String> alertTypes = [
      'Traffic',
      'Weather',
      'Closure',
      'Event',
      'Safety',
    ];
    
    final List<String> trafficMessages = [
      'Heavy traffic reported near',
      'Road construction causing delays at',
      'Accident reported on the route to',
      'Expect longer travel times to',
      'Limited parking available at',
    ];
    
    final List<String> weatherMessages = [
      'Rain forecasted during your visit to',
      'Unusually high temperatures expected at',
      'Strong winds may affect outdoor activities at',
      'Thunderstorms expected near',
      'Foggy conditions reported around',
    ];
    
    final List<String> closureMessages = [
      'Temporary closure announced for',
      'Reduced hours today at',
      'Partial area closure at',
      'Maintenance work scheduled at',
      'Special event limiting access to',
    ];
    
    final List<String> eventMessages = [
      'Special exhibition taking place at',
      'Increased crowds expected at',
      'Cultural event could cause congestion around',
    ];
    
    final List<String> safetyMessages = [
      'Health advisory issued for visitors to',
      'Increased pickpocket reports around',
      'Be aware of ongoing construction at',
      'Recent incidents reported near',
      'Carry extra water when visiting',
    ];
    
    // Collect all activities from all days
    final allActivities = <Activity>[];
    for (final dayPlan in widget.itinerary.daysPlans) {
      allActivities.addAll(dayPlan.activities);
    }
    
    // Generate 5-7 random alerts
    final alertCount = 5 + (allActivities.length > 2 ? 2 : allActivities.length);
    final alertCount2 = alertCount > allActivities.length ? allActivities.length : alertCount;
    
    for (int i = 0; i < alertCount2; i++) {
      if (allActivities.isEmpty) break;
      
      // Select a random activity
      final randomIndex = i % allActivities.length;
      final activity = allActivities[randomIndex];
      
      // Select a random alert type
      final alertType = alertTypes[i % alertTypes.length];
      
      // Generate message based on alert type
      String message;
      String icon;
      Color color;
      
      switch (alertType) {
        case 'Traffic':
          message = '${trafficMessages[i % trafficMessages.length]} ${activity.title}';
          icon = 'traffic';
          color = Colors.red;
          break;
        case 'Weather':
          message = '${weatherMessages[i % weatherMessages.length]} ${activity.title}';
          icon = 'cloud';
          color = Colors.blue;
          break;
        case 'Closure':
          message = '${closureMessages[i % closureMessages.length]} ${activity.title}';
          icon = 'block';
          color = Colors.orange;
          break;
        case 'Event':
          message = '${eventMessages[i % eventMessages.length]} ${activity.title}';
          icon = 'event';
          color = Colors.purple;
          break;
        case 'Safety':
          message = '${safetyMessages[i % safetyMessages.length]} ${activity.title}';
          icon = 'warning';
          color = Colors.amber;
          break;
        default:
          message = 'Alert regarding ${activity.title}';
          icon = 'info';
          color = Colors.grey;
      }
      
      alerts.add(Alert(
        id: 'alert_${activity.id}_$i',
        type: alertType,
        message: message,
        activityTitle: activity.title,
        icon: icon,
        color: color,
        timestamp: DateTime.now().subtract(Duration(hours: i * 2)),
      ));
    }
    
    return alerts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alerts for ${widget.itinerary.destination}'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alerts.isEmpty
              ? _buildEmptyState()
              : _buildAlertsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.notifications_off,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No alerts found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Currently there are no alerts for your itinerary',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchAlerts,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Alerts'),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList() {
    return RefreshIndicator(
      onRefresh: _fetchAlerts,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _alerts.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final alert = _alerts[index];
          return _buildAlertCard(alert);
        },
      ),
    );
  }

  Widget _buildAlertCard(Alert alert) {
    final formattedTime = DateFormat('h:mm a').format(alert.timestamp);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: alert.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: alert.color.withOpacity(0.2),
          child: Icon(
            _getIconData(alert.icon),
            color: alert.color,
          ),
        ),
        title: Text(
          alert.message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: alert.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  alert.type,
                  style: TextStyle(
                    fontSize: 12,
                    color: alert.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formattedTime,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'traffic':
        return Icons.traffic;
      case 'cloud':
        return Icons.cloud;
      case 'block':
        return Icons.block;
      case 'event':
        return Icons.event;
      case 'warning':
        return Icons.warning_amber;
      default:
        return Icons.info;
    }
  }
}

// Model for alerts
class Alert {
  final String id;
  final String type;
  final String message;
  final String activityTitle;
  final String icon;
  final Color color;
  final DateTime timestamp;

  Alert({
    required this.id,
    required this.type,
    required this.message,
    required this.activityTitle,
    required this.icon,
    required this.color,
    required this.timestamp,
  });
}