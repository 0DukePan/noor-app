import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:noor_app/core/services/api_fetcher_service.dart';

/// Tests every API endpoint and fallback of ApiFetcherService against a
/// mocked http client — no network access.
void main() {
  ApiFetcherService build(MockClient client, {String? apiKey}) {
    final service = ApiFetcherService(client: client);
    if (apiKey != null) service.hadithApiKey = apiKey;
    return service;
  }

  http.Response json(Object body, {int status = 200}) {
    return http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  group('quran endpoints', () {
    test('fetchAllSurahs parses data list', () async {
      Uri? captured;
      final service = build(MockClient((request) async {
        captured = request.url;
        return json({
          'data': [
            {'number': 1, 'name': 'Al-Fatihah'},
          ],
        });
      }),);
      final surahs = await service.fetchAllSurahs();
      expect(captured?.path, '/v1/surah');
      expect(surahs, hasLength(1));
      expect(surahs.first['number'], 1);
    });

    test('fetchAllSurahs falls back to the backup endpoint on failure', () async {
      final urls = <String>[];
      final service = build(MockClient((request) async {
        urls.add(request.url.toString());
        if (urls.length == 1) throw ApiException('down', 'primary');
        return json([
          {'number': 1, 'name': 'Al-Fatihah'},
        ]);
      }),);
      final surahs = await service.fetchAllSurahs();
      expect(urls, hasLength(2));
      expect(urls[1], contains('chapters.json'));
      expect(surahs, hasLength(1));
    });

    test('fetchSurah returns the data map', () async {
      Uri? captured;
      final service = build(MockClient((request) async {
        captured = request.url;
        return json({
          'data': {
            'number': 1,
            'ayahs': <Object>[],
          },
        });
      }),);
      final surah = await service.fetchSurah(1);
      expect(captured?.path, '/v1/surah/1/quran-uthmani');
      expect(surah['number'], 1);
    });

    test('fetchEditions appends the type path segment', () async {
      Uri? captured;
      final service = build(MockClient((request) async {
        captured = request.url;
        return json({
          'data': <Object>[],
        });
      }),);
      final editions = await service.fetchEditions(type: 'tafsir');
      expect(captured?.path, '/v1/edition/type/tafsir');
      expect(editions, isEmpty);
    });

    test('fetchTafsir uses the ayah reference path', () async {
      Uri? captured;
      final service = build(MockClient((request) async {
        captured = request.url;
        return json({
          'data': {'text': 'بسم الله'},
        });
      }),);
      final tafsir = await service.fetchTafsir(surahNumber: 1, verseNumber: 2);
      expect(captured?.path, '/v1/ayah/1:2/ar.muyassar');
      expect(tafsir['text'], 'بسم الله');
    });

    test('fetchRecitationUrl extracts the audio URL', () async {
      Uri? captured;
      final service = build(MockClient((request) async {
        captured = request.url;
        return json({
          'data': {'audio': 'https://cdn.example.com/2-255.mp3'},
        });
      }),);
      final url = await service.fetchRecitationUrl(surahNumber: 2, verseNumber: 255);
      expect(captured?.path, '/v1/ayah/2:255/ar.alafasy');
      expect(url, 'https://cdn.example.com/2-255.mp3');
    });
  });

  group('hadith endpoints', () {
    test('fetchHadithCollections sends the API key header', () async {
      Map<String, String>? headers;
      final service = build(
        MockClient((request) async {
          headers = request.headers;
          return json({
            'data': <Object>[],
          });
        }),
        apiKey: 'test-key',
      );
      await service.fetchHadithCollections();
      expect(headers?['X-API-Key'], 'test-key');
    });

    test('fetchHadithsByCollection encodes page and limit', () async {
      Uri? captured;
      final service = build(MockClient((request) async {
        captured = request.url;
        return json({
          'data': <Object>[],
        });
      }),);
      final hadiths = await service.fetchHadithsByCollection(
        'bukhari',
        page: 2,
        limit: 25,
      );
      expect(captured?.queryParameters['collection'], 'bukhari');
      expect(captured?.queryParameters['page'], '2');
      expect(captured?.queryParameters['limit'], '25');
      expect(hadiths, isEmpty);
    });

    test('fetchHadithByUrn returns null when data is absent', () async {
      Uri? captured;
      final service = build(MockClient((request) async {
        captured = request.url;
        return json({'data': null});
      }),);
      expect(await service.fetchHadithByUrn('1'), isNull);
      expect(captured?.path, '/v1/hadiths/1');
    });
  });

  group('prayer endpoints', () {
    test('fetchPrayerTimes formats the date and coordinates', () async {
      Uri? captured;
      final service = build(MockClient((request) async {
        captured = request.url;
        return json({
          'data': {'timings': <String, String>{}},
        });
      }),);
      final timings = await service.fetchPrayerTimes(
        latitude: 21.4225,
        longitude: 39.8262,
        date: DateTime(2026, 3, 15),
      );
      expect(captured?.pathSegments[1], 'timings');
      expect(captured?.pathSegments[2], '15-3-2026');
      expect(captured?.queryParameters['latitude'], '21.4225');
      expect(captured?.queryParameters['longitude'], '39.8262');
      expect(captured?.queryParameters['method'], '4');
      expect(timings['timings'], isNotNull);
    });

    test('fetchMonthlyCalendar parses the list', () async {
      Uri? captured;
      final service = build(MockClient((request) async {
        captured = request.url;
        return json({
          'data': <Object>[],
        });
      }),);
      final calendar = await service.fetchMonthlyCalendar(
        latitude: 21.4,
        longitude: 39.8,
        year: 2026,
        month: 3,
      );
      expect(captured?.pathSegments[1], 'calendar');
      expect(captured?.pathSegments[2], '2026');
      expect(captured?.pathSegments[3], '3');
      expect(calendar, isEmpty);
    });

    test('fetchQiblaDirection returns the angle as double', () async {
      final service = build(MockClient((request) async {
        return json({
          'data': {'direction': 255.5},
        });
      }),);
      final direction = await service.fetchQiblaDirection(
        latitude: 21.4,
        longitude: 39.8,
      );
      expect(direction, closeTo(255.5, 0.001));
    });

    test('fetchCalculationMethods returns the map', () async {
      final service = build(MockClient((request) async {
        return json({
          'data': {'4': {'name': 'Umm al-Qura'}},
        });
      }),);
      final methods = await service.fetchCalculationMethods();
      expect(methods['4'], isNotNull);
    });
  });

  group('mosque finder', () {
    test('findNearbyMosques parses the masjids list', () async {
      Uri? captured;
      final service = build(MockClient((request) async {
        captured = request.url;
        return json({
          'masjids': [
            {'name': 'Masjid Al-Haram'},
          ],
        });
      }),);
      final mosques = await service.findNearbyMosques(
        latitude: 21.4,
        longitude: 39.8,
      );
      expect(captured?.queryParameters['radius'], '5000');
      expect(mosques, hasLength(1));
    });

    test('findNearbyMosques returns empty list on network failure', () async {
      final service = build(MockClient((request) async {
        throw Exception('network down');
      }),);
      final mosques = await service.findNearbyMosques(
        latitude: 21.4,
        longitude: 39.8,
      );
      expect(mosques, isEmpty);
    });
  });

  group('error handling', () {
    test('non-200 status throws ApiException with the URL', () async {
      final service = build(MockClient((request) async {
        return json({'error': 'not found'}, status: 404);
      }),);
      expect(
        service.fetchAllSurahs,
        throwsA(isA<ApiException>()),
      );
    });
  });
}
