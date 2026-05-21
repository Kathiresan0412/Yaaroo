import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'secure_storage.dart';
import '../main.dart' show User, DiscoveryProfile, SwipeResult, SwipeAction, ExploreCategory, VibeQuestion, MatchItem, LikeItem;

class ApiClient {
  ApiClient(String baseUrl) : baseUri = Uri.parse(baseUrl);

  final Uri baseUri;
  String? accessToken;
  User? user;
  String? cookies;

  final SecureStorage _secureStorage = SecureStorage.instance;

  Future<void> init() async {
    accessToken = await _secureStorage.readAccessToken();
    cookies = await _secureStorage.readCookies();
    user = await _secureStorage.readUser();
  }

  Uri _uri(String path) {
    if (path.startsWith('http')) {
      return Uri.parse(path);
    }
    return baseUri.replace(path: path);
  }

  Map<String, String> _headers([Map<String, String>? headers]) {
    return {
      'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      if (cookies != null) 'Cookie': cookies!,
      ...?headers,
    };
  }

  void _extractCookies(http.Response response) {
    final setCookie = response.headers['set-cookie'] ?? response.headers['Set-Cookie'];
    if (setCookie != null && setCookie.isNotEmpty) {
      cookies = setCookie;
      _secureStorage.writeCookies(setCookie);
    }
  }

  Future<Map<String, dynamic>> _decode(http.Response response) async {
    final body = response.body.isEmpty ? '{}' : response.body;
    final parsed = jsonDecode(body);

    if (parsed is! Map<String, dynamic>) {
      throw ApiException('Yaaro0 returned an unexpected response.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(parsed['message']?.toString() ?? 'Request failed.');
    }

    return parsed;
  }

  Future<http.Response> _request(
    String method,
    String path, {
    Object? body,
    Map<String, String>? headers,
    bool isRetry = false,
  }) async {
    final url = _uri(path);
    final allHeaders = _headers(headers);

    http.Response response;
    final encodedBody = body != null ? jsonEncode(body) : null;

    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(url, headers: allHeaders);
        break;
      case 'POST':
        response = await http.post(url, headers: allHeaders, body: encodedBody);
        break;
      case 'PUT':
        response = await http.put(url, headers: allHeaders, body: encodedBody);
        break;
      case 'DELETE':
        response = await http.delete(url, headers: allHeaders, body: encodedBody);
        break;
      case 'PATCH':
        response = await http.patch(url, headers: allHeaders, body: encodedBody);
        break;
      default:
        throw ApiException('Unsupported HTTP method: $method');
    }

    _extractCookies(response);

    // Trap 401 or 403 to trigger auto-refresh
    if ((response.statusCode == 401 || response.statusCode == 403) && !isRetry) {
      final refreshed = await refreshSession();
      if (refreshed) {
        return _request(method, path, body: body, headers: headers, isRetry: true);
      } else {
        logout();
        throw ApiException('Your session has expired. Please log in again.');
      }
    }

    return response;
  }

  Future<bool> refreshSession() async {
    try {
      final url = _uri('/api/auth/refresh');
      final response = await http.post(
        url,
        headers: _headers(),
        body: '{}',
      );
      _extractCookies(response);

      if (response.statusCode == 200) {
        final payload = jsonDecode(response.body);
        if (payload is Map<String, dynamic>) {
          accessToken = payload['accessToken']?.toString();
          if (accessToken != null) {
            await _secureStorage.writeAccessToken(accessToken!);
          }
          final rawUser = payload['user'];
          if (rawUser is Map<String, dynamic>) {
            user = User.fromJson(rawUser);
            await _secureStorage.writeUser(user!);
          }
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  Future<void> login(String email, String password) async {
    final response = await http.post(
      _uri('/api/auth/login'),
      headers: _headers(),
      body: jsonEncode({
        'email': email,
        'password': password,
        'remember': true,
      }),
    );
    _extractCookies(response);
    final payload = await _decode(response);
    accessToken = payload['accessToken']?.toString();
    if (accessToken != null) {
      await _secureStorage.writeAccessToken(accessToken!);
    }
    final rawUser = payload['user'];
    if (rawUser is Map<String, dynamic>) {
      user = User.fromJson(rawUser);
      await _secureStorage.writeUser(user!);
    }
  }

  Future<void> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String dateOfBirth,
    required String gender,
  }) async {
    final response = await http.post(
      _uri('/api/auth/register'),
      headers: _headers(),
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
      }),
    );
    _extractCookies(response);
    // Note: Registration returns { success: true, message: "Verification email sent..." }
    await _decode(response);
  }

