import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../models/attendance.dart';

class AttendanceProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  List<Attendance> _history = [];
  Attendance? _todayAttendance;
  bool _isLoading = false;
  String? _error;
  
  List<Attendance> get history => _history;
  Attendance? get todayAttendance => _todayAttendance;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  bool get isCheckedIn => _todayAttendance != null;
  bool get isCheckedOut => _todayAttendance?.isCheckedOut ?? false;
  
  // Fetch attendance history
  Future<void> fetchHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiClient.get('/api/attendance/self');
      if (response['success'] == true) {
        final data = response['data'];
        _history = (data['attendance'] as List)
            .map((json) => Attendance.fromJson(json))
            .toList();
        
        // Find today's attendance
        final today = DateTime.now().toIso8601String().split('T')[0];
        _todayAttendance = _history.firstWhere(
          (a) => a.date == today,
          orElse: () => null as Attendance,
        );
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to fetch attendance history';
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Check in with GPS coordinates
  Future<bool> checkIn(double latitude, double longitude) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiClient.post('/api/attendance/check-in', {
        'latitude': latitude,
        'longitude': longitude,
      });
      
      if (response['success'] == true) {
        await fetchHistory();
        return true;
      }
      
      _error = response['error'];
      _isLoading = false;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Check-in failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Check out with GPS coordinates
  Future<bool> checkOut(double latitude, double longitude) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiClient.post('/api/attendance/check-out', {
        'latitude': latitude,
        'longitude': longitude,
      });
      
      if (response['success'] == true) {
        await fetchHistory();
        return true;
      }
      
      _error = response['error'];
      _isLoading = false;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Check-out failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
