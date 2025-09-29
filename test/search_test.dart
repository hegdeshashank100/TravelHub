import 'package:flutter_test/flutter_test.dart';
import '../lib/services/tourism_api_service.dart';

void main() {
  test('Test search functionality', () async {
    // Test fallback search
    final results = await TourismApiService.searchTouristPlaces('mumbai');
    print('Search results for "mumbai": ${results.length}');
    for (var result in results) {
      print('- ${result['name']} (${result['category']})');
    }

    expect(results.length, greaterThan(0));
  });

  test('Test city search', () {
    final cities = TourismApiService.searchCities('mumbai');
    print('City search results for "mumbai": ${cities.length}');
    for (var city in cities) {
      print('- ${city['name']}, ${city['state']}');
    }

    expect(cities.length, greaterThan(0));
  });

  test('Test comprehensive search', () async {
    final results =
        await TourismApiService.getComprehensiveSearchResults('mumbai');
    print('Comprehensive search results for "mumbai":');
    print('Cities: ${results['cities']?.length ?? 0}');
    print('Places: ${results['places']?.length ?? 0}');
    print('Categories: ${results['categories']?.length ?? 0}');

    expect(results['cities'], isNotNull);
    expect(results['places'], isNotNull);
  });
}
