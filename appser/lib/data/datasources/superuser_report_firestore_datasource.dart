import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';

class SuperuserReportFirestoreDataSource {
  SuperuserReportFirestoreDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  Future<List<Map<String, dynamic>>> fetchUsersWithSessions() async {
    final usuariosSnapshot =
        await _firestore.collection(FirestorePaths.usersCollection).get();

    // Alguns usuários antigos podem não ter o campo `groupName` salvo em
    // `users/{uid}`. Nesses casos, usamos o documento do grupo
    // `groups/{groupId}` (campo `name`) para preencher o export.
    final groupIdsToFetch = <String>{};
    for (final doc in usuariosSnapshot.docs) {
      final data = doc.data();
      final groupId = (data['groupId'] ?? '').toString().trim();
      final groupName = (data['groupName'] ?? '').toString().trim();
      if (groupId.isNotEmpty && groupName.isEmpty) {
        groupIdsToFetch.add(groupId);
      }
    }

    final groupNameById = <String, String>{};
    if (groupIdsToFetch.isNotEmpty) {
      final groupSnapshots = await Future.wait(
        groupIdsToFetch.map(
          (groupId) => _firestore
              .collection(FirestorePaths.groupsCollection)
              .doc(groupId)
              .get(),
        ),
      );

      for (final snap in groupSnapshots) {
        if (!snap.exists) continue;
        final data = snap.data() ?? const <String, dynamic>{};
        final name = (data['name'] ?? data['groupName'] ?? '').toString().trim();
        if (name.isNotEmpty) {
          groupNameById[snap.id] = name;
        }
      }
    }

    return Future.wait(
      usuariosSnapshot.docs.map((doc) async {
        final userData = Map<String, dynamic>.from(doc.data());

        final groupId = (userData['groupId'] ?? '').toString().trim();
        final existingGroupName =
            (userData['groupName'] ?? '').toString().trim();
        if (groupId.isNotEmpty && existingGroupName.isEmpty) {
          final resolved = groupNameById[groupId];
          if (resolved != null && resolved.isNotEmpty) {
            userData['groupName'] = resolved;
          }
        }

        // Best-effort: lê também o documento de progresso (caso exista)
        // para exportar tudo que estiver armazenado nessa coleção.
        Map<String, dynamic> progressData = const <String, dynamic>{};

        // Dispara leituras em paralelo, mas mantém tipagem correta.
        final sessoesFuture =
          doc.reference.collection(FirestorePaths.sessoesSubcollection).get();
        final taskEventsFuture = doc.reference
          .collection(FirestorePaths.taskEventsSubcollection)
          .get();
        final progressFuture = _firestore
          .collection(FirestorePaths.progressCollection)
          .doc(doc.id)
          .get();

        final sessoesSnapshot = await sessoesFuture;
        final taskEventsSnapshot = await taskEventsFuture;
        final progressSnapshot = await progressFuture;

        if (progressSnapshot.exists) {
          progressData = progressSnapshot.data() ?? const <String, dynamic>{};
        }

        final sessoes = <String, dynamic>{};
        for (final sessaoDoc in sessoesSnapshot.docs) {
          final sessaoData = sessaoDoc.data();
          sessoes[sessaoDoc.id] = {
            'vezesFinalizada': sessaoData['vezesFinalizada'] ?? 0,
            'vezesFinalizadaPorConclusao':
                sessaoData['vezesFinalizadaPorConclusao'] ?? 0,
            'cliques': Map<String, int>.from(sessaoData['cliques'] ?? {}),
            'conclusoesPorItemId': Map<String, dynamic>.from(
              sessaoData['conclusoesPorItemId'] ?? {},
            ),
            'parciaisPorItemId': Map<String, dynamic>.from(
              sessaoData['parciaisPorItemId'] ?? {},
            ),
            'tarefasCompletasTotal': sessaoData['tarefasCompletasTotal'] ?? 0,
            'tarefasParciaisTotal': sessaoData['tarefasParciaisTotal'] ?? 0,
          };
        }

        final taskEvents = <Map<String, dynamic>>[];
        for (final ev in taskEventsSnapshot.docs) {
          final data = ev.data();
          taskEvents.add({
            'id': ev.id,
            ...data,
          });
        }

        return {
          'uid': doc.id,
          // Dados principais do usuário (mantém também os campos específicos
          // usados pelo relatório antigo).
          'nome': userData['nome'] ?? 'Sem nome',
          'cpf': userData['cpf'] ?? 'Sem CPF',
          'email': userData['email'] ?? '',

          // Export completo: espelha o documento de usuário e progresso.
          'user': userData,
          'progress': progressData,
          'sessoes': sessoes,
          'taskEvents': taskEvents,
        };
      }),
    );
  }
}
