import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ImageService {
  static const String _baseUrl = 'https://api.unsplash.com';
  static final String _accessKey = dotenv.get('UNSPLASH_ACCESS_KEY', fallback: 'YOUR_UNSPLASH_KEY');

  Future<String?> fetchImage(String query) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/search/photos?query=${Uri.encodeComponent(query)}&per_page=1',
        ),
        headers: {'Authorization': 'Client-ID $_accessKey'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List;
        
        if (results.isNotEmpty) {
          return results[0]['urls']['regular'];
        }
      }
      
      return 'https://via.placeholder.com/800x600?text=No+Image+Available';
    } catch (e) {
      print('Error fetching image: $e');
      return null;
    }
  }
}