import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'providers/theme_provider.dart';
import 'providers/localization_provider.dart';
import 'services/tourism_api_service.dart';
import 'main.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounceTimer;
  List<String> _recentSearches = [
    'Mumbai',
    'Goa',
    'Kerala',
    'Rajasthan',
    'Kashmir',
  ];

  void _searchPlaces(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Set new timer for debouncing (ultra-fast for better UX)
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Directly search tourist places using Gemini
      final places = await TourismApiService.searchTouristPlaces(query);

      // Remove duplicates and sort by rating
      final uniqueResults = <Map<String, dynamic>>[];
      final seenPlaces = <String>{};

      for (var place in places) {
        final placeKey = '${place['name']}-${place['lat']}-${place['lng']}';
        if (!seenPlaces.contains(placeKey)) {
          seenPlaces.add(placeKey);
          uniqueResults.add(place);
        }
      }

      // Sort by rating and limit results
      uniqueResults.sort(
          (a, b) => (b['rating'] as double).compareTo(a['rating'] as double));
      final limitedResults =
          uniqueResults.take(15).toList(); // Limit to 15 results

      setState(() {
        _searchResults = limitedResults;
        _isLoading = false;
      });

      print(
          'Search completed: Found ${limitedResults.length} results for "$query"');
    } catch (e) {
      print('Search error: $e');
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Search failed. Please check your internet connection.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openInGoogleMaps(Map<String, dynamic> place) async {
    final double lat = place['lat'];
    final double lng = place['lng'];
    final String placeName = place['name'];
    final String? address = place['address'];

    // Get search context from current search query
    final String searchContext = _searchController.text.trim();

    // Build comprehensive search query for Google Maps using place name
    // This is more accurate than coordinates as Google Maps has better place database
    String searchQuery = placeName;

    // Enhance search query with location context for better accuracy
    if (searchContext.isNotEmpty && searchContext.length < 50) {
      // If search context doesn't seem to be contained in place name, add it
      if (!placeName.toLowerCase().contains(searchContext.toLowerCase()) &&
          !searchContext.toLowerCase().contains(placeName.toLowerCase())) {
        searchQuery = '$placeName, $searchContext';
      }
    }

    // Add address if available for even better precision
    if (address != null && address.isNotEmpty && address.length < 100) {
      searchQuery = '$placeName, $address';
    }

    print('🗺️ Opening Google Maps with search query: "$searchQuery"');

    // Primary: Use place name search query (most accurate)
    final String primaryUrl =
        'https://www.google.com/maps/search/${Uri.encodeComponent(searchQuery)}';

    // Secondary: Use directions with place name
    final String directionsUrl =
        'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(searchQuery)}';

    // Fallback: Use coordinates only as last resort
    final String coordinateUrl = 'https://www.google.com/maps/search/$lat,$lng';

    try {
      // Try place name search first (most accurate)
      final Uri primaryUri = Uri.parse(primaryUrl);
      if (await canLaunchUrl(primaryUri)) {
        await launchUrl(primaryUri, mode: LaunchMode.externalApplication);
        print('✅ Opened Google Maps with place name search');
        return;
      }

      // Try directions with place name
      final Uri directionsUri = Uri.parse(directionsUrl);
      if (await canLaunchUrl(directionsUri)) {
        await launchUrl(directionsUri, mode: LaunchMode.externalApplication);
        print('✅ Opened Google Maps with place name directions');
        return;
      }

      // Last resort: Use coordinates
      final Uri fallbackUri = Uri.parse(coordinateUrl);
      if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        print('⚠️ Opened Google Maps with coordinates fallback');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening maps: $e')),
      );
    }
  }

  void _addToRecentSearches(String search) {
    setState(() {
      _recentSearches.remove(search);
      _recentSearches.insert(0, search);
      if (_recentSearches.length > 5) {
        _recentSearches = _recentSearches.take(5).toList();
      }
    });
  }

  Widget _buildSearchResult(Map<String, dynamic> place, AppTheme theme) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () {
          _openInGoogleMaps(place);
          _addToRecentSearches(place['name']);
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getCategoryIcon(place['category']),
                color: theme.accentColor,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text(
                        place['rating'].toString(),
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      SizedBox(width: 16),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.accentColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
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
            Icon(
              Icons.directions,
              color: theme.accentColor,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'beach':
        return Icons.beach_access;
      case 'monument':
        return Icons.account_balance;
      case 'heritage':
        return Icons.temple_hindu;
      case 'palace':
        return Icons.castle;
      case 'fort':
        return Icons.security;
      case 'hill station':
        return Icons.landscape;
      case 'waterfall':
        return Icons.water;
      case 'lake':
        return Icons.waves;
      case 'valley':
        return Icons.terrain;
      case 'waterfront':
        return Icons.water;
      case 'backwaters':
        return Icons.sailing;
      default:
        return Icons.place;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<UserProvider, ThemeProvider, LocalizationProvider>(
      builder:
          (context, userProvider, themeProvider, localizationProvider, child) {
        final theme = themeProvider.currentAppTheme;

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Header
                Text(
                  'Search Tourist Places',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 20),

                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: Colors.white),
                    onChanged: _searchPlaces,
                    decoration: InputDecoration(
                      hintText: 'Search cities like Mumbai, Goa, Kerala...',
                      hintStyle: TextStyle(color: Colors.white60),
                      prefixIcon: Icon(Icons.search, color: Colors.white70),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Search Results or Loading
                if (_isLoading)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(theme.accentColor),
                      ),
                    ),
                  )
                else if (_searchResults.isNotEmpty) ...[
                  Text(
                    'Search Results',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      return _buildSearchResult(_searchResults[index], theme);
                    },
                  ),
                ] else if (_searchController.text.isNotEmpty) ...[
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.white54,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No results found for "${_searchController.text}"',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Try searching for cities like Mumbai, Goa, Kerala, Rajasthan, or Kashmir',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Recent Searches
                  if (_recentSearches.isNotEmpty) ...[
                    Text(
                      'Recent Searches',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _recentSearches.map((search) {
                        return InkWell(
                          onTap: () {
                            _searchController.text = search;
                            _searchPlaces(search);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.history,
                                    color: Colors.white70, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  search,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 24),
                  ],

                  // Popular Destinations
                  Text(
                    'Popular Destinations in India',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 24),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio:
                          1.2, // Increased from 1.5 to prevent overflow
                    ),
                    itemCount:
                        TourismApiService.getAllIndianCities().length > 10
                            ? 10
                            : TourismApiService.getAllIndianCities().length,
                    itemBuilder: (context, index) {
                      final cities = TourismApiService.getAllIndianCities();
                      final city = cities[index];
                      return InkWell(
                        onTap: () {
                          _searchController.text = city['name'];
                          _searchPlaces(city['name']);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.all(12), // Reduced padding
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min, // Prevent overflow
                            children: [
                              Icon(
                                Icons.location_city,
                                color: theme.accentColor,
                                size: 28, // Slightly reduced icon size
                              ),
                              SizedBox(height: 6), // Reduced spacing
                              Flexible(
                                // Added Flexible to prevent overflow
                                child: Text(
                                  city['name'],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14, // Reduced font size
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1, // Limit to 1 line
                                  overflow:
                                      TextOverflow.ellipsis, // Handle overflow
                                ),
                              ),
                              SizedBox(height: 2), // Reduced spacing
                              Flexible(
                                // Added Flexible to prevent overflow
                                child: Text(
                                  city['state'],
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10, // Reduced font size
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1, // Limit to 1 line
                                  overflow:
                                      TextOverflow.ellipsis, // Handle overflow
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],

                SizedBox(height: 100), // Extra space for floating navigation
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
}
