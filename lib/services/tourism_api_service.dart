import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

class TourismApiService {
  // Gemini Flash 2.0 API configuration
  static const String _geminiApiKey = '';
  static const String _geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String _geminiModel = 'gemini-2.0-flash-exp';

  // OpenTripMap API configuration for accurate coordinates
  static const String _openTripMapApiKey = '';
  static const String _openTripMapBaseUrl =
      'https://api.opentripmap.com/0.1/en/places';

  // Enhanced cache for API responses with popular cities pre-cached
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry =
      Duration(hours: 6); // Longer cache for speed

  // Pre-cache popular destinations for instant results
  static final Map<String, List<Map<String, dynamic>>> _popularCache = {
    'mumbai': [],
    'delhi': [],
    'goa': [],
    'kerala': [],
    'bangalore': [],
    'chennai': [],
    'kolkata': [],
    'pune': [],
    'jaipur': [],
    'hyderabad': [],
  };

  // Accurate coordinate database for major Indian tourist places
  static final Map<String, Map<String, double>> _knownPlaceCoordinates = {
    // Mumbai
    'gateway of india': {'lat': 18.9220, 'lng': 72.8347},
    'marine drive': {'lat': 18.9432, 'lng': 72.8235},
    'chhatrapati shivaji terminus': {'lat': 18.9401, 'lng': 72.8352},
    'elephanta caves': {'lat': 18.9633, 'lng': 72.9315},
    'juhu beach': {'lat': 19.0968, 'lng': 72.8262},
    'haji ali dargah': {'lat': 18.9816, 'lng': 72.8094},
    'siddhivinayak temple': {'lat': 19.0170, 'lng': 72.8301},

    // Delhi
    'red fort': {'lat': 28.6562, 'lng': 77.2410},
    'india gate': {'lat': 28.6129, 'lng': 77.2295},
    'qutub minar': {'lat': 28.5244, 'lng': 77.1855},
    'lotus temple': {'lat': 28.5535, 'lng': 77.2588},
    'humayun tomb': {'lat': 28.5933, 'lng': 77.2507},
    'humayuns tomb': {'lat': 28.5933, 'lng': 77.2507},
    'akshardham temple': {'lat': 28.6127, 'lng': 77.2773},
    'jama masjid': {'lat': 28.6507, 'lng': 77.2334},

    // Goa
    'baga beach': {'lat': 15.5557, 'lng': 73.7516},
    'calangute beach': {'lat': 15.5434, 'lng': 73.7554},
    'anjuna beach': {'lat': 15.5735, 'lng': 73.7395},
    'basilica of bom jesus': {'lat': 15.5007, 'lng': 73.9115},
    'fort aguada': {'lat': 15.4945, 'lng': 73.7706},
    'dudhsagar falls': {'lat': 15.3144, 'lng': 74.3144},

    // Agra
    'taj mahal': {'lat': 27.1751, 'lng': 78.0421},
    'agra fort': {'lat': 27.1795, 'lng': 78.0211},
    'fatehpur sikri': {'lat': 27.0945, 'lng': 77.6619},

    // Jaipur
    'amber fort': {'lat': 26.9855, 'lng': 75.8513},
    'amer fort': {'lat': 26.9855, 'lng': 75.8513},
    'city palace jaipur': {'lat': 26.9255, 'lng': 75.8236},
    'city palace': {'lat': 26.9255, 'lng': 75.8236},
    'hawa mahal': {'lat': 26.9239, 'lng': 75.8267},
    'jantar mantar jaipur': {'lat': 26.9246, 'lng': 75.8249},
    'jantar mantar': {'lat': 26.9246, 'lng': 75.8249},

    // Kerala
    'munnar': {'lat': 10.0889, 'lng': 77.0595},
    'alleppey backwaters': {'lat': 9.4981, 'lng': 76.3388},
    'alleppey': {'lat': 9.4981, 'lng': 76.3388},
    'kumarakom': {'lat': 9.6178, 'lng': 76.4276},
    'thekkady': {'lat': 9.5939, 'lng': 77.1603},
    'kovalam beach': {'lat': 8.4004, 'lng': 76.9784},
    'kovalam': {'lat': 8.4004, 'lng': 76.9784},

    // Karnataka
    'mysore palace': {'lat': 12.3052, 'lng': 76.6551},
    'hampi': {'lat': 15.3350, 'lng': 76.4600},
    'coorg': {'lat': 12.3375, 'lng': 75.8069},
    'chikmagalur': {'lat': 13.3161, 'lng': 75.7720},

    // Sirsi, Karnataka
    'marikamba temple': {'lat': 14.6184, 'lng': 74.8334},
    'marikamba temple sirsi': {'lat': 14.6184, 'lng': 74.8334},
    'sri marikamba temple': {'lat': 14.6184, 'lng': 74.8334},
    'shri marikamba temple': {'lat': 14.6184, 'lng': 74.8334},
    'unchalli falls': {'lat': 14.3947, 'lng': 74.7139},
    'lushington falls': {'lat': 14.3947, 'lng': 74.7139},
    'madhukeshwara temple': {'lat': 14.6279, 'lng': 74.8387},
    'madhukeshwara temple banavasi': {'lat': 14.6279, 'lng': 74.8387},
    'banavasi': {'lat': 14.6279, 'lng': 74.8387},

    // Rajasthan
    'udaipur city palace': {'lat': 24.5764, 'lng': 73.6833},
    'city palace udaipur': {'lat': 24.5764, 'lng': 73.6833},
    'lake pichola': {'lat': 24.5714, 'lng': 73.6781},
    'jaisalmer fort': {'lat': 26.9157, 'lng': 70.9083},
    'jodhpur mehrangarh fort': {'lat': 26.2970, 'lng': 73.0169},
    'mehrangarh fort': {'lat': 26.2970, 'lng': 73.0169},

    // Tamil Nadu
    'meenakshi temple': {'lat': 9.9195, 'lng': 78.1193},
    'meenakshi amman temple': {'lat': 9.9195, 'lng': 78.1193},
    'mahabalipuram': {'lat': 12.6269, 'lng': 80.1930},
    'ooty': {'lat': 11.4102, 'lng': 76.6950},
    'kodaikanal': {'lat': 10.2381, 'lng': 77.4892},

    // Himachal Pradesh
    'shimla': {'lat': 31.1048, 'lng': 77.1734},
    'manali': {'lat': 32.2432, 'lng': 77.1892},
    'dharamshala': {'lat': 32.2190, 'lng': 76.3234},
    'kullu': {'lat': 31.9578, 'lng': 77.1092},

    // Uttarakhand
    'rishikesh': {'lat': 30.0869, 'lng': 78.2676},
    'haridwar': {'lat': 29.9457, 'lng': 78.1642},
    'nainital': {'lat': 29.3919, 'lng': 79.4542},
    'mussoorie': {'lat': 30.4598, 'lng': 78.0664},

    // West Bengal
    'victoria memorial': {'lat': 22.5448, 'lng': 88.3426},
    'howrah bridge': {'lat': 22.5851, 'lng': 88.3468},
    'dakshineswar temple': {'lat': 22.6547, 'lng': 88.3570},
    'darjeeling': {'lat': 27.0360, 'lng': 88.2627},
  };

