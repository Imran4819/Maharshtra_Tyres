import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maharashtra_tyres/services/auth_service.dart';

class CustomerService {
  // Coalesce concurrent in-flight requests to avoid duplicate network calls
  static final Map<String, Future<List<Map<String, dynamic>>>> _inFlightCustomers = {};

  static Future<String> _getBaseUrl() async {
    final clientId = await AuthService.getClientId();
    if (clientId == null) {
      throw Exception('No client ID found. User is not logged in.');
    }
    return 'https://business-management-ji66.onrender.com/customer/client/$clientId/customers';
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'accept': '*/*',
      'content-type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Fetch all customers
  static Future<List<Map<String, dynamic>>> fetchCustomers() async {
    try {
      final url = await _getBaseUrl();
      if (_inFlightCustomers.containsKey(url)) {
        return _inFlightCustomers[url]!;
      }

      final fetchFuture = () async {
        try {
          final headers = await _getHeaders();
          final response = await http.get(Uri.parse(url), headers: headers);
          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = jsonDecode(response.body);
            if (data['success'] == true && data['data'] != null) {
              return List<Map<String, dynamic>>.from(data['data']);
            }
          }
          return <Map<String, dynamic>>[];
        } catch (_) {
          return <Map<String, dynamic>>[];
        }
      }();

      _inFlightCustomers[url] = fetchFuture;
      final result = await fetchFuture;
      _inFlightCustomers.remove(url);
      return result;
    } catch (e) {
      return [];
    }
  }

  // Create customer
  static Future<bool> createCustomer({
    required String name,
    String? email,
    String? phone,
    String? address,
    String? city,
    required String status,
  }) async {
    try {
      final body = jsonEncode({
        'name': name,
        'email': email?.trim().isEmpty == true ? null : email,
        'phone': phone?.trim().isEmpty == true ? null : phone,
        'address': address?.trim().isEmpty == true ? null : address,
        'city': city?.trim().isEmpty == true ? null : city,
        'status': status.toLowerCase(),
      });

      final url = await _getBaseUrl();
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // Update customer
  static Future<bool> updateCustomer({
    required String id,
    required String name,
    String? email,
    String? phone,
    String? address,
    String? city,
    required String status,
  }) async {
    try {
      final body = jsonEncode({
        'name': name,
        'email': email?.trim().isEmpty == true ? null : email,
        'phone': phone?.trim().isEmpty == true ? null : phone,
        'address': address?.trim().isEmpty == true ? null : address,
        'city': city?.trim().isEmpty == true ? null : city,
        'status': status.toLowerCase(),
      });

      final url = await _getBaseUrl();
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$url/$id'),
        headers: headers,
        body: body,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // Delete customer
  static Future<bool> deleteCustomer(String id) async {
    try {
      final url = await _getBaseUrl();
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$url/$id'),
        headers: headers,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}
