/// Constantes de paths/coleções do Firestore.
///
/// IMPORTANTE: estes valores refletem o comportamento atual do app.
/// Não altere nomes de coleções/campos sem uma migração explícita.
abstract final class FirestorePaths {
  static const String usersCollection = 'users';
  static const String progressCollection = 'progress';
  static const String groupsCollection = 'groups';

  // Subcoleções
  static const String sessoesSubcollection = 'sessoes';
  static const String groupParticipantsSubcollection = 'participants';

  // Eventos de tarefas (append-only)
  static const String taskEventsSubcollection = 'taskEvents';
}
