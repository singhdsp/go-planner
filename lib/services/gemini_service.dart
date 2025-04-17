import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:go_planner/models/itinerary.dart';

class GeminiService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com';
  static final String _apiKey = dotenv.get('GEMINI_API_KEY');

  Future<String> generateItinerary(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$_baseUrl/v1beta/models/gemini-1.5-pro:generateContent?key=$_apiKey',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text":
                      "Generate a detailed travel itinerary for: $prompt. "
                      "Include day-wise breakdown with places to visit, things to try, "
                      "and recommendations. Format as JSON with this structure: "
                      "{destination: string, days: int, daysPlans: [{day: int, "
                      "activities: [{title: string, description: string, time: string, cost: string}]}]}",
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['candidates'][0]['content']['parts'][0]['text'];
      } else {
        throw Exception('Failed to generate itinerary: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to Gemini API: $e');
    }
  }

  Future<String> updateItinerary(Itinerary currentItinerary, String updatePrompt) async {
    try {
      // Convert current itinerary to JSON string for context
      final itineraryJson = jsonEncode(currentItinerary.toJson());
      
      final response = await http.post(
        Uri.parse(
          '$_baseUrl/v1beta/models/gemini-1.5-pro:generateContent?key=$_apiKey',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text":
                      "I have an existing travel itinerary in JSON format: $itineraryJson\n\n"
                      "I need to update this itinerary based on the following request: \"$updatePrompt\"\n\n"
                      "Please provide an updated version of the entire itinerary that addresses my request while keeping the same JSON structure. "
                      "Make only necessary changes to accommodate my request, while preserving as much of the original itinerary as possible. "
                      "Return only the updated JSON with this structure: "
                      "{destination: string, days: int, daysPlans: [{day: int, "
                      "activities: [{id: string, title: string, description: string, time: string, isMustVisit: boolean, cost: string, imageUrl: string(optional)}]}]}",
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['candidates'][0]['content']['parts'][0]['text'];
      } else {
        throw Exception('Failed to update itinerary: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to Gemini API: $e');
    }
  }
}