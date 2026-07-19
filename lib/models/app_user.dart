enum UserRole { student, teacher, parent }

UserRole userRoleFromString(String value) {
  return UserRole.values.firstWhere(
    (role) => role.name == value,
    orElse: () => UserRole.student,
  );
}

class AppUser {
  final String id;
  final String name;
  final UserRole role;
  final String? classroom;
  final List<String> managedClassrooms;

  /// Emoji avatar chosen at sign-up (students pick theirs).
  final String? avatar;

  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    this.classroom,
    this.managedClassrooms = const [],
    this.avatar,
  });

  /// Avatar to display, falling back to a role emoji.
  String get displayAvatar =>
      avatar ??
      switch (role) {
        UserRole.student => '🧒',
        UserRole.teacher => '🧑‍🏫',
        UserRole.parent => '👨‍👩‍👧',
      };

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      role: userRoleFromString(map['role'] as String? ?? 'student'),
      classroom: map['classroom'] as String?,
      avatar: map['avatar'] as String?,
      managedClassrooms:
          (map['managed_classrooms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toInsertMap() => {
    'id': id,
    'name': name,
    'role': role.name,
    if (classroom != null) 'classroom': classroom,
    if (avatar != null) 'avatar': avatar,
    if (managedClassrooms.isNotEmpty) 'managed_classrooms': managedClassrooms,
  };
}