  Future<void> verifyEmail(String token) async {
    final response = await _request('GET', '/api/auth/verify-email/${Uri.encodeComponent(token)}');
    await _decode(response);
  }

  Future<void> forgotPassword(String email) async {
    final response = await _request('POST', '/api/auth/forgot-password', body: {'email': email});
    await _decode(response);
  }

  Future<void> resetPassword(String token, String password) async {
    final response = await _request('POST', '/api/auth/reset-password', body: {
      'token': token,
      'password': password,
    });
    await _decode(response);
  }

  Future<void> logout() async {
    try {
      await http.post(_uri('/api/auth/logout'), headers: _headers(), body: '{}');
    } catch (_) {}
    accessToken = null;
    cookies = null;
    user = null;
    await _secureStorage.clearAll();
  }

  // --- Swipes & Discover ---

  Future<List<DiscoveryProfile>> discover() async {
    final response = await _request('GET', '/api/discover');
    final payload = await _decode(response);
    return _profilesFromPayload(payload);
  }

  Future<SwipeResult> swipe(String targetUserId, SwipeAction action) async {
    final response = await _request(
      'POST',
      '/api/swipe',
      body: {
        'target_user_id': targetUserId,
        'action': action.name,
      },
    );
    final payload = await _decode(response);
    return SwipeResult.fromJson(payload);
  }

  Future<void> undoSwipe() async {
    final response = await _request('POST', '/api/swipe/undo', body: {});
    await _decode(response);
  }

  // --- Explore ---

  Future<List<ExploreCategory>> categories() async {
    final response = await _request('GET', '/api/explore/categories');
    final payload = await _decode(response);
    final categories = payload['categories'];
    if (categories is List) {
      return categories
          .whereType<Map<String, dynamic>>()
          .map(ExploreCategory.fromJson)
          .toList();
    }
    return [];
  }

  Future<List<DiscoveryProfile>> exploreNearby() async {
    final response = await _request('GET', '/api/explore/nearby');
    final payload = await _decode(response);
    return _profilesFromPayload(payload);
  }

  Future<List<DiscoveryProfile>> exploreByGoal(String goal) async {
    final response = await _request('GET', '/api/explore/by-goal/${Uri.encodeComponent(goal)}');
    return _profilesFromPayload(await _decode(response));
  }

  Future<List<DiscoveryProfile>> exploreByInterest(String key) async {
    final response = await _request('GET', '/api/explore/by-interest/${Uri.encodeComponent(key)}');
    return _profilesFromPayload(await _decode(response));
  }

  Future<VibeQuestion?> vibeToday() async {
    final response = await _request('GET', '/api/explore/vibes/today');
    final payload = await _decode(response);
    final question = payload['question'];
    return question is Map<String, dynamic>
        ? VibeQuestion.fromJson(question, payload['answer']?.toString())
        : null;
  }

  Future<List<DiscoveryProfile>> respondToVibe(String answer) async {
    final response = await _request('POST', '/api/explore/vibes/respond', body: {'answer': answer});
    return _profilesFromPayload(await _decode(response));
  }

  // --- Matches ---

  Future<List<MatchItem>> matches() async {
    final response = await _request('GET', '/api/matches');
    final payload = await _decode(response);
    final matches = payload['matches'];
    if (matches is List) {
      return matches
          .whereType<Map<String, dynamic>>()
          .map(MatchItem.fromJson)
          .toList();
    }
    return [];
  }

  Future<List<LikeItem>> likesReceived() async {
    final response = await _request('GET', '/api/likes/received');
    final payload = await _decode(response);
    final likes = payload['likes'];
    if (likes is List) {
      return likes
          .whereType<Map<String, dynamic>>()
          .map(LikeItem.fromJson)
          .toList();
    }
    return [];
  }

  // --- Onboarding & Profile ---

  Future<Map<String, dynamic>> getProfileMe() async {
    final response = await _request('GET', '/api/profile/me');
    return await _decode(response);
  }

  Future<void> updateProfileMe(Map<String, dynamic> profileData) async {
    final response = await _request('PUT', '/api/profile/me', body: profileData);
    await _decode(response);
  }

  Future<Map<String, dynamic>> getProfileCompleteness() async {
    final response = await _request('GET', '/api/profile/completeness');
    return await _decode(response);
  }

  Future<List<dynamic>> getProfilePhotos() async {
    final response = await _request('GET', '/api/profile/photos');
    final payload = await _decode(response);
    return payload['photos'] is List ? payload['photos'] as List : [];
  }

