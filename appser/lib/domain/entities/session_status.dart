class SessionStatus {
  final Map<String, bool> values;

  const SessionStatus(this.values);

  Map<String, bool> toMap() => Map<String, bool>.from(values);
}
