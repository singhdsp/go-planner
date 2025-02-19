import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_planner/models/itinerary.dart';

class StorageService {
  static const String _itinerariesKey = 'saved_itineraries';
  static const String _themeKey = 'dark_mode';

  Future<List<Itinerary>> getSavedItineraries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_itinerariesKey) ?? [];
    
    return jsonList
        .map((json) => Itinerary.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> saveItinerary(Itinerary itinerary) async {
    final prefs = await SharedPreferences.getInstance();
    final existingList = prefs.getStringList(_itinerariesKey) ?? [];
    
    existingList.add(jsonEncode(itinerary.toJson()));
    
    await prefs.setStringList(_itinerariesKey, existingList);
  }

  Future<void> removeItinerary(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final existingList = prefs.getStringList(_itinerariesKey) ?? [];

    final itineraries = existingList
        .map((json) => Itinerary.fromJson(jsonDecode(json)))
        .toList();
    
    final filteredList = itineraries
        .where((itinerary) => itinerary.id != id)
        .map((itinerary) => jsonEncode(itinerary.toJson()))
        .toList();
    
    await prefs.setStringList(_itinerariesKey, filteredList);
  }

  Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, value);
  }
}