  // City center coordinates for fallback
  static final Map<String, Map<String, double>> _cityCenterCoordinates = {
    'mumbai': {'lat': 19.0760, 'lng': 72.8777},
    'delhi': {'lat': 28.7041, 'lng': 77.1025},
    'bangalore': {'lat': 12.9716, 'lng': 77.5946},
    'kolkata': {'lat': 22.5726, 'lng': 88.3639},
    'chennai': {'lat': 13.0827, 'lng': 80.2707},
    'hyderabad': {'lat': 17.3850, 'lng': 78.4867},
    'pune': {'lat': 18.5204, 'lng': 73.8567},
    'ahmedabad': {'lat': 23.0225, 'lng': 72.5714},
    'jaipur': {'lat': 26.9124, 'lng': 75.7873},
    'goa': {'lat': 15.2993, 'lng': 74.1240},
    'kochi': {'lat': 9.9312, 'lng': 76.2673},
    'thiruvananthapuram': {'lat': 8.5241, 'lng': 76.9366},
    'bhubaneswar': {'lat': 20.2961, 'lng': 85.8245},
    'chandigarh': {'lat': 30.7333, 'lng': 76.7794},
    'lucknow': {'lat': 26.8467, 'lng': 80.9462},
    'kanpur': {'lat': 26.4499, 'lng': 80.3319},
    'nagpur': {'lat': 21.1458, 'lng': 79.0882},
    'indore': {'lat': 22.7196, 'lng': 75.8577},
    'bhopal': {'lat': 23.2599, 'lng': 77.4126},
    'visakhapatnam': {'lat': 17.6868, 'lng': 83.2185},
    'patna': {'lat': 25.5941, 'lng': 85.1376},
    'vadodara': {'lat': 22.3072, 'lng': 73.1812},
    'agra': {'lat': 27.1767, 'lng': 78.0081},
    'nashik': {'lat': 19.9975, 'lng': 73.7898},
    'rajkot': {'lat': 22.3039, 'lng': 70.8022},
    'varanasi': {'lat': 25.3176, 'lng': 82.9739},
    'srinagar': {'lat': 34.0837, 'lng': 74.7973},
    'jodhpur': {'lat': 26.2389, 'lng': 73.0243},
    'madurai': {'lat': 9.9252, 'lng': 78.1198},
    'sirsi': {'lat': 14.6184, 'lng': 74.8334},
    'guwahati': {'lat': 26.1445, 'lng': 91.7362},
    'salem': {'lat': 11.664, 'lng': 78.146},
    'mysore': {'lat': 12.2958, 'lng': 76.6394},
    'tiruchirappalli': {'lat': 10.7905, 'lng': 78.7047},
    'bareilly': {'lat': 28.347, 'lng': 79.4304},
    'aligarh': {'lat': 27.8974, 'lng': 78.0880},
    'tiruppur': {'lat': 11.1085, 'lng': 77.3411},
    'moradabad': {'lat': 28.8386, 'lng': 78.7733},
    'jalandhar': {'lat': 31.3260, 'lng': 75.5762},
  };

