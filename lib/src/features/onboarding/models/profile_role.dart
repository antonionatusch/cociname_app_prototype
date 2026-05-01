enum ProfileRole { consumer, cook, admin }

extension ProfileRoleX on ProfileRole {
  String get databaseValue {
    switch (this) {
      case ProfileRole.consumer:
        return 'consumer';
      case ProfileRole.cook:
        return 'cook';
      case ProfileRole.admin:
        return 'admin';
    }
  }

  String get label {
    switch (this) {
      case ProfileRole.consumer:
        return 'Consumidor';
      case ProfileRole.cook:
        return 'Emprendedor';
      case ProfileRole.admin:
        return 'Administrador';
    }
  }

  String get shortDescription {
    switch (this) {
      case ProfileRole.consumer:
        return 'Explora platos y filtra segun tus gustos.';
      case ProfileRole.cook:
        return 'Publica comida casera y administra tu oferta.';
      case ProfileRole.admin:
        return 'Supervisa contenido e incidencias operativas.';
    }
  }

  static ProfileRole fromDatabaseValue(String value) {
    return ProfileRole.values.firstWhere(
      (role) => role.databaseValue == value,
      orElse: () => ProfileRole.consumer,
    );
  }
}
