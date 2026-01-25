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
  Future<bool> login(String mobileNumber, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiClient.post('/api/auth/login', {
        'mobile_number': mobileNumber,
        'password': password,
      });
      
      if (response['success'] == true) {
        final data = response['data'];
        await _apiClient.setToken(data['token']);
        
        _user = User.fromJson(data['user']);
        
        // Cache user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(data['user']));
        
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
        _user = User.fromJson(response['data']['user']);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(response['data']['user']));
        
        _status = AuthStatus.authenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      await _apiClient.clearToken();
    }
  }
  
  // Logout
  Future<void> logout() async {
    await _apiClient.clearToken();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