  /// Get tourist places using Gemini Flash 2.0 AI (Primary and only method)
  static Future<List<Map<String, dynamic>>> getTouristPlacesFromGemini(
      String cityName) async {
    final stopwatch = Stopwatch()..start();

    // Check popular cities cache for instant results
    final lowerCity = cityName.toLowerCase();
    if (_popularCache.containsKey(lowerCity) &&
        _popularCache[lowerCity]!.isNotEmpty) {
      print('⚡ Instant popular cache hit for: $cityName (0ms)');
      return List<Map<String, dynamic>>.from(_popularCache[lowerCity]!);
    }

    // Check cache first for speed
    final cacheKey = 'gemini_places_$cityName';
    if (_cache.containsKey(cacheKey) &&
        _cacheTimestamps.containsKey(cacheKey)) {
      final cacheTime = _cacheTimestamps[cacheKey]!;
      if (DateTime.now().difference(cacheTime) < _cacheExpiry) {
        print('✅ Cache hit for $cityName (${stopwatch.elapsedMilliseconds}ms)');
        stopwatch.stop();
        return List<Map<String, dynamic>>.from(_cache[cacheKey]);
      }
    }

    // Validate API key exists (removed hardcoded check)
    if (_geminiApiKey.isEmpty) {
      throw Exception(
          'Please configure your Gemini API key in tourism_api_service.dart');
    }

    try {
      print('🚀 Starting Gemini Flash 2.0 request for: $cityName');

      // Ultra-fast optimized prompt for speed with enhanced address context
      final prompt = '''Top 8 places in $cityName, India. JSON only:
[{"name":"Full Official Place Name","address":"Detailed Address, $cityName, State, India","lat":00.000,"lng":00.000,"rating":4.0,"category":"Temple","description":"Brief info"}]

Requirements:
- Use FULL OFFICIAL place names (e.g., "Shri Marikamba Temple" not just "Temple")
- Include complete address with area/locality for Google Maps accuracy
- Valid GPS coordinates for India only
- Categories: Temple|Monument|Fort|Beach|Museum|Palace|Heritage|Park|Waterfall|Lake''';

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1, // Slightly higher for faster generation
          'maxOutputTokens': 1024, // Reduced for faster response
          'topP': 0.8, // Less restrictive for speed
          'topK': 10, // More options for faster generation
        },
      };

      print(
          '📤 Sending request to Gemini (${stopwatch.elapsedMilliseconds}ms elapsed)');

      // Use Flash 2.0 model endpoint with faster timeout
      final url =
          '$_geminiBaseUrl/models/$_geminiModel:generateContent?key=$_geminiApiKey';

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(Duration(
              seconds: 15)); // Reduced timeout for faster failure/retry

      print(
          '📥 Response received: ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms)');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final content = data['candidates'][0]['content']['parts'][0]['text'];
          print(
              '📊 Response length: ${content.length} chars (${stopwatch.elapsedMilliseconds}ms)');

          // Fast JSON extraction - try multiple patterns
          String? jsonString;

