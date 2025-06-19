import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:linkily/main.dart';

const String MASTER_URL = 'http://192.168.1.18:5000';

Future<String?> _getToken() async {
  try {
    var token = await secureStorage.read(key: "auth_token");
    return token;
  } catch (e) {
    print('Error reading token: $e');
    return null;
  }
}

Future<Map<String, String>> _getHeaders({Map<String, String>? additionalHeaders}) async {
  final token = await _getToken();
  final headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    ...?additionalHeaders,
  };
  
  if (token != null) {
    headers['Authorization'] = 'Bearer $token';
  }
  
  return headers;
}

dynamic _handleResponse(http.Response response) {
  final responseBody = utf8.decode(response.bodyBytes);
  final statusCode = response.statusCode;
  
  if (statusCode >= 200 && statusCode < 300) {
    if (responseBody.isEmpty) return null;
    return jsonDecode(responseBody);
  } else {
    throw HttpException(
      statusCode: statusCode,
      message: responseBody.isNotEmpty 
          ? jsonDecode(responseBody)['message'] ?? 'Request failed'
          : 'Request failed with status $statusCode',
    );
  }
}

// GET request
Future<dynamic> aget(String endpoint, {Map<String, String>? headers, Map<String, dynamic>? queryParams}) async {
  try {
    final uri = Uri.parse('$MASTER_URL$endpoint').replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: await _getHeaders(additionalHeaders: headers),
    );
    return _handleResponse(response);
  } catch (e) {
    throw _handleError(e);
  }
}

// POST request
Future<dynamic> apost(String endpoint, dynamic body, {Map<String, String>? headers}) async {
  try {
    final response = await http.post(
      Uri.parse('$MASTER_URL$endpoint'),
      headers: await _getHeaders(additionalHeaders: headers),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  } catch (e) {
    throw _handleError(e);
  }
}

// PUT request
Future<dynamic> aput(String endpoint, dynamic body, {Map<String, String>? headers}) async {
  try {
    final response = await http.put(
      Uri.parse('$MASTER_URL$endpoint'),
      headers: await _getHeaders(additionalHeaders: headers),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  } catch (e) {
    throw _handleError(e);
  }
}

// PATCH request
Future<dynamic> apatch(String endpoint, dynamic body, {Map<String, String>? headers}) async {
  try {
    final response = await http.patch(
      Uri.parse('$MASTER_URL$endpoint'),
      headers: await _getHeaders(additionalHeaders: headers),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  } catch (e) {
    throw _handleError(e);
  }
}

// DELETE request
Future<dynamic> adelete(String endpoint, {Map<String, String>? headers, dynamic body}) async {
  try {
    final response = await http.delete(
      Uri.parse('$MASTER_URL$endpoint'),
      headers: await _getHeaders(additionalHeaders: headers),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  } catch (e) {
    throw _handleError(e);
  }
}

// Error handling
dynamic _handleError(dynamic e) {
  if (e is http.ClientException) {
    throw HttpException(message: e.message, statusCode: 0);
  } else if (e is HttpException) {
    throw e;
  } else {
    throw HttpException(message: 'An unexpected error occurred', statusCode: 0);
  }
}

class HttpException implements Exception {
  final String message;
  final int statusCode;

  HttpException({required this.message, required this.statusCode});

  @override
  String toString() => 'HttpException: $message (Status code: $statusCode)';
}