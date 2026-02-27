import 'package:appser/core/theme/app_colors.dart';
import 'package:appser/presentation/widgets/app_background.dart';
import 'package:appser/presentation/widgets/app_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/constants/firestore_paths.dart';
import 'superuser_group_detail_screen.dart';

class SuperuserGroupsScreen extends StatelessWidget {
  const SuperuserGroupsScreen({super.key});

  Future<void> _createGroup(BuildContext context) async {
    final baseTheme = Theme.of(context);
    final dialogTheme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: AppColors.primaryBlue,
        secondary: AppColors.primaryBlue,
      ),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
    );

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => Theme(
        data: dialogTheme,
        child: const _CreateGroupDialog(),
      ),
    );

    if (name == null || name.isEmpty) return;

    await FirebaseFirestore.instance.collection(FirestorePaths.groupsCollection).add({
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final tileTheme = baseTheme.copyWith(
      dividerColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: AppColors.primaryBlue,
        secondary: AppColors.primaryBlue,
      ),
    );

    final groupsQuery = FirebaseFirestore.instance
        .collection(FirestorePaths.groupsCollection)
        .orderBy('createdAt', descending: true);

    return AppScaffold(
      appBar: AppBar(
        title: const Text(
          'Grupos',
          style:
              TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
        ),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createGroup(context),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Stack(
        children: [
          AppBackground(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: groupsQuery.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('Nenhum grupo criado ainda.'));
                }

                return Theme(
                  data: tileTheme,
                  child: ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      final name = (data['name'] ?? 'Sem nome').toString();

                      return Card(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        color: Colors.white,
                        surfaceTintColor: Colors.transparent,
                        child: ListTile(
                          title: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: AppColors.primaryBlue,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SuperuserGroupDetailScreen(
                                  groupId: doc.id,
                                  groupName: name,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateGroupDialog extends StatefulWidget {
  const _CreateGroupDialog();

  @override
  State<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<_CreateGroupDialog> {
  static const primaryButtonColor = AppColors.primaryBlue;
  static const accent = AppColors.primaryBlue;

  final TextEditingController _controller = TextEditingController();

  void _submit() {
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        'Criar grupo',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        cursorColor: AppColors.primaryBlue,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: 'Nome do grupo',
          labelStyle: const TextStyle(color: AppColors.textDark),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accent, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accent.withOpacity(0.35)),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: accent,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryButtonColor,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Criar'),
        ),
      ],
    );
  }
}
