class Profile {
  const Profile({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.role = 'Member',
    this.isPlaceholder = false,
    this.subTeam = 'Full Team',
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        fullName: json['full_name'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String?,
        role: json['role'] as String? ?? 'Member',
        isPlaceholder: json['is_placeholder'] as bool? ?? false,
        subTeam: json['sub_team'] as String? ?? 'Full Team',
      );

  /// For real members this equals the auth user id. Placeholder rows
  /// (`is_placeholder`) have no account and can't sign in.
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String role;
  final bool isPlaceholder;

  /// Set on the Team page (migration-roster.sql); decides which unassigned
  /// sub-team tasks count as this member's.
  final String subTeam;

  String get displayName => fullName.trim().isEmpty ? 'Unnamed member' : fullName;
}
