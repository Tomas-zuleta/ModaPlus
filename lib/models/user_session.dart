import 'user_role.dart';

class UserSession {
  final String name;
  final String email;
  final String phone;
  final UserRole role;

  const UserSession({
    required this.name,
    required this.email,
    required this.role,
    this.phone = '',
  });

  UserSession copyWith({String? name, String? phone}) {
    return UserSession(
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      role: role,
    );
  }
}