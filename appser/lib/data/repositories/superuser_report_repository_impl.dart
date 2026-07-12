import 'package:excel/excel.dart' as ex;
import 'dart:convert';

import '../../domain/repositories/superuser_report_repository.dart';
import '../datasources/superuser_report_excel_datasource.dart';
import '../datasources/superuser_report_file_datasource.dart';
import '../datasources/superuser_report_firestore_datasource.dart';

class SuperuserReportRepositoryImpl implements SuperuserReportRepository {
  SuperuserReportRepositoryImpl({
    required SuperuserReportFirestoreDataSource firestoreDataSource,
    required SuperuserReportExcelDataSource excelDataSource,
    required SuperuserReportFileDataSource fileDataSource,
    required String sheetName,
  })  : _firestoreDataSource = firestoreDataSource,
        _excelDataSource = excelDataSource,
        _fileDataSource = fileDataSource,
        _sheetName = sheetName;

  final SuperuserReportFirestoreDataSource _firestoreDataSource;
  final SuperuserReportExcelDataSource _excelDataSource;
  final SuperuserReportFileDataSource _fileDataSource;
  final String _sheetName;

  static const Map<String, String> _nomesSessoesAmigaveis = {
    'sessao_1': 'Sessão 1',
    'sessao_2': 'Sessão 2',
    'sessao_3': 'Sessão 3',
    'sessao_4': 'Sessão 4',
    'sessao_5': 'Sessão 5',
    'sessao_6': 'Sessão 6',
    'sessao_7': 'Sessão 7',
    'sessao_8': 'Sessão 8',
  };

  static const Map<String, String> _nomeParaId = {
    'checkin': 'Check-in',
    'preparacao_pratica_uva':
        'Preparação para o exercício "Prática da Uva Passa"',
    'pratica_uva': 'Prática da Uva Passa',
    'oque_e_mindfulness': 'O que é Mindfulness',
    'posturas_copy': 'Posturas copy',
    'escaneamento_corporal': 'Escaneamento corporal',
    'praticando_em_casa': 'Praticando em Casa',
    'checkout': 'Check-out',
    'escaneamento_automassagem': 'Escaneamento com automassagem',
    'cinco_desafios': 'Cinco desafios',
    'andando_na_rua': 'Andando na rua',
    'sofrimento_duplo': 'Primeiro e segundo sofrimento',
    'montanha': 'Montanha',
    'consciencia_ouvir': 'Consciência de ouvir',
    'caminhada_mindfulness': 'Caminhada mindfulness',
    'respiracao': 'Respiração',
    'parar_teoria': 'Parar Teoria',
    'parar_audio': 'Parar Áudio',
    'consciencia_ver': 'Consciência de Ver',
    'meditacao_sentada': 'Meditação Sentada',
    'lista_gatilhos': 'Lista de gatilhos',
    'falso_refugio': 'Falso Refúgio',
    'parar_situacao': 'Parar na situação desafiadora',
    'poema_casa_hospedes': 'Poema "A Casa de Hóspedes"',
    'discussao_aceitacao_emocoes': 'Discussão sobre aceitação e emoções',
    'revisao_cinco_desafios': 'Revendo os Cinco desafios da Sessão 2',
    'movimentos_copy': 'Movimentos Copy',
    'movimentos_mindfulness': 'Movimentos Mindfulness',
    'pratica_pensamentos': 'Prática dos Pensamentos',
    'ras': 'Te Recebo Aceito Solto (RAS)',
    'cadeira_reatividade': 'Cadeira da reatividade',
    'bondade_amorosa': 'Prática Bondade Amorosa',
    'lista_atividades_diarias': 'Lista de atividades diárias',
    'visualizacao_fortalecedoras': 'Visualização Atividades Fortalecedoras',
    'funil_exaustao': 'Funil da exaustão',
    'poema_suporte_estrategias':
        'Poema + Suporte e estratégias para prática continuada',
    'pratica_pedra': 'Prática da pedra',
  };

