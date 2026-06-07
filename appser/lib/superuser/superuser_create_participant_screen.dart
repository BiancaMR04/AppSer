import 'dart:math';

import 'package:appser/core/auth/auth_error_messages.dart';
import 'package:appser/core/formatters/cpf_input_formatter.dart';
import 'package:appser/core/theme/app_colors.dart';
import 'package:appser/firebase_options.dart';
import 'package:appser/presentation/widgets/app_background.dart';
import 'package:appser/presentation/widgets/app_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/firestore_paths.dart';

class SuperuserCreateParticipantScreen extends StatefulWidget {
  const SuperuserCreateParticipantScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  final String groupId;
  final String groupName;

  @override
  State<SuperuserCreateParticipantScreen> createState() =>
      _SuperuserCreateParticipantScreenState();
}

class _SuperuserCreateParticipantScreenState
    extends State<SuperuserCreateParticipantScreen> {
  static const Color _primaryButtonColor = Color(0xFF60BFCD);
  static const Color _accent = Color(0xFF10707E);

  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _cpfCtrl.dispose();
    super.dispose();
  }

  Future<FirebaseAuth> _getSecondaryAuth() async {
    try {
      final app = await Firebase.initializeApp(
        name: 'secondary',
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return FirebaseAuth.instanceFor(app: app);
    } catch (_) {
      final app = Firebase.app('secondary');
      return FirebaseAuth.instanceFor(app: app);
    }
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  DateTime _dateOnly(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  bool _isValidCpf(String value) {
    final cpf = CpfUtils.digitsOnly(value);
    if (cpf.length != 11 || RegExp(r'^(\d)\1*$').hasMatch(cpf)) return false;

    int calcDigit(List<int> numbers, int multiplierStart) {
      var sum = 0;
      for (var i = 0; i < numbers.length; i++) {
        sum += numbers[i] * (multiplierStart - i);
      }
      final mod = sum % 11;
      return (mod < 2) ? 0 : 11 - mod;
    }

    final digits = cpf.split('').map(int.parse).toList();
    final d1 = calcDigit(digits.sublist(0, 9), 10);
    final d2 = calcDigit(digits.sublist(0, 10), 11);
    return d1 == digits[9] && d2 == digits[10];
  }

  String _temporaryPassword() {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#%';
    final random = Random.secure();
    return List.generate(24, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    FirebaseAuth? secondaryAuth;
    User? createdUser;

    try {
      secondaryAuth = await _getSecondaryAuth();

      final email = _emailCtrl.text.trim().toLowerCase();
      final name = _nameCtrl.text.trim();
      final cpf = CpfUtils.digitsOnly(_cpfCtrl.text);

      final firestore = FirebaseFirestore.instance;
      final existingUserWithEmail = await firestore
          .collection(FirestorePaths.usersCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (existingUserWithEmail.docs.isNotEmpty) {
        throw FirebaseAuthException(code: 'email-already-in-use');
      }

      final groupRef = firestore
          .collection(FirestorePaths.groupsCollection)
          .doc(widget.groupId);
      final groupSnap = await groupRef.get();
      final groupData = groupSnap.data();

      if (!groupSnap.exists || groupData == null) {
        throw StateError('Grupo nao encontrado.');
      }

      if (groupData['active'] == false || groupData['status'] == 'inactive') {
        throw StateError('Este grupo esta inativo.');
      }

      final groupName =
          (groupData['name'] ?? widget.groupName).toString().trim();
      final baseDate = _parseDate(groupData['dataInicio']) ??
          _parseDate(groupData['createdAt']) ??
          DateTime.now();
      final groupStartDate = _dateOnly(baseDate);
      final startTimestamp = Timestamp.fromDate(groupStartDate);
      final startsTodayOrBefore =
          !groupStartDate.isAfter(_dateOnly(DateTime.now()));

      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: _temporaryPassword(),
      );
      createdUser = cred.user;

      final uid = createdUser?.uid;
      if (uid == null) {
        throw StateError('Falha ao criar usuario (uid nulo).');
      }

      await createdUser!.updateDisplayName(name);
      await secondaryAuth.sendPasswordResetEmail(email: email);

      final batch = firestore.batch();

      batch.set(
        firestore.collection(FirestorePaths.usersCollection).doc(uid),
        {
          'nome': name,
          'cpf': cpf,
          'email': email,
          'createdAt': startTimestamp,
          'accountCreatedAt': FieldValue.serverTimestamp(),
          'dataInicio': startTimestamp,
          'session0': startsTodayOrBefore,
          'session1': startsTodayOrBefore,
          'session2': false,
          'session3': false,
          'session4': false,
          'session5': false,
          'session6': false,
          'session7': false,
          'session8': false,
          'groupId': widget.groupId,
          'groupName': groupName,
          'passwordSetupEmailSentAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      batch.set(
        groupRef
            .collection(FirestorePaths.groupParticipantsSubcollection)
            .doc(uid),
        {
          'uid': uid,
          'name': name,
          'cpf': cpf,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'dataInicio': startTimestamp,
          'passwordSetupEmailSentAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
      await secondaryAuth.signOut();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Participante cadastrado. Enviamos um link para criar a senha.',
          ),
        ),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (createdUser != null) {
        try {
          await createdUser!.delete();
        } catch (_) {}
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AuthErrorMessages.fromFirebaseAuthCode(
              e.code,
              operation: AuthOperation.register,
            ),
          ),
        ),
      );
    } catch (e) {
      if (createdUser != null) {
        try {
          await createdUser!.delete();
        } catch (_) {}
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao cadastrar: $e')),
      );
    } finally {
      try {
        await secondaryAuth?.signOut();
      } catch (_) {}
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _accent.withOpacity(0.35)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accent, width: 2),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 380 ? 16.0 : 24.0;

    return AppScaffold(
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.of(context).pop(),
                      icon:
                          const Icon(Icons.arrow_back, color: Color(0xFF2F7888)),
                      tooltip: 'Voltar',
                    ),
                    const Expanded(
                      child: Text(
                        'Cadastrar participante',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF202020),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    image: const DecorationImage(
                      image: AssetImage('assets/back.png'),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        height: 86,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.groupName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF202020),
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Crie a conta e envie o link para definir senha.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.black.withOpacity(0.62),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: _inputDecoration('Nome'),
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            final text = v?.trim() ?? '';
                            if (text.isEmpty) return 'Informe o nome';
                            if (text.length < 2) return 'Nome muito curto';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _emailCtrl,
                          decoration: _inputDecoration('E-mail'),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            final email = v?.trim() ?? '';
                            if (!AuthErrorMessages.isValidEmail(email)) {
                              return 'Informe um e-mail valido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _cpfCtrl,
                          decoration: _inputDecoration('CPF'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                            CpfInputFormatter(),
                          ],
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _save(),
                          validator: (v) {
                            final digits = CpfUtils.digitsOnly(v ?? '');
                            if (digits.isEmpty) return 'Informe o CPF';
                            if (!_isValidCpf(digits)) return 'CPF invalido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'O participante recebera um e-mail para escolher a propria senha.',
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: Color(0xFF555555),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryButtonColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Cadastrar e enviar link'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