  Future<void> uploadPhoto(String base64DataUrl) async {
    final response = await _request('POST', '/api/profile/photos', body: {'photo': base64DataUrl});
    await _decode(response);
  }

  Future<void> deletePhoto(String id) async {
    final response = await _request('DELETE', '/api/profile/photos/$id');
    await _decode(response);
  }

  Future<void> reorderPhotos(List<String> photoIds) async {
    final response = await _request('PUT', '/api/profile/photos/reorder', body: {'photoIds': photoIds});
    await _decode(response);
  }

  Future<void> updateLocation(double lat, double lng, String city, String country) async {
    final response = await _request('PUT', '/api/profile/location', body: {
      'latitude': lat,
      'longitude': lng,
      'city': city,
      'country': country,
    });
    await _decode(response);
  }

  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    final response = await _request('PUT', '/api/profile/preferences', body: preferences);
    await _decode(response);
  }

  Future<void> onboardingComplete() async {
    final response = await _request('PATCH', '/api/profile/onboarding/complete', body: {});
    await _decode(response);
  }

  // --- Messages ---

  Future<Map<String, dynamic>> getMessages(String matchId, {String? cursor}) async {
    final path = cursor != null
        ? '/api/messages/$matchId?limit=30&cursor=${Uri.encodeComponent(cursor)}'
        : '/api/messages/$matchId?limit=30';
    final response = await _request('GET', path);
    return await _decode(response);
  }

  Future<Map<String, dynamic>> sendMessage(String matchId, String content, String type, {String? mediaUrl}) async {
    final response = await _request('POST', '/api/messages/$matchId', body: {
      'content': content,
      'type': type,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
    });
    return await _decode(response);
  }

  Future<Map<String, dynamic>> sendVoiceMessage(String matchId, List<int> bytes) async {
    final url = _uri('/api/messages/$matchId/voice');
    final request = http.MultipartRequest('POST', url);
    request.headers.addAll(_headers());
    request.files.add(
      http.MultipartFile.fromBytes(
        'voice',
        bytes,
        filename: 'voice.webm',
        contentType: MediaType('audio', 'webm'),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    _extractCookies(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final parsed = jsonDecode(response.body);
      throw ApiException(parsed['message']?.toString() ?? 'Failed to upload voice message.');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> deleteMessage(String messageId) async {
    final response = await _request('DELETE', '/api/message-actions/$messageId');
    await _decode(response);
  }

  Future<void> reactToMessage(String messageId, String emoji) async {
    final response = await _request('POST', '/api/messages/$messageId/react', body: {'emoji': emoji});
    await _decode(response);
  }

  Future<void> markMessageRead(String messageId) async {
    final response = await _request('POST', '/api/messages/$messageId/read', body: {});
    await _decode(response);
  }

  Future<void> reportMessage(String messageId) async {
    final response = await _request('POST', '/api/messages/$messageId/report', body: {
      'reason': 'chat_report',
    });
    await _decode(response);
  }

  // --- Safety & Verification ---

  Future<Map<String, dynamic>> getVerificationStatus() async {
    final response = await _request('GET', '/api/verification/status');
    return await _decode(response);
  }

  Future<void> photoVerify(String base64DataUrl) async {
    final response = await _request('POST', '/api/verification/photo', body: {'photo': base64DataUrl});
    await _decode(response);
  }

  Future<void> idVerify(String base64DataUrl) async {
    final response = await _request('POST', '/api/verification/id', body: {'idPhoto': base64DataUrl});
    await _decode(response);
  }

  Future<void> reportUser(String targetUserId, String reason, String details) async {
    final response = await _request('POST', '/api/reports', body: {
      'targetUserId': targetUserId,
      'reason': reason,
      'details': details,
    });
    await _decode(response);
  }

  Future<void> blockUser(String userId) async {
    final response = await _request('POST', '/api/users/block/$userId', body: {});
    await _decode(response);
  }

  Future<void> unblockUser(String userId) async {
    final response = await _request('DELETE', '/api/users/block/$userId', body: {});
    await _decode(response);
  }

  Future<void> unmatch(String matchId) async {
    final response = await _request('POST', '/api/users/unmatch/$matchId', body: {});
    await _decode(response);
  }

  List<DiscoveryProfile> _profilesFromPayload(Map<String, dynamic> payload) {
    final rawCards = payload['cards'] ?? payload['profiles'] ?? payload['data'];
    if (rawCards is List) {
      return rawCards
          .whereType<Map<String, dynamic>>()
          .map(DiscoveryProfile.fromJson)
          .toList();
    }
    return [];
  }
}

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
