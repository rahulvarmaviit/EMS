class Attendance {
  final String id;
  final String date;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String status;
  final String? userName;
  
  Attendance({
    required this.id,
    required this.date,
    required this.checkInTime,
    this.checkOutTime,
    required this.status,
    this.userName,
  });
  
  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      date: json['date'],
      checkInTime: DateTime.parse(json['check_in_time']),
      checkOutTime: json['check_out_time'] != null 
          ? DateTime.parse(json['check_out_time']) 
          : null,
      status: json['status'],
      userName: json['full_name'],
    );
  }
  
  String get statusDisplay {
    switch (status) {
      case 'PRESENT':
        return 'Present';
      case 'LATE':
        return 'Late';
      case 'HALF_DAY':
        return 'Half Day';
      default:
        return status;
    }
  }
  
  bool get isCheckedOut => checkOutTime != null;
}
