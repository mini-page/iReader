enum AppFailureType {
  unavailable,
  network,
  parsing,
  storage,
  validation,
  unknown,
}

class AppFailure {
  final AppFailureType type;
  final String message;

  const AppFailure(this.type, this.message);
}