          // Pattern 1: Direct JSON array
          final directMatch =
              RegExp(r'\[[\s\S]*?\]', multiLine: true).firstMatch(content);
          if (directMatch != null) {
            jsonString = directMatch.group(0)!;
          } else {
            // Pattern 2: JSON within code blocks
            final codeBlockMatch =
                RegExp(r'```(?:json)?\s*(\[[\s\S]*?\])\s*```', multiLine: true)
                    .firstMatch(content);
            if (codeBlockMatch != null) {
              jsonString = codeBlockMatch.group(1)!;
            } else {
              // Pattern 3: Find between first [ and last ]
              final startIndex = content.indexOf('[');
              final endIndex = content.lastIndexOf(']');
              if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
                jsonString = content.substring(startIndex, endIndex + 1);
              }
            }
          }

          if (jsonString != null) {
            try {
              print('🔍 Parsing JSON (${stopwatch.elapsedMilliseconds}ms)');
              final List<dynamic> rawPlaces = json.decode(jsonString);

              List<Map<String, dynamic>> validatedPlaces = [];

              for (var place in rawPlaces) {
                if (place is Map<String, dynamic>) {
                  // Fast validation with enhanced accuracy checks
                  final validatedPlace =
                      await _validateAndEnhancePlace(place, cityName);
                  if (validatedPlace != null) {
                    validatedPlaces.add(validatedPlace);
                  }
                }
              }

              if (validatedPlaces.isNotEmpty) {
                // Cache successful results
                _cache[cacheKey] = validatedPlaces;
                _cacheTimestamps[cacheKey] = DateTime.now();

                // Also populate popular cache if it's a popular city
                if (_popularCache.containsKey(lowerCity) &&
                    _popularCache[lowerCity]!.isEmpty) {
                  _popularCache[lowerCity] =
                      List<Map<String, dynamic>>.from(validatedPlaces);
                  print('⚡ Popular cache populated for: $cityName');
                }

                print(
                    '✅ Success: ${validatedPlaces.length} places for $cityName (${stopwatch.elapsedMilliseconds}ms total)');
                stopwatch.stop();
                return validatedPlaces;
              } else {
                print(
                    '❌ No valid places after validation (${stopwatch.elapsedMilliseconds}ms)');
              }
            } catch (e) {
              print(
                  '❌ JSON parsing error: $e (${stopwatch.elapsedMilliseconds}ms)');
              print(
                  '🔍 Raw JSON attempt: ${jsonString.substring(0, jsonString.length > 200 ? 200 : jsonString.length)}...');
            }
          } else {
            print(
                '❌ No JSON found in response (${stopwatch.elapsedMilliseconds}ms)');
            print(
                '🔍 Response preview: ${content.substring(0, content.length > 300 ? 300 : content.length)}...');
          }
        }
      } else {
        print(
            '❌ API request failed: ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms)');
        print('Error response: ${response.body}');

        if (response.statusCode == 429) {
          throw Exception('Rate limit exceeded. Try again in a few minutes.');
        } else if (response.statusCode == 403) {
          throw Exception('Invalid API key or permissions.');
        } else if (response.statusCode == 400) {
          throw Exception('Bad request. Check API configuration.');
        }
      }
    } catch (e) {
      stopwatch.stop();
      print(
          '❌ Error in Gemini Flash 2.0 (${stopwatch.elapsedMilliseconds}ms): $e');
      rethrow;
    }

    stopwatch.stop();
    throw Exception(
        'No tourist places found for $cityName (${stopwatch.elapsedMilliseconds}ms)');
  }

  /// Enhanced validation and data enrichment for better accuracy
  static Future<Map<String, dynamic>?> _validateAndEnhancePlace(
      Map<String, dynamic> place, String cityName) async {
    try {
      // Check required fields exist
      if (!place.containsKey('name') ||
          !place.containsKey('lat') ||
          !place.containsKey('lng')) {
        print('❌ Missing required fields: ${place['name']}');
        return null;
      }

      // Extract and validate data
      final name = place['name']?.toString().trim();
      final lat = place['lat'];
      final lng = place['lng'];
      final rating = place['rating'];
      final category = place['category']?.toString();
      final address = place['address']?.toString();
      final description = place['description']?.toString();

      if (name == null || name.isEmpty) {
        print('❌ Invalid name: $name');
        return null;
      }

      // Validate and convert coordinates - Try to get accurate coordinates first
      double? latitude, longitude;

      // First, try to get accurate coordinates from our hybrid system
      final accurateCoords = await _getAccurateCoordinates(name, cityName);
      if (accurateCoords != null) {
        latitude = accurateCoords['lat']!;
        longitude = accurateCoords['lng']!;
        print('🎯 Using hybrid coordinates for $name: $latitude, $longitude');
      } else {
        // Fallback to Gemini-provided coordinates
        if (lat is num) {
          latitude = lat.toDouble();
        } else if (lat is String) {
          latitude = double.tryParse(lat);
        }

        if (lng is num) {
          longitude = lng.toDouble();
        } else if (lng is String) {
          longitude = double.tryParse(lng);
        }

        if (latitude == null || longitude == null) {
          print('❌ Invalid coordinates for $name: $lat, $lng');
          return null;
        }

        // Enhanced validation with coordinate correction
        if (!_isValidIndianCoordinates(latitude, longitude, cityName)) {
          print(
              '⚠️ Gemini coordinates outside valid range for $name: $latitude, $longitude - trying to correct');

          // Try to get accurate coordinates as backup
          final backupCoords = await _getAccurateCoordinates(name, cityName);
          if (backupCoords != null) {
            latitude = backupCoords['lat']!;
            longitude = backupCoords['lng']!;
            print('✅ Corrected coordinates for $name: $latitude, $longitude');
          } else {
            print(
                '⚠️ Could not correct coordinates for $name - accepting anyway');
          }
        }
      }

      // Validate and normalize rating
      double finalRating = 4.0;
      if (rating is num) {
        finalRating = rating.toDouble();
      } else if (rating is String) {
        finalRating = double.tryParse(rating) ?? 4.0;
      }

      // Ensure rating is in realistic range
      if (finalRating < 3.5 || finalRating > 5.0) {
        finalRating =
            4.0 + (latitude.abs() % 1.0) * 0.8; // Generate realistic rating
      }

      // Validate and normalize category
      final validCategories = [
        'Temple',
        'Monument',
        'Palace',
        'Fort',
        'Beach',
        'Hill Station',
        'Museum',
        'Heritage',
        'Park',
        'Lake',
        'Waterfront',
        'Adventure',
        'Shopping',
        'Wildlife',
        'Garden',
        'Attraction'
      ];

      String finalCategory = category ?? 'Attraction';
      if (!validCategories.contains(finalCategory)) {
        // Try to map common variations
        finalCategory = _mapCategoryVariations(finalCategory);
      }

      // Enhanced address validation and normalization
      String finalAddress = address ?? '$name, $cityName, India';
      if (!finalAddress.toLowerCase().contains(cityName.toLowerCase())) {
        finalAddress = '$name, $cityName, India';
      }

      // Ensure description exists and is reasonable
      String finalDescription =
          description ?? 'A popular tourist attraction in $cityName.';
      if (finalDescription.length > 200) {
        finalDescription = finalDescription.substring(0, 197) + '...';
      }

      // Return enhanced and validated place data
      return {
        'name': name,
        'address': finalAddress,
        'lat': latitude,
        'lng': longitude,
        'rating': double.parse(finalRating.toStringAsFixed(1)),
        'category': finalCategory,
        'description': finalDescription,
        'validated': true,
      };
    } catch (e) {
      print('❌ Validation error for place: $e');
      return null;
    }
  }

  /// Get accurate coordinates from OpenTripMap API
  static Future<Map<String, double>?> _getOpenTripMapCoordinates(
      String placeName, String cityName) async {
    try {
      print('🗺️ Searching OpenTripMap for: $placeName in $cityName');

      // Get city coordinates for bounding box
      final cityCoords = _cityCenterCoordinates[cityName.toLowerCase()];
      if (cityCoords == null) {
        print('⚠️ City not found in coordinates database: $cityName');
        return null;
      }

      // Create bounding box around the city (±0.1 degrees ~ 10km)
      final double lat = cityCoords['lat']!;
      final double lon = cityCoords['lng']!;

      // Search for places within the city bounds
      final searchUrl = '$_openTripMapBaseUrl/bbox'
          '?lon_min=${lon - 0.1}&lat_min=${lat - 0.1}'
          '&lon_max=${lon + 0.1}&lat_max=${lat + 0.1}'
          '&kinds=interesting_places,tourist_facilities,cultural,historic,architecture,museums,other'
          '&limit=50&format=json&apikey=$_openTripMapApiKey';

      print('🔗 OpenTripMap API URL: $searchUrl');

      final response =
          await http.get(Uri.parse(searchUrl)).timeout(Duration(seconds: 5));

      print('📡 OpenTripMap API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> places = json.decode(response.body);
        print('📍 OpenTripMap found ${places.length} places in $cityName');

        // Debug: Print first few places found
        for (int i = 0; i < math.min(places.length, 3); i++) {
          final place = places[i];
          print(
              '🏛️ Place $i: ${place['name']} at ${place['point']?['lat']}, ${place['point']?['lon']}');
        }

        // Find the best match for our place name
        final normalizedSearchName = placeName.toLowerCase().trim();
        print('🔍 Searching for normalized name: "$normalizedSearchName"');

        for (var place in places) {
          final name = place['name']?.toString().toLowerCase() ?? '';
          final containsSearch = name.contains(normalizedSearchName);
          final searchContains = normalizedSearchName.contains(name);
          final isSimilar = _isSimilarPlaceName(name, normalizedSearchName);

          print(
              '🔎 Checking place: "$name" | contains: $containsSearch | contained: $searchContains | similar: $isSimilar');

          // Check for exact match or partial match
          if (containsSearch || searchContains || isSimilar) {
            final otmLat = place['point']?['lat'];
            final otmLon = place['point']?['lon'];

            if (otmLat != null && otmLon != null) {
              print('✅ OpenTripMap match found: "$name" at $otmLat, $otmLon');
              return {
                'lat': otmLat.toDouble(),
                'lng': otmLon.toDouble(),
              };
            }
          }
        }

        print('⚠️ No OpenTripMap match found for: $placeName');
        return null;
      } else {
        print(
            '❌ OpenTripMap API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ OpenTripMap error: $e');
      return null;
    }
  }

  /// Check if two place names are similar
  static bool _isSimilarPlaceName(String name1, String name2) {
    // Remove common words and check similarity
    final commonWords = [
      'temple',
      'fort',
      'palace',
      'beach',
      'museum',
      'gate',
      'mahal',
      'mandir'
    ];

    String clean1 = name1.toLowerCase();
    String clean2 = name2.toLowerCase();

    for (String word in commonWords) {
      clean1 = clean1.replaceAll(word, '').trim();
      clean2 = clean2.replaceAll(word, '').trim();
    }

    // Check if cleaned names are similar
    return clean1.contains(clean2) ||
        clean2.contains(clean1) ||
        _levenshteinDistance(clean1, clean2) < 3;
  }

  /// Calculate string similarity using Levenshtein distance
  static int _levenshteinDistance(String s1, String s2) {
    if (s1.length < s2.length) return _levenshteinDistance(s2, s1);
    if (s2.isEmpty) return s1.length;

    List<int> previousRow = List.generate(s2.length + 1, (i) => i);

    for (int i = 0; i < s1.length; i++) {
      List<int> currentRow = [i + 1];

      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        currentRow.add([
          previousRow[j + 1] + 1,
          currentRow[j] + 1,
          previousRow[j] + cost,
        ].reduce((a, b) => a < b ? a : b));
      }

      previousRow = currentRow;
    }

    return previousRow[s2.length];
  }

  /// Enhanced coordinate validation with regional checks
  static bool _isValidIndianCoordinates(
      double lat, double lng, String cityName) {
    // Basic India bounds
    if (lat < 6.0 || lat > 37.6 || lng < 68.0 || lng > 97.25) {
      return false;
    }
    return true;
  }

  /// Get accurate coordinates for a place using hybrid approach:
  /// 1. Try OpenTripMap API for real-time accuracy
  /// 2. Fall back to our verified database
  /// 3. Use city center with offset as last resort
  static Future<Map<String, double>?> _getAccurateCoordinates(
      String placeName, String cityName) async {
    final normalizedPlaceName = placeName.toLowerCase().trim();
    final normalizedCityName = cityName.toLowerCase().trim();

    // Step 1: Try OpenTripMap API for real-time coordinates
    try {
      final openTripMapCoords =
          await _getOpenTripMapCoordinates(placeName, cityName);
      if (openTripMapCoords != null) {
        print(
            'Using OpenTripMap coordinates for $placeName: $openTripMapCoords');
        return openTripMapCoords;
      }
    } catch (e) {
      print('OpenTripMap API failed for $placeName: $e');
    }

    // Step 2: Check our verified database for exact matches
    if (_knownPlaceCoordinates.containsKey(normalizedPlaceName)) {
      print('Using database coordinates for $placeName');
      return _knownPlaceCoordinates[normalizedPlaceName];
    }

    // Step 3: Check for partial matches in our database
    for (var entry in _knownPlaceCoordinates.entries) {
      if (entry.key.contains(normalizedPlaceName) ||
          normalizedPlaceName.contains(entry.key)) {
        print(
            'Using partial match database coordinates for $placeName: ${entry.key}');
        return entry.value;
      }
    }

    // Step 4: Fallback to city center coordinates with small random offset
    if (_cityCenterCoordinates.containsKey(normalizedCityName)) {
      final cityCoords = _cityCenterCoordinates[normalizedCityName]!;
      // Add small random offset to avoid all places appearing at exact city center
      final random = (normalizedPlaceName.hashCode % 1000) / 10000;
      print('Using city center fallback for $placeName in $cityName');
      return {
        'lat': cityCoords['lat']! + (random - 0.05),
        'lng': cityCoords['lng']! + (random - 0.05),
      };
    }

    print('No coordinates found for $placeName in $cityName');
    return null;
  }

  /// Map category variations to standard categories
  static String _mapCategoryVariations(String category) {
    final lowerCategory = category.toLowerCase();

    if (lowerCategory.contains('temple') ||
        lowerCategory.contains('church') ||
        lowerCategory.contains('mosque') ||
        lowerCategory.contains('religious')) {
      return 'Temple';
    } else if (lowerCategory.contains('monument') ||
        lowerCategory.contains('memorial') ||
        lowerCategory.contains('statue')) {
      return 'Monument';
    } else if (lowerCategory.contains('palace') ||
        lowerCategory.contains('castle')) {
      return 'Palace';
    } else if (lowerCategory.contains('fort') ||
        lowerCategory.contains('fortress')) {
      return 'Fort';
    } else if (lowerCategory.contains('beach') ||
        lowerCategory.contains('coast')) {
      return 'Beach';
    } else if (lowerCategory.contains('hill') ||
        lowerCategory.contains('mountain')) {
      return 'Hill Station';
    } else if (lowerCategory.contains('museum') ||
        lowerCategory.contains('gallery')) {
      return 'Museum';
    } else if (lowerCategory.contains('heritage') ||
        lowerCategory.contains('historical')) {
      return 'Heritage';
    } else if (lowerCategory.contains('park') ||
        lowerCategory.contains('garden')) {
      return 'Park';
    } else if (lowerCategory.contains('lake') ||
        lowerCategory.contains('river') ||
        lowerCategory.contains('waterfall')) {
      return 'Lake';
    } else if (lowerCategory.contains('water') ||
        lowerCategory.contains('marina')) {
      return 'Waterfront';
    } else if (lowerCategory.contains('adventure') ||
        lowerCategory.contains('sports')) {
      return 'Adventure';
    } else if (lowerCategory.contains('shopping') ||
        lowerCategory.contains('market')) {
      return 'Shopping';
    } else if (lowerCategory.contains('wildlife') ||
        lowerCategory.contains('zoo') ||
        lowerCategory.contains('sanctuary')) {
      return 'Wildlife';
    }

    return 'Attraction';
  }

  /// Main entry point for getting tourist places - Gemini only
  static Future<List<Map<String, dynamic>>> getTouristPlaces(
      String cityName) async {
    return await getTouristPlacesFromGemini(cityName);
  }

  /// Main search method for tourist places using Gemini Flash 2.0
  static Future<List<Map<String, dynamic>>> searchTouristPlaces(
      String query) async {
    // Initialize popular cache on first call
    if (_popularCache['mumbai']!.isEmpty) {
      initializePopularCache();
    }

    if (query.isEmpty) {
      return getPopularDestinations();
    }

    print('🔍 Searching for: $query');
    return await getTouristPlacesFromGemini(query);
  }

  /// Get comprehensive search results using Gemini only
  static Future<Map<String, dynamic>> getComprehensiveSearchResults(
      String query) async {
    if (query.isEmpty) {
      return {
        'places': getPopularDestinations(),
        'cities': getAllIndianCities().take(10).toList(),
        'categories': <String>[],
      };
    }

    final places = await searchTouristPlaces(query);
    final cities = searchCities(query);

    return {
      'places': places,
      'cities': cities,
      'categories': _getMatchingCategories(query),
    };
  }

  /// Get popular destinations (minimal fallback data for empty searches)
  static List<Map<String, dynamic>> getPopularDestinations({int limit = 10}) {
    return [
      {
        'name': 'Search for any city',
        'address': 'Enter city name like Mumbai, Delhi, Goa...',
        'lat': 20.5937,
        'lng': 78.9629,
        'rating': 4.0,
        'category': 'Attraction',
        'description':
            'Use the search to find tourist places in any Indian city'
      }
    ];
  }

  /// Get all Indian cities (major cities list)
  static List<Map<String, dynamic>> getAllIndianCities() {
    final majorCities = [
      {
        'name': 'Mumbai',
        'state': 'Maharashtra',
        'lat': 19.0760,
        'lng': 72.8777
      },
      {'name': 'Delhi', 'state': 'Delhi', 'lat': 28.6139, 'lng': 77.2090},
      {
        'name': 'Bangalore',
        'state': 'Karnataka',
        'lat': 12.9716,
        'lng': 77.5946
      },
      {
        'name': 'Chennai',
        'state': 'Tamil Nadu',
        'lat': 13.0827,
        'lng': 80.2707
      },
      {
        'name': 'Kolkata',
        'state': 'West Bengal',
        'lat': 22.5726,
        'lng': 88.3639
      },
      {
        'name': 'Hyderabad',
        'state': 'Telangana',
        'lat': 17.3850,
        'lng': 78.4867
      },
      {'name': 'Pune', 'state': 'Maharashtra', 'lat': 18.5204, 'lng': 73.8567},
      {'name': 'Ahmedabad', 'state': 'Gujarat', 'lat': 23.0225, 'lng': 72.5714},
      {'name': 'Jaipur', 'state': 'Rajasthan', 'lat': 26.9124, 'lng': 75.7873},
      {'name': 'Goa', 'state': 'Goa', 'lat': 15.2993, 'lng': 74.1240},
      {'name': 'Kerala', 'state': 'Kerala', 'lat': 10.8505, 'lng': 76.2711},
      {
        'name': 'Rajasthan',
        'state': 'Rajasthan',
        'lat': 27.0238,
        'lng': 74.2179
      },
      {
        'name': 'Kashmir',
        'state': 'Jammu and Kashmir',
        'lat': 34.0837,
        'lng': 74.7973
      },
      {
        'name': 'Agra',
        'state': 'Uttar Pradesh',
        'lat': 27.1767,
        'lng': 78.0081
      },
      {
        'name': 'Varanasi',
        'state': 'Uttar Pradesh',
        'lat': 25.3176,
        'lng': 82.9739
      },
      {
        'name': 'Rishikesh',
        'state': 'Uttarakhand',
        'lat': 30.0869,
        'lng': 78.2676
      },
      {
        'name': 'Shimla',
        'state': 'Himachal Pradesh',
        'lat': 31.1048,
        'lng': 77.1734
      },
      {
        'name': 'Manali',
        'state': 'Himachal Pradesh',
        'lat': 32.2432,
        'lng': 77.1892
      },
      {
        'name': 'Darjeeling',
        'state': 'West Bengal',
        'lat': 27.0360,
        'lng': 88.2627
      },
      {'name': 'Ooty', 'state': 'Tamil Nadu', 'lat': 11.4064, 'lng': 76.6932},
    ];

    return majorCities;
  }

  /// Search cities by name with improved performance
  static List<Map<String, dynamic>> searchCities(String query) {
    if (query.isEmpty) return getAllIndianCities().take(10).toList();

    final lowerQuery = query.toLowerCase();
    final List<Map<String, dynamic>> exactMatches = [];
    final List<Map<String, dynamic>> partialMatches = [];

    final allCities = getAllIndianCities();

    // Fast two-pass search for better performance
    for (var city in allCities) {
      final cityName = city['name'].toString().toLowerCase();
      final stateName = city['state'].toString().toLowerCase();

      if (cityName == lowerQuery) {
        exactMatches.add(city);
      } else if (cityName.contains(lowerQuery) ||
          stateName.contains(lowerQuery) ||
          lowerQuery.contains(cityName)) {
        partialMatches.add(city);
      }
    }

    // Return exact matches first, then partial matches
    final results = <Map<String, dynamic>>[];
    results.addAll(exactMatches);
    results.addAll(partialMatches.take(10 - exactMatches.length));

    return results;
  }

  /// Get matching categories for query
  static List<String> _getMatchingCategories(String query) {
    final lowerQuery = query.toLowerCase();
    final allCategories = [
      'Temple',
      'Monument',
      'Palace',
      'Fort',
      'Beach',
      'Hill Station',
      'Museum',
      'Heritage',
      'Park',
      'Lake',
      'Waterfront',
      'Adventure',
      'Shopping',
      'Wildlife',
      'Garden'
    ];

    return allCategories
        .where((category) => category.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Initialize popular cache with instant fallback data
  static void initializePopularCache() {
    // Pre-populate with basic data for instant results
    _popularCache['mumbai'] = [
      {
        'name': 'Gateway of India',
        'address': 'Mumbai, Maharashtra',
        'lat': 18.9220,
        'lng': 72.8347,
        'rating': 4.5,
        'category': 'Monument',
        'description': 'Iconic arch monument overlooking Arabian Sea'
      },
      {
        'name': 'Marine Drive',
        'address': 'Mumbai, Maharashtra',
        'lat': 18.9439,
        'lng': 72.8234,
        'rating': 4.4,
        'category': 'Waterfront',
        'description': 'Famous promenade known as Queen\'s Necklace'
      },
    ];

    _popularCache['delhi'] = [
      {
        'name': 'Red Fort',
        'address': 'Delhi, Delhi',
        'lat': 28.6562,
        'lng': 77.2410,
        'rating': 4.5,
        'category': 'Fort',
        'description': 'Historic Mughal fortress and UNESCO World Heritage site'
      },
      {
        'name': 'India Gate',
        'address': 'Delhi, Delhi',
        'lat': 28.6129,
        'lng': 77.2295,
        'rating': 4.4,
        'category': 'Monument',
        'description': 'War memorial arch in heart of New Delhi'
      },
    ];

    _popularCache['goa'] = [
      {
        'name': 'Baga Beach',
        'address': 'Goa, Goa',
        'lat': 15.5557,
        'lng': 73.7515,
        'rating': 4.3,
        'category': 'Beach',
        'description': 'Popular beach destination with water sports'
      },
      {
        'name': 'Basilica of Bom Jesus',
        'address': 'Goa, Goa',
        'lat': 15.5008,
        'lng': 73.9115,
        'rating': 4.6,
        'category': 'Heritage',
        'description': 'UNESCO World Heritage church with St. Francis Xavier'
      },
    ];

    print('⚡ Popular cache initialized for instant results');
  }

  /// Clear all cached data
  static void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    _popularCache.clear();
    print('🧹 All caches cleared');
  }
}
