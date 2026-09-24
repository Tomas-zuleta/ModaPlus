enum UserRole { admin, client }

/// Regla simple: los correos que empiezan por "admin" son administradores.
UserRole roleFromEmail(String email) {
  return email.trim().toLowerCase().startsWith('admin')
      ? UserRole.admin
      : UserRole.client;
}