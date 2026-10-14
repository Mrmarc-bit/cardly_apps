/// Hirarki failure domain untuk penanganan error terstruktur di Cardly
sealed class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class SecurityFailure extends Failure {
  const SecurityFailure(super.message);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}
