import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'main.dart';
import 'services/location_service.dart';
import 'services/tourism_api_service.dart';
import 'providers/localization_provider.dart';
import 'providers/theme_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LocationService _locationService = LocationService.instance;
  String _currentLocation = 'Loading...';

  String _getLocalizedWelcomeMessage(
      LocalizationProvider localizationProvider, String? city) {
    if (city != null && city.isNotEmpty) {
      return '${localizationProvider.getLocalizedText('welcome')} to $city!';
    }
    return localizationProvider.getLocalizedText('welcome');
  }

  List<Map<String, dynamic>> _nearbyPlaces = [];
  bool _isLoadingLocation = true;
  bool _isLoadingPlaces = true;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      setState(() {
        _isLoadingLocation = true;
        _isLoadingPlaces = true;
      });

      // Try to get current location
      Position? position = await _locationService.getCurrentLocation();

      if (position != null) {
        // Get address and city name
        String address = await _locationService.getAddressFromCoordinates(
            position.latitude, position.longitude);
        String city = await _locationService.getCityFromCoordinates(
            position.latitude, position.longitude);

        // Store location in Firebase
        await _locationService.storeUserLocation(position, address);

        // Get nearby tourist places using TourismApiService
        await _getNearbyTouristPlaces(city);

        print('🏞️ Found ${_nearbyPlaces.length} tourist places near $city');

        if (mounted) {
          setState(() {
            _currentLocation = city;
            _isLoadingLocation = false;
            _isLoadingPlaces = false;
          });
        }
      } else {
        // Try to get last known location
        Map<String, dynamic>? lastLocation =
            await _locationService.getLastKnownLocation();

        if (lastLocation != null && mounted) {
          String address = lastLocation['address'] ?? 'Unknown Location';
          List<String> addressParts = address.split(',');
          String city = addressParts.isNotEmpty
              ? addressParts[0].trim()
              : 'Your Location';

          setState(() {
            _currentLocation = city;
            _isLoadingLocation = false;
          });

          // Get nearby tourist places for last known location
          await _getNearbyTouristPlaces(city);
        } else if (mounted) {
          setState(() {
            _currentLocation = 'Your Location';
            _isLoadingLocation = false;
          });
        }

        // Load fallback places if no places found
        if (mounted && _nearbyPlaces.isEmpty) {
          setState(() {
            _nearbyPlaces = _getFallbackPlaces();
            _isLoadingPlaces = false;
          });
        }
      }
    } catch (e) {
      print('Error initializing location: $e');
      if (mounted) {
        setState(() {
          _currentLocation = 'Your Location';
          _nearbyPlaces = [];
          _isLoadingLocation = false;
          _isLoadingPlaces = false;
        });
      }
    }
  }

  Future<void> _getNearbyTouristPlaces(String cityName) async {
    try {
      setState(() {
        _isLoadingPlaces = true;
      });

      print('🔍 Searching for tourist places in: $cityName');

      // Use TourismApiService to get places for the city
      final places = await TourismApiService.searchTouristPlaces(cityName);

      if (mounted) {
        setState(() {
          _nearbyPlaces =
              places.take(10).toList(); // Limit to 10 places for homepage
          _isLoadingPlaces = false;
        });
      }

      print(
          '✅ Found ${places.length} places for $cityName, showing ${_nearbyPlaces.length}');
    } catch (e) {
      print('❌ Error getting nearby places: $e');
      if (mounted) {
        setState(() {
          _nearbyPlaces = _getFallbackPlaces();
          _isLoadingPlaces = false;
        });
      }
    }
  }

  void _showAllNearbyPlaces() {
    // Navigate to a new page or show a modal with all places
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            final appTheme = themeProvider.currentAppTheme;
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: appTheme.surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(
                          'All Attractions in $_currentLocation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  // Places list
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: TourismApiService.searchTouristPlaces(
                          _currentLocation),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: appTheme.accentColor,
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error loading places',
                              style: TextStyle(color: Colors.white70),
                            ),
                          );
                        }

                        final allPlaces = snapshot.data ?? [];

                        if (allPlaces.isEmpty) {
                          return Center(
                            child: Text(
                              'No attractions found in $_currentLocation',
                              style: TextStyle(color: Colors.white70),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: allPlaces.length,
                          itemBuilder: (context, index) {
                            final place = allPlaces[index];
                            return Container(
                              margin: EdgeInsets.only(bottom: 12),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color:
                                          appTheme.accentColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.place,
                                      color: appTheme.accentColor,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          place['name'],
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        if (place['address'] != null)
                                          Text(
                                            place['address'],
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white70,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.star,
                                                color: Colors.amber, size: 16),
                                            SizedBox(width: 4),
                                            Text(
                                              place['rating'].toString(),
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14),
                                            ),
                                            SizedBox(width: 16),
                                            if (place['category'] != null)
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: appTheme.accentColor
                                                      .withOpacity(0.3),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  place['category'],
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _refreshLocation() async {
    await _initializeLocation();
  }

  List<Map<String, dynamic>> _getFallbackPlaces() {
    return [
      {
        'name': 'Popular Tourist Destination',
        'description': 'Must-visit local attraction with rich heritage',
        'address': 'Local Area, $_currentLocation',
        'lat': 20.5937,
        'lng': 78.9629,
        'rating': 4.3,
        'category': 'Tourist Attraction',
      },
      {
        'name': 'Historic Cultural Monument',
        'description': 'Ancient architecture and cultural significance',
        'address': 'Historic District, $_currentLocation',
        'lat': 20.5937,
        'lng': 78.9629,
        'rating': 4.5,
        'category': 'Historical Site',
      },
      {
        'name': 'Scenic Natural Wonder',
        'description': 'Beautiful landscapes and photography spots',
        'address': 'Natural Reserve, $_currentLocation',
        'lat': 20.5937,
        'lng': 78.9629,
        'rating': 4.4,
        'category': 'Natural Beauty',
      },
    ];
  }

  void _showPlaceDetails(Map<String, dynamic> place) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            final appTheme = themeProvider.currentAppTheme;
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: appTheme.surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Place image
                  Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(place['image'] ??
                            'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=800&h=600&fit=crop'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Place name
                  Text(
                    place['name'] ?? 'Unknown Place',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Place category
                  if (place['category'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: appTheme.accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: appTheme.accentColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        place['category'],
                        style: TextStyle(
                          fontSize: 14,
                          color: appTheme.accentColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Distance and rating info
                  Row(
                    children: [
                      if (place['distance'] != null) ...[
                        const Icon(Icons.location_on,
                            color: Colors.white70, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '${place['distance'].toStringAsFixed(1)} km from your location',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ] else if (place['address'] != null) ...[
                        const Icon(Icons.location_on,
                            color: Colors.white70, size: 18),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            place['address'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (place['rating'] != null) ...[
                        const Icon(Icons.star, color: Colors.yellow, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '${place['rating']}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  if (place['description'] != null)
                    Text(
                      place['description'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appTheme.accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<UserProvider, LocalizationProvider, ThemeProvider>(
      builder:
          (context, userProvider, localizationProvider, themeProvider, child) {
        final appTheme = themeProvider.currentAppTheme;

        return RefreshIndicator(
          onRefresh: _refreshLocation,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Personal Welcome Section with location-based message
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: const DecorationImage(
                      image: NetworkImage(
                          'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&h=400&fit=crop'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  margin: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Hello ${userProvider.userName}! 👋',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_isLoadingLocation)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLoadingLocation
                              ? localizationProvider.getLocalizedText('loading')
                              : _getLocalizedWelcomeMessage(
                                  localizationProvider,
                                  _currentLocation.split(',').first),
                          style: TextStyle(
                            fontSize: 18,
                            color: appTheme.textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Ready for your next adventure?',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // User Stats Card with location info
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userProvider.userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.white70,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _currentLocation,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Verification badge
                            if (userProvider.isEmailVerified) ...[
                              Row(
                                children: [
                                  const Icon(
                                    Icons.verified,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Verified Traveler',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Row(
                                children: [
                                  const Icon(
                                    Icons.warning_rounded,
                                    color: Colors.orange,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Email Not Verified',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ]
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: userProvider.isEmailVerified
                              ? appTheme.accentColor.withOpacity(0.2)
                              : Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: userProvider.isEmailVerified
                                ? appTheme.accentColor.withOpacity(0.5)
                                : Colors.orange.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          userProvider.isEmailVerified
                              ? 'Explorer'
                              : 'New User',
                          style: TextStyle(
                            color: userProvider.isEmailVerified
                                ? appTheme.accentColor
                                : Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Nearby Popular Destinations (Location-based)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Nearby Attractions',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Within 50km of $_currentLocation',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              if (_isLoadingPlaces)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white70,
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                GestureDetector(
                                  onTap: _refreshLocation,
                                  child: const Icon(
                                    Icons.refresh,
                                    color: Colors.white70,
                                    size: 20,
                                  ),
                                ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _showAllNearbyPlaces,
                                child: const Text(
                                  'See all',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 220,
                        child: _nearbyPlaces.isEmpty && !_isLoadingPlaces
                            ? const Center(
                                child: Text(
                                  'No nearby attractions found',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount:
                                    _isLoadingPlaces ? 3 : _nearbyPlaces.length,
                                itemBuilder: (context, index) {
                                  if (_isLoadingPlaces) {
                                    return _buildLoadingCard();
                                  }

                                  final place = _nearbyPlaces[index];
                                  return GestureDetector(
                                    onTap: () => _showPlaceDetails(place),
                                    child: Container(
                                      width: 160,
                                      margin: const EdgeInsets.only(right: 16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        image: DecorationImage(
                                          image: NetworkImage(place['image'] ??
                                              'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=800&h=600&fit=crop'),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.black.withOpacity(0.7),
                                              Colors.transparent,
                                            ],
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.center,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              place['name'],
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              place['description'] ??
                                                  place['address'] ??
                                                  'Tourist attraction',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white70,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (place['rating'] != null) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.star,
                                                    color: Colors.yellow,
                                                    size: 12,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    '${place['rating']}',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.white70,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  if (place['category'] !=
                                                      null) ...[
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 4,
                                                        vertical: 1,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white
                                                            .withOpacity(0.2),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
                                                      ),
                                                      child: Text(
                                                        place['category'],
                                                        style: const TextStyle(
                                                          fontSize: 8,
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Travel Tips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Travel Tips',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.lightbulb,
                                color: Colors.green,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pack Light, Travel Smart',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Always carry essentials and keep digital copies of important documents.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Rate Us Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: RateUsWidget(),
                ),

                const SizedBox(
                    height: 100), // Extra space for floating navigation
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

// Keep the existing RateUsWidget class unchanged
class RateUsWidget extends StatefulWidget {
  @override
  _RateUsWidgetState createState() => _RateUsWidgetState();
}

class _RateUsWidgetState extends State<RateUsWidget> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _showFeedback = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.star,
                      color: Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rate Your Experience, ${userProvider.userName.split(' ').first}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Help us improve by rating our app',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Star Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _rating = index + 1;
                        _showFeedback = _rating <= 3;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: index < _rating ? Colors.yellow : Colors.white70,
                        size: 32,
                      ),
                    ),
                  );
                }),
              ),
              if (_rating > 0) ...[
                const SizedBox(height: 16),
                Text(
                  _getRatingText(_rating),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (_showFeedback) ...[
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: TextField(
                    controller: _feedbackController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Tell us how we can improve...',
                      hintStyle: TextStyle(color: Colors.white60),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
              if (_rating > 0) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _submitRating(userProvider.userName);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                    ),
                    child: const Text(
                      'Submit Rating',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor - We\'ll work to improve!';
      case 2:
        return 'Fair - Help us get better!';
      case 3:
        return 'Good - Almost there!';
      case 4:
        return 'Very Good - Thank you!';
      case 5:
        return 'Excellent - You\'re awesome!';
      default:
        return '';
    }
  }

  void _submitRating(String userName) {
    String message = _rating >= 4
        ? 'Thank you ${userName.split(' ').first} for your ${_rating}-star rating! 🌟'
        : 'Thank you ${userName.split(' ').first} for your feedback. We\'ll work on improvements!';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _rating >= 4 ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );

    setState(() {
      _rating = 0;
      _showFeedback = false;
      _feedbackController.clear();
    });
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
}
