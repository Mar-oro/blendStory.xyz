import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class BlendAuthService {
  BlendAuthService._();
  static final instance = BlendAuthService._();

  String? _token;
  String? _username;

  String? get token    => _token;
  String? get username => _username;
  bool   get loggedIn  => _token != null;

  Future<bool> healthCheck() async {
    try {
      final r = await http
          .get(Uri.parse('${AppConfig.authBase}/auth/health'))
          .timeout(const Duration(seconds: 5));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> login(String username, String password) async {
    final r1 = await http.post(
      Uri.parse('${AppConfig.authBase}/auth/authorize'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'client_id': AppConfig.clientId,
        'scope': AppConfig.scope,
      }),
    ).timeout(const Duration(seconds: 10));

    if (r1.statusCode != 200) {
      final b = jsonDecode(r1.body);
      throw Exception(b['detail'] ?? b['error'] ?? 'Auth failed');
    }
    final d1   = jsonDecode(r1.body) as Map<String, dynamic>;
    final code = d1['code'] ?? d1['authorization_code'];
    if (code == null) throw Exception('No authorization code received');

    final r2 = await http.post(
      Uri.parse('${AppConfig.authBase}/auth/token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'grant_type': 'authorization_code',
        'code': code,
        'client_id': AppConfig.clientId,
        'client_secret': password,
      }),
    ).timeout(const Duration(seconds: 10));

    if (r2.statusCode != 200) {
      final b = jsonDecode(r2.body);
      throw Exception(b['detail'] ?? b['error'] ?? 'Token exchange failed');
    }
    final d2 = jsonDecode(r2.body) as Map<String, dynamic>;
    _token    = d2['access_token'];
    _username = username;
    if (_token == null) throw Exception('No access token in response');
  }

  void logout() {
    _token    = null;
    _username = null;
  }
}
