import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maharashtra_tyres/services/auth_service.dart';

class InventoryService {
  // Coalesce concurrent in-flight requests to avoid duplicate network calls
  static final Map<String, Future<List<Map<String, dynamic>>>> _inFlightInventory = {};

  static Future<String> _getBaseUrl() async {
    final clientId = await AuthService.getClientId();
    if (clientId == null) {
      throw Exception('No client ID found. User is not logged in.');
    }
    return 'https://business-management-ji66.onrender.com/inventory/client/$clientId/inventories';
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'accept': '*/*',
      'content-type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Fetch all inventory items
  static Future<List<Map<String, dynamic>>> fetchInventory() async {
    try {
      final url = await _getBaseUrl();
      if (_inFlightInventory.containsKey(url)) {
        return _inFlightInventory[url]!;
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

      _inFlightInventory[url] = fetchFuture;
      final result = await fetchFuture;
      _inFlightInventory.remove(url);
      return result;
    } catch (e) {
      return [];
    }
  }

  // Create inventory item
  static Future<bool> createInventoryItem({
    required String productName,
    String? company,
    String? size,
    String? quantity,
    String? date,
    required String status,
  }) async {
    try {
      final body = jsonEncode({
        'product_name': productName,
        'company': company?.trim().isEmpty == true ? null : company,
        'size': size?.trim().isEmpty == true ? null : size,
        'quantity': quantity?.trim().isEmpty == true ? null : quantity,
        'date': date?.trim().isEmpty == true ? null : date,
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

  // Update inventory item
  static Future<bool> updateInventoryItem({
    required String id,
    required String productName,
    String? company,
    String? size,
    String? quantity,
    String? date,
    required String status,
  }) async {
    try {
      final body = jsonEncode({
        'product_name': productName,
        'company': company?.trim().isEmpty == true ? null : company,
        'size': size?.trim().isEmpty == true ? null : size,
        'quantity': quantity?.trim().isEmpty == true ? null : quantity,
        'date': date?.trim().isEmpty == true ? null : date,
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

  // Delete inventory item
  static Future<bool> deleteInventoryItem(String id) async {
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
