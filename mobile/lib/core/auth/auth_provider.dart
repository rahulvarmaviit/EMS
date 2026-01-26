import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../../models/user.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _error;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  User _enforceAdminRules(User user) {
    const adminMobile = '7989498358';
    // Ensure Super Admin is always ADMIN
    if (user.mobileNumber == adminMobile) {
      return user.copyWith(role: 'ADMIN');
    }
    // Allow other users to be ADMIN if backend says so
    return user;
  }

  // Check if user is already logged in
  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final token = await _apiClient.getToken();
      if (token == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      // Load cached user data
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      if (userData != null) {
        _user = User.fromJson(jsonDecode(userData));
        _status = AuthStatus.authenticated;
      } else {
        // Fetch fresh user data
        await _fetchProfile();
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      await _apiClient.clearToken();
    }

    notifyListeners();
  }

  // Login with mobile number and password
  Future<bool> login(String mobileNumber, String password,
      {String? deviceName}) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/api/auth/login', {
        'mobile_number': mobileNumber,
        'password': password,
        'device_name': deviceName ?? 'Unknown Device',
      });

      if (response['success'] == true) {
        final data = response['data'];
        await _apiClient.setToken(data['token']);

        var user = User.fromJson(data['user']);
        user = _enforceAdminRules(user);
        _user = user;

        // Cache user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(user.toJson()));

        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }

      _error = response['error'] ?? 'Login failed';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _error = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection failed. Please check your internet.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // Fetch user profile
  Future<void> _fetchProfile() async {
    try {
      final response = await _apiClient.get('/api/auth/me');
      if (response['success'] == true) {
        var user = User.fromJson(response['data']['user']);
        user = _enforceAdminRules(user);
        _user = user;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(user.toJson()));

        _status = AuthStatus.authenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      await _apiClient.clearToken();
    }
  }

  // Signup for new employees
  Future<bool> signup({
    required String fullName,
    required String mobileNumber,
    required String password,
    String? deviceName,
  }) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/api/auth/signup', {
        'full_name': fullName,
        'mobile_number': mobileNumber,
        'password': password,
      });

      if (response['success'] == true) {
        // Validation: If new user tries to be admin via signup (not possible usually as role is backend assigned default)
        // Check enforce rules? Login will handle it.
        // Auto-login after signup
        // Note: Signup usually makes regular employees. "from this credentials only..."
        // If they sign up with the admin number, login() will catch it and make them admin. Correct.
        return await login(mobileNumber, password, deviceName: deviceName);
      }

      _error = response['error'] ?? 'Signup failed';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _error = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection failed. Please check your internet.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // Send OTP
  Future<void> sendOtp(String mobileNumber) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      // Mock API call for OTP - in production call real endpoint
      await Future.delayed(const Duration(seconds: 1));

      // Assume success for now
      _status = AuthStatus.unauthenticated; // Reset to allow entering OTP
      notifyListeners();
    } catch (e) {
      _error = 'Failed to send OTP';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  // Verify OTP
  Future<bool> verifyOtp(String mobileNumber, String otp) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      // Mock API call for OTP verification
      await Future.delayed(const Duration(seconds: 1));

      if (otp == '123456') {
        // Mock validation
        // Ideally this would return a token and user data like login
        return await login(mobileNumber, 'password'); // Mock login
      } else {
        throw Exception('Invalid OTP');
      }
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  // Update profile
  Future<bool> updateProfile({String? email}) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.put('/api/auth/profile', {
        'email': email,
      });

      if (response['success'] == true) {
        _user = User.fromJson(response['data']['user']);

        // Update cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'user_data', jsonEncode(response['data']['user']));

        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }

      _error = response['error'] ?? 'Failed to update profile';
    } catch (e) {
      _error = 'Failed to update profile';
    }

    _status = AuthStatus.authenticated;
    notifyListeners();
    return false;
  }

  // Logout
  Future<void> logout() async {
    await _apiClient.clearToken();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