  String _formatarItem(String raw) {
    final semPrefixo = raw.replaceAll(RegExp(r'^(video_|audio_|pdf_)'), '');
    return _nomeParaId.entries
        .firstWhere(
          (entry) =>
              entry.key.toLowerCase().replaceAll(RegExp(r'["\s]'), '') ==
              semPrefixo.toLowerCase().replaceAll(RegExp(r'["\s]'), ''),
          orElse: () => MapEntry(semPrefixo, semPrefixo),
        )
        .value;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchUsersWithSessions() {
    return _firestoreDataSource.fetchUsersWithSessions();
  }

  String _isoOrEmpty(Object? value) {
    if (value == null) return '';
    if (value is DateTime) return value.toIso8601String();
    if (value is String) return value;
    // Firestore Timestamp
    try {
      // ignore: avoid_dynamic_calls
      final dt = (value as dynamic).toDate();
      if (dt is DateTime) return dt.toIso8601String();
    } catch (_) {
      // ignore
    }
    return value.toString();
  }

  Map<String, dynamic> _asMap(Object? v) {
    if (v == null) return const <String, dynamic>{};
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return const <String, dynamic>{};
  }

  String _json(Object? v) {
    try {
      return jsonEncode(v ?? const <String, dynamic>{});
    } catch (_) {
      return '';
    }
  }

  String _csvEscape(Object? value) {
    final s = (value ?? '').toString();
    final needsQuotes = s.contains(',') || s.contains('\n') || s.contains('"');
    if (!needsQuotes) return s;
    return '"${s.replaceAll('"', '""')}"';
  }

  @override
  Future<String> exportReportToCsvFilePath({required String fileName}) async {
    final usuarios = await fetchUsersWithSessions();

    final buffer = StringBuffer();
    buffer.writeln(
      [
        // Tipo da linha para facilitar leitura/filtragem no Excel/Sheets.
        'rowType',

        'uid',
        'nome',
        'cpf',
        'email',

        // Metadados e vínculo
        'groupId',
        'groupName',
        'createdAt',
        'dataInicio',
        'sessionsLastAutoUnlockAt',
        'session0',
        'session1',
        'session2',
        'session3',
        'session4',
        'session5',
        'session6',
        'session7',
        'session8',
        'progress_json',

        'sessaoId',

        'eventId',
        'eventType',
        'createdAt',
        'tipo',
        'itemId',
        'isSupplementary',
        'title',
        'path',
        'positionSeconds',
        'positionMinute',
        'durationSeconds',
        'mode',

        // Agregados por sessão (úteis mesmo quando rowType = event)
        'vezesFinalizada',
        'vezesFinalizadaPorConclusao',
        'tarefasCompletasTotal',
        'tarefasParciaisTotal',
        'cliques_json',
        'conclusoesPorItemId_json',
        'parciaisPorItemId_json',
      ].join(','),
    );

    for (final usuario in usuarios) {
      final uid = (usuario['uid'] ?? '').toString();
      final nome = (usuario['nome'] ?? 'Sem nome').toString();
      final cpf = (usuario['cpf'] ?? 'Sem CPF').toString();
      final email = (usuario['email'] ?? '').toString();

      final userDoc = _asMap(usuario['user']);
      final progressDoc = _asMap(usuario['progress']);

      final groupId = (userDoc['groupId'] ?? '').toString();
      final groupName = (userDoc['groupName'] ?? '').toString();
      final userCreatedAt = _isoOrEmpty(userDoc['createdAt']);
      final dataInicio = _isoOrEmpty(userDoc['dataInicio']);
      final sessionsLastAutoUnlockAt =
          _isoOrEmpty(userDoc['sessionsLastAutoUnlockAt']);

      bool readBool(String key) {
        final v = userDoc[key];
        if (v is bool) return v;
        return false;
      }

      final session0 = readBool('session0');
      final session1 = readBool('session1');
      final session2 = readBool('session2');
      final session3 = readBool('session3');
      final session4 = readBool('session4');
      final session5 = readBool('session5');
      final session6 = readBool('session6');
      final session7 = readBool('session7');
      final session8 = readBool('session8');

      final progressJson = _json(progressDoc);

      final sessoes =
          (usuario['sessoes'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final taskEvents = (usuario['taskEvents'] as List?) ?? const [];

      // 1) Linha de resumo do usuário (sempre exporta)
      buffer.writeln([
        _csvEscape('user_summary'),
        _csvEscape(uid),
        _csvEscape(nome),
        _csvEscape(cpf),
        _csvEscape(email),
        _csvEscape(groupId),
        _csvEscape(groupName),
        _csvEscape(userCreatedAt),
        _csvEscape(dataInicio),
        _csvEscape(sessionsLastAutoUnlockAt),
        _csvEscape(session0),
        _csvEscape(session1),
        _csvEscape(session2),
        _csvEscape(session3),
        _csvEscape(session4),
        _csvEscape(session5),
        _csvEscape(session6),
        _csvEscape(session7),
        _csvEscape(session8),
        _csvEscape(progressJson),
        _csvEscape(''), // sessaoId
        _csvEscape(''), // eventId
        _csvEscape('user_summary'), // eventType
        _csvEscape(''), // createdAt
        _csvEscape(''), // tipo
        _csvEscape(''), // itemId
        _csvEscape(''), // isSupplementary
        _csvEscape(''), // title
        _csvEscape(''), // path
        _csvEscape(''), // positionSeconds
        _csvEscape(''), // positionMinute
        _csvEscape(''), // durationSeconds
        _csvEscape(''), // mode
        _csvEscape(''), // vezesFinalizada
        _csvEscape(''), // vezesFinalizadaPorConclusao
        _csvEscape(''), // tarefasCompletasTotal
        _csvEscape(''), // tarefasParciaisTotal
        _csvEscape(''), // cliques_json
        _csvEscape(''), // conclusoesPorItemId_json
        _csvEscape(''), // parciaisPorItemId_json
      ].join(','));

      // Exporta eventos (append-only) como principal fonte de rastreamento.
      for (final evAny in taskEvents) {
        final ev = Map<String, dynamic>.from(evAny as Map);
        final sessaoId = (ev['sessaoId'] ?? '').toString();
        final sessao =
            (sessoes[sessaoId] as Map<String, dynamic>?) ?? <String, dynamic>{};

        final eventCreatedAt = ev['createdAt'];
        final createdAtStr = _isoOrEmpty(eventCreatedAt);

        final cliquesJson = jsonEncode(sessao['cliques'] ?? {});
        final concJson = jsonEncode(sessao['conclusoesPorItemId'] ?? {});
        final parcJson = jsonEncode(sessao['parciaisPorItemId'] ?? {});

        final row = [
          _csvEscape('event'),
          _csvEscape(uid),
          _csvEscape(nome),
          _csvEscape(cpf),
          _csvEscape(email),
          _csvEscape(groupId),
          _csvEscape(groupName),
          _csvEscape(userCreatedAt),
          _csvEscape(dataInicio),
          _csvEscape(sessionsLastAutoUnlockAt),
          _csvEscape(session0),
          _csvEscape(session1),
          _csvEscape(session2),
          _csvEscape(session3),
          _csvEscape(session4),
          _csvEscape(session5),
          _csvEscape(session6),
          _csvEscape(session7),
          _csvEscape(session8),
          _csvEscape(progressJson),
          _csvEscape(sessaoId),
          _csvEscape(ev['id'] ?? ''),
          _csvEscape(ev['eventType'] ?? ''),
          _csvEscape(createdAtStr),
          _csvEscape(ev['tipo'] ?? ''),
          _csvEscape(ev['itemId'] ?? ''),
          _csvEscape(ev['isSupplementary'] ?? false),
          _csvEscape(ev['title'] ?? ''),
          _csvEscape(ev['path'] ?? ''),
          _csvEscape(ev['positionSeconds'] ?? ''),
          _csvEscape(ev['positionMinute'] ?? ''),
          _csvEscape(ev['durationSeconds'] ?? ''),
          _csvEscape(ev['mode'] ?? ''),
          _csvEscape(sessao['vezesFinalizada'] ?? 0),
          _csvEscape(sessao['vezesFinalizadaPorConclusao'] ?? 0),
          _csvEscape(sessao['tarefasCompletasTotal'] ?? 0),
          _csvEscape(sessao['tarefasParciaisTotal'] ?? 0),
          _csvEscape(cliquesJson),
          _csvEscape(concJson),
          _csvEscape(parcJson),
        ];
        buffer.writeln(row.join(','));
      }

      // 2) Resumo por sessão (sempre exporta, mesmo se houver eventos)
      for (final sessaoEntry in sessoes.entries) {
        final sessaoId = sessaoEntry.key;
        final sessao =
            (sessaoEntry.value as Map<String, dynamic>?) ?? <String, dynamic>{};

        buffer.writeln([
          _csvEscape('session_summary'),
          _csvEscape(uid),
          _csvEscape(nome),
          _csvEscape(cpf),
          _csvEscape(email),
          _csvEscape(groupId),
          _csvEscape(groupName),
          _csvEscape(userCreatedAt),
          _csvEscape(dataInicio),
          _csvEscape(sessionsLastAutoUnlockAt),
          _csvEscape(session0),
          _csvEscape(session1),
          _csvEscape(session2),
          _csvEscape(session3),
          _csvEscape(session4),
          _csvEscape(session5),
          _csvEscape(session6),
          _csvEscape(session7),
          _csvEscape(session8),
          _csvEscape(progressJson),
          _csvEscape(sessaoId),
          _csvEscape(''),
          _csvEscape('session_summary'),
          _csvEscape(''),
          _csvEscape(''),
          _csvEscape(''),
          _csvEscape(''),
          _csvEscape(''),
          _csvEscape(''),
          _csvEscape(''),
          _csvEscape(''),
          _csvEscape(''),
          _csvEscape(''),
          _csvEscape(''),
          _csvEscape(sessao['vezesFinalizada'] ?? 0),
          _csvEscape(sessao['vezesFinalizadaPorConclusao'] ?? 0),
          _csvEscape(sessao['tarefasCompletasTotal'] ?? 0),
          _csvEscape(sessao['tarefasParciaisTotal'] ?? 0),
          _csvEscape(jsonEncode(sessao['cliques'] ?? {})),
          _csvEscape(jsonEncode(sessao['conclusoesPorItemId'] ?? {})),
          _csvEscape(jsonEncode(sessao['parciaisPorItemId'] ?? {})),
        ].join(','));
      }
    }

    final bytes = utf8.encode(buffer.toString());
    return _fileDataSource.writeBytesToDocuments(
      fileName: fileName,
      bytes: bytes,
    );
  }

  @override
  Future<String> exportReportToExcelFilePath({required String fileName}) async {
    final usuarios = await fetchUsersWithSessions();

    final excel = ex.Excel.createExcel();
    excel.delete('Sheet1');

    final usersSheet = excel['Usuarios'];
    final sessionsSheet = excel['Sessoes'];
    final eventsSheet = excel['Eventos'];
    final dictionarySheet = excel['Dicionario'];

    usersSheet.appendRow([
      ex.TextCellValue('ID do participante'),
      ex.TextCellValue('Nome'),
      ex.TextCellValue('CPF'),
      ex.TextCellValue('E-mail'),
      ex.TextCellValue('ID do grupo'),
      ex.TextCellValue('Grupo'),
      ex.TextCellValue('Data de cadastro'),
      ex.TextCellValue('Data de inicio no protocolo'),
      ex.TextCellValue('Ultima liberacao automatica'),
      ex.TextCellValue('Sessao 0 liberada'),
      ex.TextCellValue('Sessao 1 liberada'),
      ex.TextCellValue('Sessao 2 liberada'),
      ex.TextCellValue('Sessao 3 liberada'),
      ex.TextCellValue('Sessao 4 liberada'),
      ex.TextCellValue('Sessao 5 liberada'),
      ex.TextCellValue('Sessao 6 liberada'),
      ex.TextCellValue('Sessao 7 liberada'),
      ex.TextCellValue('Sessao 8 liberada'),
      ex.TextCellValue('Progresso nos materiais'),
    ]);

    sessionsSheet.appendRow([
      ex.TextCellValue('ID do participante'),
      ex.TextCellValue('Nome'),
      ex.TextCellValue('CPF'),
      ex.TextCellValue('E-mail'),
      ex.TextCellValue('ID do grupo'),
      ex.TextCellValue('Grupo'),
      ex.TextCellValue('Sessao'),
      ex.TextCellValue('Finalizacoes registradas'),
      ex.TextCellValue('Finalizacoes por conclusao das atividades'),
      ex.TextCellValue('Atividades concluidas'),
      ex.TextCellValue('Atividades iniciadas e nao concluidas'),
      ex.TextCellValue('Cliques por atividade'),
      ex.TextCellValue('Conclusoes por atividade'),
      ex.TextCellValue('Parciais por atividade'),
    ]);

    eventsSheet.appendRow([
      ex.TextCellValue('ID do participante'),
      ex.TextCellValue('Nome'),
      ex.TextCellValue('CPF'),
      ex.TextCellValue('E-mail'),
      ex.TextCellValue('ID do grupo'),
      ex.TextCellValue('Grupo'),
      ex.TextCellValue('ID do evento'),
      ex.TextCellValue('Tipo de evento'),
      ex.TextCellValue('Data e hora do evento'),
      ex.TextCellValue('Sessao'),
      ex.TextCellValue('Tipo de conteudo'),
      ex.TextCellValue('ID da atividade'),
      ex.TextCellValue('Material de apoio'),
      ex.TextCellValue('Titulo da atividade'),
      ex.TextCellValue('Arquivo ou caminho'),
      ex.TextCellValue('Ponto em que parou (segundos)'),
      ex.TextCellValue('Ponto em que parou (minuto)'),
      ex.TextCellValue('Duracao total (segundos)'),
      ex.TextCellValue('Modo de registro'),
    ]);

    dictionarySheet.appendRow([
      ex.TextCellValue('Aba'),
      ex.TextCellValue('Coluna'),
      ex.TextCellValue('Descricao'),
    ]);

    void addDictionaryRow({
      required String sheet,
      required String column,
      required String description,
    }) {
      dictionarySheet.appendRow([
        ex.TextCellValue(sheet),
        ex.TextCellValue(column),
        ex.TextCellValue(description),
      ]);
    }

    void addCommonParticipantColumns(String sheet) {
      addDictionaryRow(
        sheet: sheet,
        column: 'ID do participante',
        description:
            'Identificador unico do participante no Firebase Authentication.',
      );
      addDictionaryRow(
        sheet: sheet,
        column: 'Nome',
        description: 'Nome cadastrado para o participante.',
      );
      addDictionaryRow(
        sheet: sheet,
        column: 'CPF',
        description: 'CPF cadastrado para o participante.',
      );
      addDictionaryRow(
        sheet: sheet,
        column: 'E-mail',
        description: 'E-mail cadastrado para o participante.',
      );
      addDictionaryRow(
        sheet: sheet,
        column: 'ID do grupo',
        description: 'Identificador interno do grupo do participante.',
      );
      addDictionaryRow(
        sheet: sheet,
        column: 'Grupo',
        description: 'Nome do grupo do participante.',
      );
    }

    addCommonParticipantColumns('Usuarios');
    addDictionaryRow(
      sheet: 'Usuarios',
      column: 'Data de cadastro',
      description: 'Data em que o participante foi criado no app.',
    );
    addDictionaryRow(
      sheet: 'Usuarios',
      column: 'Data de inicio no protocolo',
      description:
          'Data usada como referencia para liberar novas sessoes semanalmente.',
    );
    addDictionaryRow(
      sheet: 'Usuarios',
      column: 'Ultima liberacao automatica',
      description:
          'Ultimo momento em que o app atualizou automaticamente as sessoes liberadas.',
    );
    for (var i = 0; i <= 8; i++) {
      addDictionaryRow(
        sheet: 'Usuarios',
        column: 'Sessao $i liberada',
        description:
            'Indica se a sessao $i estava liberada para o participante no momento da exportacao.',
      );
    }
    addDictionaryRow(
      sheet: 'Usuarios',
      column: 'Progresso nos materiais',
      description:
          'Dados brutos em formato JSON sobre progresso de materiais e PDFs.',
    );

    addCommonParticipantColumns('Sessoes');
    addDictionaryRow(
      sheet: 'Sessoes',
      column: 'Sessao',
      description: 'Sessao do protocolo relacionada aos dados da linha.',
    );
    addDictionaryRow(
      sheet: 'Sessoes',
      column: 'Finalizacoes registradas',
      description:
          'Quantidade de vezes em que a sessao foi marcada como finalizada.',
    );
    addDictionaryRow(
      sheet: 'Sessoes',
      column: 'Finalizacoes por conclusao das atividades',
      description:
          'Quantidade de finalizacoes geradas pela conclusao das atividades obrigatorias da sessao.',
    );
    addDictionaryRow(
      sheet: 'Sessoes',
      column: 'Atividades concluidas',
      description:
          'Total de atividades concluidas pelo participante nessa sessao.',
    );
    addDictionaryRow(
      sheet: 'Sessoes',
      column: 'Atividades iniciadas e nao concluidas',
      description:
          'Total de atividades iniciadas, mas sem conclusao registrada nessa sessao.',
    );
    addDictionaryRow(
      sheet: 'Sessoes',
      column: 'Cliques por atividade',
      description:
          'Mapa em JSON com a quantidade de acessos ou cliques em cada atividade.',
    );
    addDictionaryRow(
      sheet: 'Sessoes',
      column: 'Conclusoes por atividade',
      description:
          'Mapa em JSON com a quantidade de conclusoes registradas por atividade.',
    );
    addDictionaryRow(
      sheet: 'Sessoes',
      column: 'Parciais por atividade',
      description:
          'Mapa em JSON com atividades iniciadas e nao concluidas, por atividade.',
    );

    addCommonParticipantColumns('Eventos');
    addDictionaryRow(
      sheet: 'Eventos',
      column: 'ID do evento',
      description: 'Identificador unico do evento de interacao.',
    );
    addDictionaryRow(
      sheet: 'Eventos',
      column: 'Tipo de evento',
      description:
          'Tipo da interacao registrada, como clique, conclusao ou progresso parcial.',
    );
    addDictionaryRow(
      sheet: 'Eventos',
      column: 'Data e hora do evento',
      description: 'Momento em que a interacao foi registrada.',
    );
    addDictionaryRow(
      sheet: 'Eventos',
      column: 'Sessao',
      description: 'Sessao do protocolo associada ao evento.',
    );
    addDictionaryRow(
      sheet: 'Eventos',
      column: 'Tipo de conteudo',
      description: 'Formato do conteudo acessado, como audio, video ou PDF.',
    );
    addDictionaryRow(
      sheet: 'Eventos',
      column: 'ID da atividade',
      description: 'Identificador interno da atividade acessada.',
    );
    addDictionaryRow(
      sheet: 'Eventos',
      column: 'Material de apoio',
      description:
          'Indica se o evento aconteceu em material complementar, e nao em atividade principal.',
    );
    addDictionaryRow(
      sheet: 'Eventos',
      column: 'Titulo da atividade',
      description: 'Titulo exibido ao participante para a atividade.',
    );
    addDictionaryRow(
      sheet: 'Eventos',
      column: 'Arquivo ou caminho',
      description: 'Caminho interno do arquivo de audio, video, PDF ou texto.',
    );
    addDictionaryRow(
      sheet: 'Eventos',
      column: 'Ponto em que parou (segundos)',
      description:
          'Posicao em segundos em que o participante parou audio ou video, quando aplicavel.',
    );
    addDictionaryRow(
      sheet: 'Eventos',
      column: 'Ponto em que parou (minuto)',
      description:
          'Posicao em minutos em que o participante parou audio ou video, quando aplicavel.',
    );
    addDictionaryRow(
      sheet: 'Eventos',
      column: 'Duracao total (segundos)',
      description:
          'Duracao total do audio ou video em segundos, quando disponivel.',
    );
    addDictionaryRow(
      sheet: 'Eventos',
      column: 'Modo de registro',
      description:
          'Como a interacao foi registrada, por exemplo abertura do conteudo ou chegada ao fim.',
    );

    for (final usuario in usuarios) {
      final uid = (usuario['uid'] ?? '').toString();
      final nome = (usuario['nome'] ?? 'Sem nome').toString();
      final cpf = (usuario['cpf'] ?? 'Sem CPF').toString();
      final email = (usuario['email'] ?? '').toString();
      final userDoc = _asMap(usuario['user']);
      final progressDoc = _asMap(usuario['progress']);

      final groupId = (userDoc['groupId'] ?? '').toString();
      final groupName = (userDoc['groupName'] ?? '').toString();
      final createdAt = _isoOrEmpty(userDoc['createdAt']);
      final dataInicio = _isoOrEmpty(userDoc['dataInicio']);
      final sessionsLastAutoUnlockAt =
          _isoOrEmpty(userDoc['sessionsLastAutoUnlockAt']);

      bool readBool(String key) {
        final v = userDoc[key];
        if (v is bool) return v;
        return false;
      }

      usersSheet.appendRow([
        ex.TextCellValue(uid),
        ex.TextCellValue(nome),
        ex.TextCellValue(cpf),
        ex.TextCellValue(email),
        ex.TextCellValue(groupId),
        ex.TextCellValue(groupName),
        ex.TextCellValue(createdAt),
        ex.TextCellValue(dataInicio),
        ex.TextCellValue(sessionsLastAutoUnlockAt),
        ex.BoolCellValue(readBool('session0')),
        ex.BoolCellValue(readBool('session1')),
        ex.BoolCellValue(readBool('session2')),
        ex.BoolCellValue(readBool('session3')),
        ex.BoolCellValue(readBool('session4')),
        ex.BoolCellValue(readBool('session5')),
        ex.BoolCellValue(readBool('session6')),
        ex.BoolCellValue(readBool('session7')),
        ex.BoolCellValue(readBool('session8')),
        ex.TextCellValue(_json(progressDoc)),
      ]);

      final sessoes =
          (usuario['sessoes'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      for (final sessaoEntry in sessoes.entries) {
        final sessaoId = sessaoEntry.key;
        final sessao =
            (sessaoEntry.value as Map<String, dynamic>?) ?? <String, dynamic>{};

        sessionsSheet.appendRow([
          ex.TextCellValue(uid),
          ex.TextCellValue(nome),
          ex.TextCellValue(cpf),
          ex.TextCellValue(email),
          ex.TextCellValue(groupId),
          ex.TextCellValue(groupName),
          ex.TextCellValue(_nomesSessoesAmigaveis[sessaoId] ?? sessaoId),
          ex.IntCellValue((sessao['vezesFinalizada'] as num?)?.toInt() ?? 0),
          ex.IntCellValue(
              (sessao['vezesFinalizadaPorConclusao'] as num?)?.toInt() ?? 0),
          ex.IntCellValue(
              (sessao['tarefasCompletasTotal'] as num?)?.toInt() ?? 0),
          ex.IntCellValue(
              (sessao['tarefasParciaisTotal'] as num?)?.toInt() ?? 0),
          ex.TextCellValue(_json(sessao['cliques'] ?? {})),
          ex.TextCellValue(_json(sessao['conclusoesPorItemId'] ?? {})),
          ex.TextCellValue(_json(sessao['parciaisPorItemId'] ?? {})),
        ]);
      }

      final taskEvents = (usuario['taskEvents'] as List?) ?? const [];
      for (final evAny in taskEvents) {
        final ev = Map<String, dynamic>.from(evAny as Map);
        eventsSheet.appendRow([
          ex.TextCellValue(uid),
          ex.TextCellValue(nome),
          ex.TextCellValue(cpf),
          ex.TextCellValue(email),
          ex.TextCellValue(groupId),
          ex.TextCellValue(groupName),
          ex.TextCellValue((ev['id'] ?? '').toString()),
          ex.TextCellValue((ev['eventType'] ?? '').toString()),
          ex.TextCellValue(_isoOrEmpty(ev['createdAt'])),
          ex.TextCellValue((ev['sessaoId'] ?? '').toString()),
          ex.TextCellValue((ev['tipo'] ?? '').toString()),
          ex.TextCellValue((ev['itemId'] ?? '').toString()),
          ex.BoolCellValue((ev['isSupplementary'] as bool?) ?? false),
          ex.TextCellValue((ev['title'] ?? '').toString()),
          ex.TextCellValue((ev['path'] ?? '').toString()),
          ex.TextCellValue((ev['positionSeconds'] ?? '').toString()),
          ex.TextCellValue((ev['positionMinute'] ?? '').toString()),
          ex.TextCellValue((ev['durationSeconds'] ?? '').toString()),
          ex.TextCellValue((ev['mode'] ?? '').toString()),
        ]);
      }
    }

    final bytes = excel.encode() ?? <int>[];
    return _fileDataSource.writeBytesToDocuments(
      fileName: fileName,
      bytes: bytes,
    );
  }
}
