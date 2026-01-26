import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../models/leave_request.dart';

class LeaveProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<LeaveRequest> _leaves = [];
  bool _isLoading = false;
  String? _error;

  List<LeaveRequest> get leaves => _leaves;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchLeaveHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/api/leaves/self');
      if (response['success'] == true) {
        final data = response['data'];
        _leaves = (data['leaves'] as List)
            .map((json) => LeaveRequest.fromJson(json))
            .toList();
      } else {
        _error = response['error'] ?? 'Failed to fetch leaves';
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to fetch leave history';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> applyForLeave({
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/api/leaves', {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'reason': reason,
      });

      if (response['success'] == true) {
        await fetchLeaveHistory();
        return true;
      }

      _error = response['error'] ?? 'Failed to apply for leave';
      _isLoading = false;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to apply for leave. Please try again.';
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
