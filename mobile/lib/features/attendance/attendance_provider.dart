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
    // Clear previous state immediately to avoid showing old user's data
    _history = [];
    _todayAttendance = null;

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

        // Helper to check if two dates are the same day (ignoring time)
        // IMPORTANT: Convert dates to local before comparing to handle UTC/local mismatch
        bool isSameDay(DateTime date1, DateTime date2) {
          final local1 = date1.toLocal();
          final local2 = date2.toLocal();
          return local1.year == local2.year &&
              local1.month == local2.month &&
              local1.day == local2.day;
        }

        // Find today's attendance
        final now = DateTime.now();
        debugPrint('AttendanceProvider: Today (local) is ${now.toString()}');
        debugPrint('AttendanceProvider: Total records: ${_history.length}');

        // Debug: print all records for diagnosis
        for (var a in _history) {
          debugPrint('  Record date: ${a.date} (local: ${a.date.toLocal()})');
        }

        final todayRecords = _history.where((a) => isSameDay(a.date, now));

        debugPrint(
            'AttendanceProvider: Found ${todayRecords.length} records for today');
        _todayAttendance = todayRecords.isNotEmpty ? todayRecords.first : null;
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

  // Check out with GPS coordinates and work log
  Future<bool> checkOut(double latitude, double longitude,
      {Map<String, dynamic>? workLog}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final body = {
        'latitude': latitude,
        'longitude': longitude,
        ...?workLog, // Spread operator to include work log fields if present
      };

      final response = await _apiClient.post('/api/attendance/check-out', body);

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
