import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AllInOneService {
  // Ganti URL dengan endpoint API Anda
  static const String baseUrl = 'http://192.168.1.40:8000/api';

  // Instance untuk menyimpan token
  final _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Simpan token ke secure storage
        await _storage.write(key: 'access_token', value: data['access_token']);

        return {'success': true, 'message': 'Login berhasil'};
      } else if (response.statusCode == 401) {
        return {'success': false, 'message': 'Email atau password salah'};
      } else {
        return {'success': false, 'message': 'Login gagal. Coba lagi.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<void> logout() async {
    final token = await _storage.read(key: 'access_token'); // Ambil token dari storage

    if (token != null) {
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Hapus token di storage jika logout berhasil
        await _storage.delete(key: 'access_token');
      } else {
        throw Exception('Failed to logout');
      }
    }
  }

  Future<Map<String, dynamic>> getAttendanceHistory() async {
    final token = await getToken(); // Mendapatkan token dari secure storage

    if (token == null) {
      return {'success': false, 'message': 'Token tidak ditemukan'};
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else if (response.statusCode == 404) {
        return {'success': false, 'message': 'Data absensi tidak ditemukan'};
      } else {
        return {'success': false, 'message': 'Gagal mengambil data absensi'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  Future<Map<String, dynamic>> getRekapByLoggedInUser(String token) async {
    final url = Uri.parse('$baseUrl/rekap-absensi');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'data': data['data'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'],
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch attendance recap. Status code: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred while fetching attendance recap',
        'error': e.toString(),
      };
    }
  }

  Future<String> sendFaceData(Map<String, dynamic> faceData) async {
    final url = Uri.parse('$baseUrl/face-recognition');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(faceData),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['message'] ?? 'Face recognized successfully';
      } else {
        return 'Face not recognized.';
      }
    } catch (e) {
      print('Error sending face data: $e');
      return 'Failed to send face data.';
    }
  }

  Future<Map<String, dynamic>> fetchKaryawanData() async {
    final url = Uri.parse("$baseUrl/karyawan");
    final token = await getToken();

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)['data'];
      } else {
        throw Exception("Gagal memuat data karyawan. Status: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }
}