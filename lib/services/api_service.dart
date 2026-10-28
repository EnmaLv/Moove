import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_routes.dart';

class ApiService {

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> _parse(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {'statusCode': response.statusCode, ...data};
    } catch (_) {
      return {
        'statusCode': response.statusCode,
        'success': false,
        'message': 'Error al procesar la respuesta del servidor.',
      };
    }
  }

  static Map<String, dynamic> _connectionError(Object e) => {
    'statusCode': 0,
    'success': false,
    'message': 'Error de conexión. Verifica tu red.',
  };

  static Future<Map<String, dynamic>> login(
    String identifier,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$kBaseUrl/auth/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            // El backend sigue esperando el campo "email";
            // internamente valida si es correo o cédula.
            body: jsonEncode({'email': identifier, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('usuario', jsonEncode(data['usuario']));
        await prefs.setString('roles', jsonEncode(data['roles']));
        await prefs.setString('modulos', jsonEncode(data['modulos']));
      }

      return {'statusCode': response.statusCode, ...data};
    } catch (e) {
      return {
        'statusCode': 0,
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      try {
        await http
            .post(
              Uri.parse('$kBaseUrl/auth/logout'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
            )
            .timeout(const Duration(seconds: 10));
      } catch (_) {
      }
    }

    await prefs.remove('token');
    await prefs.remove('usuario');
    await prefs.remove('roles');
    await prefs.remove('modulos');
  }

  static Future<Map<String, dynamic>?> getSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final usuarioStr = prefs.getString('usuario');
      final rolesStr = prefs.getString('roles');
      if (token != null && usuarioStr != null && rolesStr != null) {
        return {
          'success': true,
          'usuario': jsonDecode(usuarioStr) as Map<String, dynamic>,
          'roles': jsonDecode(rolesStr) as List<dynamic>,
        };
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http
          .get(Uri.parse('$kBaseUrl$endpoint'), headers: await _headers())
          .timeout(const Duration(seconds: 15));
      return _parse(response);
    } catch (e) {
      return _connectionError(e);
    }
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$kBaseUrl$endpoint'),
            headers: await _headers(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return _parse(response);
    } catch (e) {
      return _connectionError(e);
    }
  }

  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('$kBaseUrl$endpoint'),
            headers: await _headers(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return _parse(response);
    } catch (e) {
      return _connectionError(e);
    }
  }

  static Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$kBaseUrl$endpoint'),
            headers: await _headers(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return _parse(response);
    } catch (e) {
      return _connectionError(e);
    }
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await http
          .delete(Uri.parse('$kBaseUrl$endpoint'), headers: await _headers())
          .timeout(const Duration(seconds: 15));
      return _parse(response);
    } catch (e) {
      return _connectionError(e);
    }
  }
}
