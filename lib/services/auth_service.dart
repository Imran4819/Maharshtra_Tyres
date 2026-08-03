import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maharashtra_tyres/services/web_storage_helper.dart';

class AuthService {
  static const String _baseUrl =
      'https://business-management-ji66.onrender.com';

  /// Returns null on success, or an error message string on failure.
  static Future<String?> login({
    required String identifier,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      final trimmed = identifier.trim();
      final digitsOnly = trimmed.replaceAll(RegExp(r'[^0-9]'), '');

      // Determine if identifier is a mobile number or email address
      final isPhone = RegExp(r'^\+?[0-9]{10,12}$').hasMatch(trimmed.replaceAll(' ', '')) &&
          (digitsOnly.length == 10 || (digitsOnly.length == 12 && digitsOnly.startsWith('91')));

      String phoneFormatted = '';
      if (isPhone) {
        if (digitsOnly.length == 10) {
          phoneFormatted = '+91$digitsOnly';
        } else if (digitsOnly.length == 12 && digitsOnly.startsWith('91')) {
          phoneFormatted = '+$digitsOnly';
        } else {
          phoneFormatted = trimmed;
        }
      }

      final Map<String, dynamic> body = {
        'password': password,
        if (isPhone)
          'phone': phoneFormatted
        else
          'email': trimmed.toLowerCase(),
      };

      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/login'),
            headers: {
              'accept': '*/*',
              'content-type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Extract token – handle various token key names
        final String? token = data['token'] ??
            data['accessToken'] ??
            data['access_token'] ??
            (data['data'] is Map ? data['data']['token'] : null) ??
            (data['data'] is Map ? data['data']['accessToken'] : null);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('logged_user_identifier', trimmed);
        if (data is Map && data['user'] is Map && data['user']['name'] != null) {
          await prefs.setString('logged_user_name', data['user']['name'].toString());
        }
        if (token != null) {
          await prefs.setString('auth_token', token);
          saveTokenToWebStorage(token);
          try {
            final payload = decodeJwt(token);
            final clientId = payload['client_id']?.toString();
            if (clientId != null) {
              await prefs.setString('client_id', clientId);
            }
          } catch (_) {}
        }
        if (rememberMe) {
          await prefs.setString('saved_identifier', trimmed);
        } else {
          await prefs.remove('saved_identifier');
        }
        return null; // success
      } else {
        // Try to extract a meaningful error message from the response
        String errorMsg = 'Invalid credentials. Please try again.';
        if (data is Map) {
          errorMsg = data['message'] ??
              data['error'] ??
              data['msg'] ??
              errorMsg;
        }
        return errorMsg;
      }
    } on http.ClientException {
      return 'Network error. Please check your internet connection.';
    } on TimeoutException {
      return 'Server response timed out. Please try again.';
    } catch (e) {
      return 'An error occurred. Please try again.';
    }
  }

  /// Clears stored session data on logout.
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_logged_in');
    await prefs.remove('auth_token');
    await prefs.remove('logged_user_identifier');
    await prefs.remove('logged_user_name');
    await prefs.remove('client_id');
    clearTokenFromWebStorage();
  }

  /// Returns the stored JWT token, or null if not logged in.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Returns the saved identifier (email/phone) for the "remember me" feature.
  static Future<String?> getSavedIdentifier() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('saved_identifier');
  }

  /// Returns user display name or fallback identifier
  static Future<String> getUserDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('logged_user_name');
    if (name != null && name.trim().isNotEmpty) return name;

    final identifier = prefs.getString('logged_user_identifier') ?? prefs.getString('saved_identifier');
    if (identifier != null && identifier.trim().isNotEmpty) {
      final trimmed = identifier.trim();
      if (trimmed.contains('@')) {
        final prefix = trimmed.split('@').first;
        if (prefix.isNotEmpty) {
          return prefix[0].toUpperCase() + prefix.substring(1);
        }
      }
      return trimmed;
    }
    return 'Admin';
  }

  /// Returns user initials (e.g. "AD" or "IM")
  static Future<String> getUserInitials() async {
    final displayName = await getUserDisplayName();
    if (displayName.trim().isEmpty) return 'AD';
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return displayName.substring(0, displayName.length.clamp(1, 2)).toUpperCase();
  }

  /// Decodes JWT token payload to retrieve claims.
  static Map<String, dynamic> decodeJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid token');
    }
    final payload = parts[1];
    var normalized = base64Url.normalize(payload);
    final resp = utf8.decode(base64Url.decode(normalized));
    return jsonDecode(resp) as Map<String, dynamic>;
  }

  /// Returns the dynamically stored client_id, fallback to null.
  static Future<String?> getClientId() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedClientId = prefs.getString('client_id');
    if (cachedClientId != null) return cachedClientId;

    final token = await getToken();
    if (token != null) {
      try {
        final payloadMap = decodeJwt(token);
        final clientId = payloadMap['client_id']?.toString();
        if (clientId != null) {
          await prefs.setString('client_id', clientId);
          return clientId;
        }
      } catch (_) {}
    }
    return null;
  }
}
