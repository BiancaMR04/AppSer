import 'package:appser/core/theme/app_colors.dart';
import 'package:appser/presentation/widgets/app_background.dart';
import 'package:appser/presentation/widgets/app_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/constants/firestore_paths.dart';
import 'superuser_group_detail_screen.dart';

class SuperuserGroupsScreen extends StatefulWidget {
  const SuperuserGroupsScreen({super.key});

  @override
  State<SuperuserGroupsScreen> createState() => _SuperuserGroupsScreenState();
}

class _SuperuserGroupsScreenState extends State<SuperuserGroupsScreen> {
  bool _isCreating = false;

  Future<void> _createGroup(BuildContext context) async {
    if (_isCreating) return;

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

    final draft = await showDialog<_GroupDraft>(
      context: context,
      builder: (dialogContext) => Theme(
        data: dialogTheme,
        child: const _CreateGroupDialog(),
      ),
    );

    if (draft == null) return;

    setState(() => _isCreating = true);

    try {
      await FirebaseFirestore.instance
          .collection(FirestorePaths.groupsCollection)
          .add({
        'name': draft.name,
        'description': draft.description,
        'status': draft.isActive ? 'active' : 'inactive',
        'active': draft.isActive,
        'dataInicio': Timestamp.fromDate(draft.startDate),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grupo criado com sucesso.')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao criar grupo: ${e.message ?? e.code}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar grupo: $e')),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  String _formatDate(dynamic raw) {
    DateTime? date;
    if (raw is Timestamp) date = raw.toDate();
    if (raw is DateTime) date = raw;
    if (raw is String) date = DateTime.tryParse(raw);
    if (date == null) return 'Sem data de inicio';

    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isCreating ? null : () => _createGroup(context),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        child: _isCreating
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add),
      ),
      body: Stack(
        children: [
          AppBackground(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: groupsQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erro ao carregar grupos: ${snapshot.error}'),
                  );
                }

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
                      final description =
                          (data['description'] ?? '').toString().trim();
                      final active = data['active'] != false;
                      final startDateText = _formatDate(data['dataInicio']);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
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
                          subtitle: Text(
                            [
                              'Inicio: $startDateText',
                              if (description.isNotEmpty) description,
                              active ? 'Ativo' : 'Inativo',
                            ].join(' • '),
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

class _GroupDraft {
  final String name;
  final String description;
  final DateTime startDate;
  final bool isActive;

  const _GroupDraft({
    required this.name,
    required this.description,
    required this.startDate,
    required this.isActive,
  });
}

class _CreateGroupDialog extends StatefulWidget {
  const _CreateGroupDialog();

  @override
  State<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<_CreateGroupDialog> {
  static const primaryButtonColor = AppColors.primaryBlue;
  static const accent = AppColors.primaryBlue;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  late DateTime _startDate;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Data de inicio do grupo',
      cancelText: 'Cancelar',
      confirmText: 'Selecionar',
    );

    if (selected == null) return;
    setState(() {
      _startDate = DateTime(selected.year, selected.month, selected.day);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      _GroupDraft(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        startDate: _startDate,
        isActive: _isActive,
      ),
    );
  }

  String _dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
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
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                cursorColor: AppColors.primaryBlue,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration('Nome do grupo'),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Informe o nome do grupo';
                  if (text.length < 2) return 'Nome muito curto';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                cursorColor: AppColors.primaryBlue,
                textInputAction: TextInputAction.done,
                minLines: 1,
                maxLines: 3,
                decoration: _inputDecoration('Descricao (opcional)'),
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _pickStartDate,
                child: InputDecorator(
                  decoration: _inputDecoration('Data de inicio'),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 10),
                      Text(_dateLabel(_startDate)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primaryBlue,
                title: const Text('Grupo ativo'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
            ],
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textDark),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accent, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: accent.withOpacity(0.35)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE57070)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE57070), width: 2),
      ),
    );
  }
}
