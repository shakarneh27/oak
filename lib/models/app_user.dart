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

  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    this.classroom,
    this.managedClassrooms = const [],
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      role: userRoleFromString(map['role'] as String? ?? 'student'),
      classroom: map['classroom'] as String?,
      managedClassrooms: (map['managed_classrooms'] as List<dynamic>?)
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
        if (managedClassrooms.isNotEmpty) 'managed_classrooms': managedClassrooms,
      };
}
