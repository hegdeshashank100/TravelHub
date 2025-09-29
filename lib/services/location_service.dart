import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class LocationService {
  // Singleton pattern for global access
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();

  LocationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Replace with your Foursquare API key
  static const String _foursquareApiKey = '';

  // Global location tracking variables
  Timer? _globalLocationTimer;
  Map<String, dynamic> _previousLocation = {};
  Map<String, dynamic> _currentLocation = {};
  bool _isGlobalTracking = false;
  bool _isBackgroundModeEnabled = false;

  // Start global location tracking from app startup
  void startGlobalLocationTracking() {
    if (_isGlobalTracking) return; // Already tracking

    print('🌍 STARTING GLOBAL LIVE LOCATION TRACKING FROM APP STARTUP');
    print('🚀 Location updates: Every 1 second');
    print('💾 Storage: Firebase Firestore');
    print('🔄 Source: Global App Service');
    print('============================================');

    _isGlobalTracking = true;

    // Start location tracking with 1-second intervals
    _globalLocationTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _updateGlobalLocation();
    });

    // Initial location fetch
    print('📍 Fetching initial global location...');
    _updateGlobalLocation();
  }

  // Stop global location tracking
  void stopGlobalLocationTracking() {
    print('🛑 Stopping global location tracking...');
    _globalLocationTimer?.cancel();
    _globalLocationTimer = null;
    _isGlobalTracking = false;
    print('✅ Global location tracking stopped');
  }

  // Update location with enhanced logging for global tracking
  void _updateGlobalLocation() async {
    try {
      print('🔄 [GLOBAL] Updating location...');

      // Simulate getting current GPS location
      // In real implementation, use getCurrentLocation() method below
      double mockLatitude =
          19.0760 + (DateTime.now().millisecondsSinceEpoch % 1000) / 100000;
      double mockLongitude =
          72.8777 + (DateTime.now().millisecondsSinceEpoch % 1000) / 100000;

      // Move current to previous (with same format as current location)
      if (_currentLocation.isNotEmpty) {
        _previousLocation =
            Map.from(_currentLocation); // Complete copy of current location
        print('📍 Previous location stored globally with full format');
      }

      // Update current location with simplified format
      _currentLocation = {
        'latitude': mockLatitude,
        'longitude': mockLongitude,
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('📱 [GLOBAL] New current location: $mockLatitude, $mockLongitude');
      if (_previousLocation.isNotEmpty) {
        print(
            '📱 [GLOBAL] Previous location: ${_previousLocation['latitude']}, ${_previousLocation['longitude']}');
        print(
            '📱 [GLOBAL] Previous timestamp: ${_previousLocation['timestamp']}');
      }

      // Save to Firestore
      await _saveGlobalLocationToFirestore();
    } catch (e) {
      print('❌ [GLOBAL] Error updating location: $e');
    }
  }

  // Save location to Firebase Firestore from global service
  Future<void> _saveGlobalLocationToFirestore() async {
    try {
      // Get current user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('⚠️ [GLOBAL] No user logged in, skipping location save');
        return;
      }

      print('🔥 [FIRESTORE] Updating live location for user: ${user.uid}');

      // Create simplified document data with only essential location info
      Map<String, dynamic> locationData = {
        // Current location - only essential data
        'currentLocation': {
          'latitude': _currentLocation['latitude'],
          'longitude': _currentLocation['longitude'],
          'timestamp': _currentLocation['timestamp'],
        },
        // Previous location - only essential data (if exists)
        'previousLocation': _previousLocation.isNotEmpty
            ? {
                'latitude': _previousLocation['latitude'],
                'longitude': _previousLocation['longitude'],
                'timestamp': _previousLocation['timestamp'],
              }
            : null,
        // Basic metadata
        'lastUpdated': FieldValue.serverTimestamp(),
        'uid': user.uid,
      };

      print('📄 [FIRESTORE] Document data: $locationData');

      // Update single document using set() to rewrite the same document
      await FirebaseFirestore.instance
          .collection('live_locations')
          .doc(user.uid)
          .set(locationData,
              SetOptions(merge: false)); // Rewrite entire document

      print('✅ [GLOBAL] Location saved to Firestore!');
      print(
          '📍 Current: ${_currentLocation['latitude']}, ${_currentLocation['longitude']}');
      if (_previousLocation.isNotEmpty) {
        print(
            '📍 Previous: ${_previousLocation['latitude']}, ${_previousLocation['longitude']}');
      }
      print('⏰ Timestamp: ${_currentLocation['timestamp']}');
      print('👤 User: ${user.uid}');
      print('🗂️ [FIRESTORE] Full path: live_locations/${user.uid}');
      print('============================================');
    } catch (e) {
      print('❌ [GLOBAL] Error saving to Firestore: $e');
      print('🔍 [DEBUG] Error details: ${e.toString()}');
      print('🔍 [DEBUG] Current location data: $_currentLocation');
    }
  }

  // Getters for global tracking status
  bool get isGlobalTracking => _isGlobalTracking;
  Map<String, dynamic> get globalCurrentLocation => _currentLocation;
  Map<String, dynamic> get globalPreviousLocation => _previousLocation;
  bool get isBackgroundModeEnabled => _isBackgroundModeEnabled;

  // Enable background mode for persistent tracking
  void enableBackgroundMode() {
    _isBackgroundModeEnabled = true;
    print(
        '🔋 Background mode enabled - Location will continue when app is minimized');

    // If not already tracking, start it
    if (!_isGlobalTracking) {
      startGlobalLocationTracking();
    }
  }

  // Disable background mode
  void disableBackgroundMode() {
    _isBackgroundModeEnabled = false;
    print('🔋 Background mode disabled');
  }

  // Get current location with permission handling
  Future<Position?> getCurrentLocation() async {
    try {
      print('🔄 Getting current location...');

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location services are disabled');
        throw 'Location services are disabled. Please enable location services.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Location permissions are denied');
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permissions are permanently denied');
        throw 'Location permissions are permanently denied, please enable them in settings.';
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      print('✅ Location obtained: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('❌ Error getting location: $e');
      return null;
    }
  }

  // Get address from coordinates
  Future<String> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      print('🔄 Getting address for: $latitude, $longitude');

      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        String city =
            place.locality ?? place.subAdministrativeArea ?? 'Unknown City';
        String state = place.administrativeArea ?? '';
        String country = place.country ?? '';

        String address = city;
        if (state.isNotEmpty) address += ', $state';
        if (country.isNotEmpty) address += ', $country';

        print('✅ Address found: $address');
        return address;
      }

      return 'Unknown Location';
    } catch (e) {
      print('❌ Error getting address: $e');
      return 'Unknown Location';
    }
  }

  // Get city name from coordinates
  Future<String> getCityFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return place.locality ?? place.subAdministrativeArea ?? 'Your Location';
      }

      return 'Your Location';
    } catch (e) {
      print('❌ Error getting city: $e');
      return 'Your Location';
    }
  }

  // Store user location in Firebase with digital ID
  Future<void> storeUserLocation(Position position, String address) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      print('🔄 Storing location for user: ${user.uid}');

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      Map<String, dynamic>? digitalIdData;

      if (userDoc.exists) {
        Map<String, dynamic>? userData =
            userDoc.data() as Map<String, dynamic>?;
        digitalIdData = userData?['digitalId'];
      }

      await _firestore.collection('user_locations').doc(user.uid).set({
        'userId': user.uid,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': address,
        'accuracy': position.accuracy,
        'timestamp': FieldValue.serverTimestamp(),
        'lastUpdated': DateTime.now().toIso8601String(),
        'digitalIdAvailable': digitalIdData != null,
        'userVerified': user.emailVerified,
        'userName': user.displayName ?? 'Unknown User',
        'userEmail': user.email,
      }, SetOptions(merge: true));

      await _firestore.collection('users').doc(user.uid).update({
        'currentLocation': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'address': address,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });

      print('✅ Location stored successfully');
    } catch (e) {
      print('❌ Error storing location: $e');
    }
  }

  // Get nearby tourist places using Foursquare Places API
  Future<List<Map<String, dynamic>>> getNearbyTouristPlaces(
      double latitude, double longitude,
      {int radiusKm = 50}) async {
    try {
      print('🔄 Getting nearby tourist places from Foursquare...');

      // Multiple Foursquare API categories for better tourist places
      List<String> categories = [
        '10000', // Arts & Entertainment
        '12000', // Cultural Sites
        '16000', // Landmark
        '17000', // Outdoors & Recreation
      ];

      List<Map<String, dynamic>> allTouristPlaces = [];

      // Try each category to get diverse tourist attractions
      for (String category in categories) {
        final String url = 'https://api.foursquare.com/v3/places/search'
            '?ll=$latitude,$longitude'
            '&radius=${radiusKm * 1000}' // Convert km to meters
            '&categories=$category'
            '&limit=8';

        try {
          final response = await http.get(
            Uri.parse(url),
            headers: {
              'Authorization': _foursquareApiKey,
              'Accept': 'application/json',
            },
          ).timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            List<dynamic> results = data['results'] ?? [];

            for (var place in results) {
              try {
                String name = place['name']?.toString() ?? '';
                if (name.isEmpty) continue;

                var location = place['geocodes']?['main'];
                if (location == null) continue;

                double placeLat =
                    double.tryParse(location['latitude']?.toString() ?? '0') ??
                        0;
                double placeLng =
                    double.tryParse(location['longitude']?.toString() ?? '0') ??
                        0;

                if (placeLat == 0 || placeLng == 0) continue;

                List<dynamic> categoriesData = place['categories'] ?? [];
                String categoryName = categoriesData.isNotEmpty
                    ? categoriesData[0]['name'] ?? ''
                    : '';

                double distance =
                    _calculateDistance(latitude, longitude, placeLat, placeLng);

                // Only add places within specified radius
                if (distance <= radiusKm) {
                  allTouristPlaces.add({
                    'name': _cleanPlaceName(name),
                    'description':
                        _generateDescriptionFromCategory(categoryName),
                    'image': _getImageFromCategory(categoryName),
                    'distance': distance,
                    'coordinates': {
                      'lat': placeLat,
                      'lng': placeLng,
                    },
                    'category': categoryName,
                    'rating': _generateRatingFromCategory(categoryName),
                  });
                }
              } catch (e) {
                print('⚠️ Error parsing place: $e');
                continue;
              }
            }
          }
        } catch (e) {
          print('⚠️ Error fetching category $category: $e');
          continue;
        }
      }

      // Remove duplicates and sort
      Map<String, Map<String, dynamic>> uniquePlaces = {};
      for (var place in allTouristPlaces) {
        String key = place['name'].toString().toLowerCase();
        if (!uniquePlaces.containsKey(key)) {
          uniquePlaces[key] = place;
        }
      }

      List<Map<String, dynamic>> touristPlaces = uniquePlaces.values.toList();

      // Sort by distance and rating
      touristPlaces.sort((a, b) {
        double scoreA = (5 - (a['distance'] as num).toDouble()) +
            ((a['rating'] as num).toDouble() * 0.5);
        double scoreB = (5 - (b['distance'] as num).toDouble()) +
            ((b['rating'] as num).toDouble() * 0.5);
        return scoreB.compareTo(scoreA);
      });

      touristPlaces = touristPlaces.take(10).toList();

      print('✅ Found ${touristPlaces.length} nearby tourist places');

      if (touristPlaces.isNotEmpty) {
        return touristPlaces;
      } else {
        print('⚠️ No places found from API, using fallback');
        return getFallbackPlaces();
      }
    } catch (e) {
      print('❌ Error getting nearby places: $e');
      return getFallbackPlaces();
    }
  }

  // Clean place names
  String _cleanPlaceName(String name) {
    name = name.replaceAll(RegExp(r'^(The|A|An)\s+', caseSensitive: false), '');
    name = name.replaceAll(RegExp(r'\s+\(.*\)$'), '');
    return name.length > 30 ? '${name.substring(0, 30)}...' : name;
  }

  // Generate description from category
  String _generateDescriptionFromCategory(String category) {
    String lower = category.toLowerCase();
    if (lower.contains('museum')) return 'Explore history and culture';
    if (lower.contains('monument') || lower.contains('historic'))
      return 'Historical significance and beauty';
    if (lower.contains('temple') || lower.contains('religious'))
      return 'Spiritual and architectural marvel';
    if (lower.contains('park') || lower.contains('garden'))
      return 'Natural beauty and relaxation';
    if (lower.contains('beach')) return 'Scenic waterfront destination';
    if (lower.contains('market') || lower.contains('shopping'))
      return 'Local shopping and culture';
    if (lower.contains('restaurant') || lower.contains('cafe'))
      return 'Local cuisine and dining';
    return 'Popular local attraction';
  }

  // Generate rating from category
  double _generateRatingFromCategory(String category) {
    String lower = category.toLowerCase();
    if (lower.contains('museum') || lower.contains('monument')) return 4.3;
    if (lower.contains('temple') || lower.contains('religious')) return 4.5;
    if (lower.contains('park') || lower.contains('garden')) return 4.2;
    if (lower.contains('beach')) return 4.4;
    if (lower.contains('historic')) return 4.3;
    return 4.0;
  }

  // Get image from category
  String _getImageFromCategory(String category) {
    String lower = category.toLowerCase();
    if (lower.contains('museum')) {
      return 'https://images.unsplash.com/photo-1571115764595-644a1f56a55c?w=300&h=200&fit=crop';
    }
    if (lower.contains('monument') || lower.contains('historic')) {
      return 'https://images.unsplash.com/photo-1539650116574-75c0c6d75d2f?w=300&h=200&fit=crop';
    }
    if (lower.contains('temple') || lower.contains('religious')) {
      return 'https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?w=300&h=200&fit=crop';
    }
    if (lower.contains('park') || lower.contains('garden')) {
      return 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=300&h=200&fit=crop';
    }
    if (lower.contains('beach')) {
      return 'https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?w=300&h=200&fit=crop';
    }
    return 'https://images.unsplash.com/photo-1577720643271-6760b6f96990?w=300&h=200&fit=crop';
  }

  // Fallback places when API fails
  List<Map<String, dynamic>> getFallbackPlaces() {
    return [
      {
        'name': 'Historical Heritage Site',
        'description': 'Discover local culture and rich history',
        'image':
            'https://images.unsplash.com/photo-1539650116574-75c0c6d75d2f?w=300&h=200&fit=crop',
        'distance': 5.2,
        'rating': 4.3,
        'category': 'Cultural Site',
      },
      {
        'name': 'Scenic Mountain Viewpoint',
        'description': 'Breathtaking views and perfect for photography',
        'image':
            'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=300&h=200&fit=crop',
        'distance': 8.7,
        'rating': 4.5,
        'category': 'Natural Wonder',
      },
      {
        'name': 'Local Art & Cultural Center',
        'description': 'Experience local arts, crafts and traditions',
        'image':
            'https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?w=300&h=200&fit=crop',
        'distance': 12.3,
        'rating': 4.1,
        'category': 'Arts & Culture',
      },
      {
        'name': 'Beautiful Nature Park',
        'description': 'Wildlife sanctuary and natural beauty spot',
        'image':
            'https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?w=300&h=200&fit=crop',
        'distance': 15.8,
        'rating': 4.4,
        'category': 'Nature & Wildlife',
      },
      {
        'name': 'Ancient Temple Complex',
        'description': 'Sacred architecture and spiritual experience',
        'image':
            'https://images.unsplash.com/photo-1571115764595-644a1f56a55c?w=300&h=200&fit=crop',
        'distance': 18.5,
        'rating': 4.6,
        'category': 'Religious Site',
      },
      {
        'name': 'Lakeside Recreation Area',
        'description': 'Peaceful waters and recreational activities',
        'image':
            'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=300&h=200&fit=crop',
        'distance': 22.1,
        'rating': 4.2,
        'category': 'Recreation',
      },
      {
        'name': 'Historic Fort & Museum',
        'description': 'Ancient fortress with guided tours available',
        'image':
            'https://images.unsplash.com/photo-1583423230902-b653abc541ab?w=300&h=200&fit=crop',
        'distance': 28.3,
        'rating': 4.3,
        'category': 'Historical Landmark',
      },
      {
        'name': 'Botanical Gardens',
        'description': 'Exotic plants and peaceful walking trails',
        'image':
            'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=300&h=200&fit=crop',
        'distance': 32.7,
        'rating': 4.1,
        'category': 'Gardens & Parks',
      },
      {
        'name': 'Adventure Sports Center',
        'description': 'Thrilling outdoor activities and sports',
        'image':
            'https://images.unsplash.com/photo-1551632811-561732d1e306?w=300&h=200&fit=crop',
        'distance': 38.9,
        'rating': 4.4,
        'category': 'Adventure & Sports',
      },
      {
        'name': 'Traditional Market District',
        'description': 'Local crafts, food and cultural shopping',
        'image':
            'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=300&h=200&fit=crop',
        'distance': 42.5,
        'rating': 4.0,
        'category': 'Shopping & Culture',
      },
    ];
  }

  // Public fallback places method for external access
  List<Map<String, dynamic>> getDefaultPlaces() {
    return getFallbackPlaces();
  }

  // Calculate distance between coordinates
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  // Get last known location
  Future<Map<String, dynamic>?> getLastKnownLocation() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      DocumentSnapshot doc =
          await _firestore.collection('user_locations').doc(user.uid).get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }

      return null;
    } catch (e) {
      print('❌ Error getting last known location: $e');
      return null;
    }
  }

  // Cleanup when app terminates
  void dispose() {
    print('🧹 Disposing LocationService...');
    stopGlobalLocationTracking();
  }
}
