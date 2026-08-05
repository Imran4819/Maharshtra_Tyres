import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maharashtra_tyres/services/auth_service.dart';

class InvoiceService {
  // Coalesce concurrent in-flight requests to avoid duplicate network calls
  static final Map<String, Future<List<Map<String, dynamic>>>> _inFlightInvoices = {};
  static final Map<String, Future<List<Map<String, dynamic>>>> _inFlightReminders = {};

  static Future<String> _getBaseUrl() async {
    final clientId = await AuthService.getClientId();
    if (clientId == null) {
      throw Exception('No client ID found. User is not logged in.');
    }
    return 'https://business-management-ji66.onrender.com/invoice/client/$clientId/invoices';
  }

  static Future<String> _getClientBaseUrl() async {
    final clientId = await AuthService.getClientId();
    if (clientId == null) {
      throw Exception('No client ID found. User is not logged in.');
    }
    return 'https://business-management-ji66.onrender.com/invoice/client/$clientId';
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'accept': '*/*',
      'content-type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Fetch all invoices
  static Future<List<Map<String, dynamic>>> fetchInvoices() async {
    try {
      final url = await _getBaseUrl();
      if (_inFlightInvoices.containsKey(url)) {
        return _inFlightInvoices[url]!;
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

      _inFlightInvoices[url] = fetchFuture;
      final result = await fetchFuture;
      _inFlightInvoices.remove(url);
      return result;
    } catch (e) {
      return [];
    }
  }

  // Fetch next sequential invoice number (1, 2, 3, 4, 5...)
  static Future<String> fetchNextInvoiceNumber() async {
    try {
      final invoices = await fetchInvoices();
      int maxNum = 0;
      for (final inv in invoices) {
        final numStr = inv['invoice_number']?.toString().trim() ?? '';
        final directVal = int.tryParse(numStr);
        if (directVal != null && directVal > 0 && directVal < 10000) {
          if (directVal > maxNum) maxNum = directVal;
        } else {
          final digitsOnly = numStr.replaceAll(RegExp(r'\D'), '');
          if (digitsOnly.isNotEmpty) {
            final parsed = int.tryParse(digitsOnly) ?? 0;
            if (parsed > 0 && parsed < 10000 && parsed > maxNum) {
              maxNum = parsed;
            }
          }
        }
      }
      return (maxNum + 1).toString();
    } catch (_) {
      return '1';
    }
  }

  // Create invoice
  static Future<Map<String, dynamic>> createInvoice(Map<String, dynamic> payload) async {
    try {
      final url = await _getBaseUrl();
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(payload),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'message': data['message'] ?? 'Failed to create invoice.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Update invoice
  static Future<Map<String, dynamic>> updateInvoice(String id, Map<String, dynamic> payload) async {
    try {
      final url = await _getBaseUrl();
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$url/$id'),
        headers: headers,
        body: jsonEncode(payload),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'message': data['message'] ?? 'Failed to update invoice.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Delete invoice
  static Future<bool> deleteInvoice(String id) async {
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

  // Fetch Invoice PDF bytes
  static Future<List<int>?> fetchInvoicePdfBytes(String id, {String? lang}) async {
    try {
      final url = await _getBaseUrl();
      final headers = await _getHeaders();
      final queryParam = lang != null ? '?lang=$lang' : '';
      final response = await http.get(
        Uri.parse('$url/$id/pdf$queryParam'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Fetch Overdue Payment Reminders (>10 Days)
  static Future<List<Map<String, dynamic>>> fetchOverdueReminders({int days = 10}) async {
    try {
      final clientBaseUrl = await _getClientBaseUrl();
      final url = '$clientBaseUrl/overdue-reminders?days=$days';
      if (_inFlightReminders.containsKey(url)) {
        return _inFlightReminders[url]!;
      }

      final fetchFuture = () async {
        try {
          final headers = await _getHeaders();
          final response = await http.get(
            Uri.parse(url),
            headers: headers,
          );

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

      _inFlightReminders[url] = fetchFuture;
      final result = await fetchFuture;
      _inFlightReminders.remove(url);
      return result;
    } catch (e) {
      return [];
    }
  }

  // Send Payment Reminder (via SMS & Email)
  static Future<Map<String, dynamic>> sendPaymentReminder(String id, {String channel = 'all'}) async {
    try {
      final url = await _getBaseUrl();
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$url/$id/send-reminder'),
        headers: headers,
        body: jsonEncode({'channel': channel}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] == true,
          'message': data['data']?['message'] ?? 'Reminder sent successfully',
          'sent_channels': data['data']?['sent_channels'] ?? [],
        };
      }
      return {'success': false, 'message': 'Failed to send reminder. Code: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Error sending reminder: $e'};
    }
  }
}
