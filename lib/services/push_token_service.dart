import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:maharashtra_tyres/services/auth_service.dart';

class PushTokenService {
  PushTokenService._();

  static const String _tokenUrl =
      'https://business-management-ji66.onrender.com/notifications/token';

  static Future<void> registerToken(String token) async {
    final authToken = await AuthService.getToken();
    if (authToken == null || authToken.isEmpty) {
      throw Exception('Sign in before registering push notifications.');
    }

    final clientId = await AuthService.getClientId();
    if (clientId == null || clientId.isEmpty) {
      throw Exception('Your account is missing a client ID.');
    }

    final response = await http
        .post(
          Uri.parse(_tokenUrl),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'client_id': clientId,
            'token': token,
            'device_info': 'Flutter/${_platformName()}',
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Push token registration failed (${response.statusCode}).',
      );
    }
  }

  static String _platformName() {
    if (kIsWeb) return 'Web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android',
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.macOS => 'macOS',
      TargetPlatform.windows => 'Windows',
      TargetPlatform.linux => 'Linux',
      TargetPlatform.fuchsia => 'Fuchsia',
    };
  }
}
