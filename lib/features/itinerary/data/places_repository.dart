import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../domain/place_suggestion.dart';

class PlacesApiException implements Exception {
  const PlacesApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Google Places API（Autocomplete / Place Details）のラッパー。
class PlacesRepository {
  PlacesRepository(this._client);

  final http.Client _client;

  String get _apiKey => dotenv.env['PLACES_API_KEY'] ?? '';

  Future<List<PlaceSuggestion>> autocomplete({
    required String input,
    required String sessionToken,
  }) async {
    if (input.trim().isEmpty) return const [];
    if (_apiKey.isEmpty) {
      throw const PlacesApiException('Places APIキーが設定されていません。');
    }

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      {
        'input': input,
        'key': _apiKey,
        'language': 'ja',
        'components': 'country:jp',
        'sessiontoken': sessionToken,
      },
    );

    final response = await _client.get(uri);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final status = body['status'] as String?;
    if (status != 'OK' && status != 'ZERO_RESULTS') {
      throw PlacesApiException(
        'スポット検索に失敗しました: ${body['error_message'] ?? status}',
      );
    }

    final predictions = body['predictions'] as List? ?? const [];
    return predictions
        .map((p) => PlaceSuggestion(
              placeId: p['place_id'] as String,
              description: p['description'] as String,
            ))
        .toList();
  }

  Future<PlaceDetails> getDetails({
    required String placeId,
    required String sessionToken,
  }) async {
    if (_apiKey.isEmpty) {
      throw const PlacesApiException('Places APIキーが設定されていません。');
    }

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      {
        'place_id': placeId,
        'key': _apiKey,
        'language': 'ja',
        'fields': 'name,formatted_address,opening_hours,geometry',
        'sessiontoken': sessionToken,
      },
    );

    final response = await _client.get(uri);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final status = body['status'] as String?;
    if (status != 'OK') {
      throw PlacesApiException(
        'スポット詳細の取得に失敗しました: ${body['error_message'] ?? status}',
      );
    }

    final result = body['result'] as Map<String, dynamic>;
    final openingHours = result['opening_hours'] as Map<String, dynamic>?;
    final weekdayText = (openingHours?['weekday_text'] as List?)
            ?.map((e) => e as String)
            .join('\n') ??
        '';

    final location =
        (result['geometry'] as Map<String, dynamic>?)?['location'] as Map<String, dynamic>?;

    return PlaceDetails(
      name: result['name'] as String? ?? '',
      address: result['formatted_address'] as String? ?? '',
      openingHoursText: weekdayText,
      latitude: (location?['lat'] as num?)?.toDouble(),
      longitude: (location?['lng'] as num?)?.toDouble(),
    );
  }
}
