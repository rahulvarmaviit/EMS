class Team {
  final String id;
  final String name;
  final String? leadId;
  final String? leadName;
  final int? memberCount;
  
  Team({
    required this.id,
    required this.name,
    this.leadId,
    this.leadName,
    this.memberCount,
  });
  
  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'],
      name: json['name'],
      leadId: json['lead_id'],
      leadName: json['lead_name'],
      memberCount: json['member_count'] is int 
          ? json['member_count'] 
          : int.tryParse(json['member_count']?.toString() ?? '0'),
    );
  }
}
