import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:maharashtra_tyres/services/auth_service.dart';

class BillService {
  static const String _apiRoot =
      'https://business-management-ji66.onrender.com/tyre-bills/client';

  static Future<String> _billsUrl() async {
    final clientId = await AuthService.getClientId();
    if (clientId == null || clientId.isEmpty) {
      throw Exception(
        'Your account is missing a client ID. Please sign in again.',
      );
    }
    return '$_apiRoot/$clientId/bills';
  }

  static Future<Map<String, String>> _headers({bool json = false}) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Your session has expired. Please sign in again.');
    }
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  static Future<List<Map<String, dynamic>>> fetchBills() async {
    final response = await http
        .get(Uri.parse(await _billsUrl()), headers: await _headers())
        .timeout(const Duration(seconds: 30));
    _ensureSuccess(response);
    return _extractList(_decode(response.body));
  }

  static Future<Map<String, dynamic>> fetchBillById(String id) async {
    final response = await http
        .get(
          Uri.parse('${await _billsUrl()}/${Uri.encodeComponent(id)}'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 30));
    _ensureSuccess(response);
    return _extractBill(_decode(response.body));
  }

  static Future<void> uploadBillPhoto({
    required List<int> photoBytes,
    required String fileName,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(await _billsUrl()));
    request.headers.addAll(await _headers());
    request.files.add(
      http.MultipartFile.fromBytes('image', photoBytes, filename: fileName),
    );
    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 60),
    );
    final response = await http.Response.fromStream(streamedResponse);
    _ensureSuccess(response);
  }

  static Future<void> createBill(Map<String, dynamic> bill) async {
    final response = await http
        .post(
          Uri.parse(await _billsUrl()),
          headers: await _headers(json: true),
          body: jsonEncode(bill),
        )
        .timeout(const Duration(seconds: 30));
    _ensureSuccess(response);
  }

  static Future<void> updateBill(String id, Map<String, dynamic> bill) async {
    final response = await http
        .put(
          Uri.parse('${await _billsUrl()}/${Uri.encodeComponent(id)}'),
          headers: await _headers(json: true),
          body: jsonEncode(bill),
        )
        .timeout(const Duration(seconds: 30));
    _ensureSuccess(response);
  }

  static dynamic _decode(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  static List<Map<String, dynamic>> _extractList(dynamic payload) {
    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((bill) => _normalizeBill(Map<String, dynamic>.from(bill)))
          .toList();
    }
    if (payload is Map) {
      for (final key in ['data', 'bills', 'results']) {
        final value = payload[key];
        if (value is List) return _extractList(value);
        if (value is Map) {
          final nested = _extractList(value);
          if (nested.isNotEmpty) return nested;
        }
      }
    }
    return [];
  }

  static Map<String, dynamic> _extractBill(dynamic payload) {
    if (payload is Map) {
      for (final key in ['data', 'bill', 'result']) {
        final value = payload[key];
        if (value is Map) {
          return _extractBill(value);
        }
      }
      return _normalizeBill(Map<String, dynamic>.from(payload));
    }
    throw Exception('The server returned an invalid bill response.');
  }

  static Map<String, dynamic> _normalizeBill(Map<String, dynamic> bill) {
    bill['id'] ??= bill['_id'] ?? bill['bill_id'];
    bill['store_name'] ??= bill['shop_name'] ?? bill['supplier_name'];
    bill['date'] ??= bill['bill_date'] ?? bill['created_at'];
    bill['image_url'] ??=
        bill['image'] ??
        bill['photo_url'] ??
        bill['photo'] ??
        bill['bill_photo'] ??
        bill['bill_photo_url'] ??
        bill['bill_image_url'] ??
        bill['bill_image'] ??
        bill['image_path'];

    final items = bill['items'];
    if (bill['quantity'] == null && items is List) {
      bill['quantity'] = items.fold<int>(
        0,
        (sum, item) =>
            sum +
            (item is Map
                ? int.tryParse(item['quantity']?.toString() ?? '') ?? 0
                : 0),
      );
    }
    return bill;
  }

  static void _ensureSuccess(http.Response response) {
    final payload = _decode(response.body);
    final isHttpSuccess =
        response.statusCode >= 200 && response.statusCode < 300;
    if (isHttpSuccess && !(payload is Map && payload['success'] == false)) {
      return;
    }
    if (payload is Map) {
      final message =
          payload['message'] ?? payload['error'] ?? payload['detail'];
      if (message != null && message.toString().trim().isNotEmpty) {
        throw Exception(message.toString());
      }
    }
    throw Exception(
      'Request failed (${response.statusCode}). Please try again.',
    );
  }
}
