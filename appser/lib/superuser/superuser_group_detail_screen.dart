import 'package:appser/core/theme/app_colors.dart';
import 'package:appser/presentation/widgets/app_background.dart';
import 'package:appser/presentation/widgets/app_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/constants/firestore_paths.dart';
import 'superuser_create_participant_screen.dart';

class SuperuserGroupDetailScreen extends StatelessWidget {
  const SuperuserGroupDetailScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  final String groupId;
  final String groupName;

  @override
  Widget build(BuildContext context) {
    final participantsQuery = FirebaseFirestore.instance
        .collection(FirestorePaths.groupsCollection)
        .doc(groupId)
        .collection(FirestorePaths.groupParticipantsSubcollection)
        .orderBy('createdAt', descending: true);

    return AppScaffold(
      appBar: AppBar(
        title: Text(
          groupName,
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
        ),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Cadastrar participante',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SuperuserCreateParticipantScreen(
                    groupId: groupId,
                    groupName: groupName,
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: Stack(
        children: [
          AppBackground(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: participantsQuery.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Nenhum participante cadastrado neste grupo.'),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final name = (data['name'] ?? 'Sem nome').toString();
                    final cpf = (data['cpf'] ?? 'Sem CPF').toString();
                    final email = (data['email'] ?? '').toString();

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        title: Text('$name ($cpf)'),
                        subtitle: Text(email),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
