import 'package:flutter/material.dart';

enum SessionContentType { audio, video, pdf }

@immutable
class SessionContentItem {
  final String title;
  final String duration;
  final SessionContentType type;
  final String itemId;
  final String path;
  final String viewerTitle;
  final String? downloadPath;

  const SessionContentItem({
    required this.title,
    required this.duration,
    required this.type,
    required this.itemId,
    required this.path,
    required this.viewerTitle,
    this.downloadPath,
  });
}

@immutable
class SessionMaterialItem {
  final String title;
  final String pdfPath;
  final String downloadPath;
  final String pdfTitle;

  const SessionMaterialItem({
    required this.title,
    required this.pdfPath,
    required this.downloadPath,
    required this.pdfTitle,
  });
}

class SessionCatalog {
  static List<SessionContentItem> contentItemsFor(int sessionNumber) {
    return _contentItemsBySession[sessionNumber] ??
        _contentItemsBySession[1] ??
        const <SessionContentItem>[];
  }

  static List<SessionMaterialItem> materialItemsFor(int sessionNumber) {
    return _materialItemsBySession[sessionNumber] ??
        _materialItemsBySession[1] ??
        const <SessionMaterialItem>[];
  }

  static const Map<int, List<SessionContentItem>> _contentItemsBySession = {
    1: [
      SessionContentItem(
        title: '1. Check-in',
        duration: '2:59',
        type: SessionContentType.audio,
        itemId: 'checkin',
        path: 'audios/sessaoum/checkinone.mp3',
        viewerTitle: 'Check-in',
      ),
      SessionContentItem(
        title: '2. Preparação para o exercício "Prática da Uva Passa"',
        duration: '1:05',
        type: SessionContentType.video,
        itemId: 'preparacao_pratica_uva',
        path: 'videos/sessaoum/preparacaouva.mp4',
        viewerTitle: 'Preparação para o exercício "Prática da Uva Passa"',
      ),
      SessionContentItem(
        title: '3. Prática da Uva Passa',
        duration: '12:39',
        type: SessionContentType.video,
        itemId: 'pratica_uva',
        path: 'videos/sessaoum/praticauvapassaum.mp4',
        viewerTitle: 'Prática da Uva Passa',
      ),
      SessionContentItem(
        title: '4. O que é Mindfulness',
        duration: '6:01',
        type: SessionContentType.video,
        itemId: 'oque_e_mindfulness',
        path: 'videos/sessaoum/oquemindfulnessum.mp4',
        viewerTitle: 'O que é Mindfulness',
      ),
      SessionContentItem(
        title: '5. Posturas copy',
        duration: '7:59',
        type: SessionContentType.video,
        itemId: 'posturas_copy',
        path: 'videos/sessaoum/videosposturaum.mp4',
        viewerTitle: 'Posturas copy',
      ),
      SessionContentItem(
        title: '6. Escaneamento corporal',
        duration: '13:33',
        type: SessionContentType.audio,
        itemId: 'escaneamento_corporal',
        path: 'audios/sessaoum/escaneamentoone.mp3',
        viewerTitle: 'Escaneamento corporal',
      ),
      SessionContentItem(
        title: '7. Praticando em Casa',
        duration: '',
        type: SessionContentType.pdf,
        itemId: 'praticando_em_casa',
        path: 'docs/sessaoum/praticandoemcasaum.pdf',
        downloadPath: 'docs/sessaoum/praticandoemcasaum.pdf',
        viewerTitle: 'Praticando em Casa',
      ),
      SessionContentItem(
        title: '8. Check-out',
        duration: '2:49',
        type: SessionContentType.audio,
        itemId: 'checkout',
        path: 'audios/sessaoum/checkoutone.mp3',
        viewerTitle: 'Check-out',
      ),
    ],
    2: [
      SessionContentItem(
        title: '1. Check-in',
        duration: '1:40',
        type: SessionContentType.audio,
        itemId: 'checkin',
        path: 'audios/sessaodois/checkintwo.mp3',
        viewerTitle: 'Check-in',
      ),
      SessionContentItem(
        title: '2. Escaneamento com automassagem',
        duration: '13:38',
        type: SessionContentType.video,
        itemId: 'escaneamento_automassagem',
        path: 'videos/sessaodois/escaneamentodois.mp4',
        viewerTitle: 'Escaneamento com automassagem',
      ),
      SessionContentItem(
        title: '3. Cinco desafios',
        duration: '6:06',
        type: SessionContentType.video,
        itemId: 'cinco_desafios',
        path: 'videos/sessaodois/desafiosdois.mp4',
        viewerTitle: 'Cinco desafios',
      ),
      SessionContentItem(
        title: '4. Andando na rua',
        duration: '9:42',
        type: SessionContentType.video,
        itemId: 'andando_na_rua',
        path: 'videos/sessaodois/andandodois.mp4',
        viewerTitle: 'Andando na rua',
      ),
      SessionContentItem(
        title: '5. Primeiro e segundo sofrimento',
        duration: '9:39',
        type: SessionContentType.video,
        itemId: 'sofrimento_duplo',
        path: 'videos/sessaodois/pssofrimentodois.mp4',
        viewerTitle: 'Primeiro e segundo sofrimento',
      ),
      SessionContentItem(
        title: '6. Montanha',
        duration: '8:35',
        type: SessionContentType.audio,
        itemId: 'montanha',
        path: 'audios/sessaodois/montanha.mp3',
        viewerTitle: 'Montanha',
      ),
      SessionContentItem(
        title: '7. Praticando em Casa',
        duration: '',
        type: SessionContentType.pdf,
        itemId: 'praticando_em_casa',
        path: 'docs/sessaodois/praticandoemcasadois.pdf',
        downloadPath: 'docs/sessaodois/praticandoemcasadois.pdf',
        viewerTitle: 'Praticando em Casa',
      ),
      SessionContentItem(
        title: '8. Check-out',
        duration: '2:56',
        type: SessionContentType.audio,
        itemId: 'checkout',
        path: 'audios/sessaodois/checkouttwo.mp3',
        viewerTitle: 'Check-out',
      ),
    ],
    3: [
      SessionContentItem(
        title: '1. Check-in',
        duration: '3:24',
        type: SessionContentType.audio,
        itemId: 'checkin',
        path: 'audios/sessaotres/checkintres.mp3',
        viewerTitle: 'Check-in',
      ),
      SessionContentItem(
        title: '2. Consciência de ouvir',
        duration: '13:55',
        type: SessionContentType.audio,
        itemId: 'consciencia_ouvir',
        path: 'audios/sessaotres/conscienciatres.mp3',
        viewerTitle: 'Consciência de ouvir',
      ),
      SessionContentItem(
        title: '3. Caminhada mindfulness',
        duration: '13:54',
        type: SessionContentType.audio,
        itemId: 'caminhada_mindfulness',
        path: 'audios/sessaotres/caminhadamindtres.mp3',
        viewerTitle: 'Caminhada mindfulness',
      ),
      SessionContentItem(
        title: '4. Respiração',
        duration: '20:16',
        type: SessionContentType.audio,
        itemId: 'respiracao',
        path: 'audios/sessaotres/respiracaotres.mp3',
        viewerTitle: 'Respiração',
      ),
      SessionContentItem(
        title: '5. Parar Teoria',
        duration: '3:24',
        type: SessionContentType.video,
        itemId: 'parar_teoria',
        path: 'videos/sessaotres/pararteoriatres.mp4',
        viewerTitle: 'Parar Teoria',
      ),
      SessionContentItem(
        title: '6. Parar Áudio',
        duration: '5:12',
        type: SessionContentType.audio,
        itemId: 'parar_audio',
        path: 'audios/sessaotres/pararaudiotres.mp3',
        viewerTitle: 'Parar Áudio',
      ),
      SessionContentItem(
        title: '7. Praticando em Casa',
        duration: '',
        type: SessionContentType.pdf,
        itemId: 'praticando_em_casa',
        path: 'docs/sessaotres/praticandoemcasatres.pdf',
        downloadPath: 'docs/sessaotres/praticandoemcasatres.pdf',
        viewerTitle: 'Praticando em Casa',
      ),
      SessionContentItem(
        title: '8. Check-out',
        duration: '2:06',
        type: SessionContentType.audio,
        itemId: 'checkout',
        path: 'audios/sessaotres/checkouttres.mp3',
        viewerTitle: 'Check-out',
      ),
    ],
    4: [
      SessionContentItem(
        title: '1. Check-in',
        duration: '1:02',
        type: SessionContentType.audio,
        itemId: 'checkin',
        path: 'audios/sessaoquatro/checkinquatro.mp3',
        viewerTitle: 'Check-in',
      ),
      SessionContentItem(
        title: '2. Consciência do Ver',
        duration: '13:57',
        type: SessionContentType.audio,
        itemId: 'consciencia_ver',
        path: 'audios/sessaoquatro/conscienciaquatro.mp3',
        viewerTitle: 'Consciência do Ver',
      ),
      SessionContentItem(
        title: '3. Meditação Sentada',
        duration: '20:52',
        type: SessionContentType.audio,
        itemId: 'meditacao_sentada',
        path: 'audios/sessaoquatro/meditacaosentadaquatro.mp3',
        viewerTitle: 'Meditação Sentada',
      ),
      SessionContentItem(
        title: '4. Lista de gatilhos',
        duration: '8:36',
        type: SessionContentType.video,
        itemId: 'lista_gatilhos',
        path: 'videos/sessaoquatro/listagatilhosquatro.mp4',
        viewerTitle: 'Lista de gatilhos',
      ),
      SessionContentItem(
        title: '5. Falso Refúgio',
        duration: '14:56',
        type: SessionContentType.video,
        itemId: 'falso_refugio',
        path: 'videos/sessaoquatro/falsorefugioquatro.mp4',
        viewerTitle: 'Falso Refúgio',
      ),
      SessionContentItem(
        title: '6. Parar na situação desafiadora',
        duration: '11:08',
        type: SessionContentType.video,
        itemId: 'parar_situacao',
        path: 'videos/sessaoquatro/pararsituacaoquatro.mp4',
        viewerTitle: 'Parar na situação desafiadora',
      ),
      SessionContentItem(
        title: '7. Check-out',
        duration: '1:56',
        type: SessionContentType.audio,
        itemId: 'checkout',
        path: 'audios/sessaoquatro/checkoutquatro.mp3',
        viewerTitle: 'Check-out',
      ),
      SessionContentItem(
        title: '8. Praticando em Casa',
        duration: '',
        type: SessionContentType.pdf,
        itemId: 'praticando_em_casa',
        path: 'docs/sessaoquatro/praticandoemcasaquatro.pdf',
        downloadPath: 'docs/sessaoquatro/praticandoemcasaquatro.pdf',
        viewerTitle: 'Praticando em Casa',
      ),
    ],
    5: [
      SessionContentItem(
        title: '1. Check-in',
        duration: '1:45',
        type: SessionContentType.audio,
        itemId: 'checkin',
        path: 'audios/sessaocinco/checkincinco.mp3',
        viewerTitle: 'Check-in',
      ),
      SessionContentItem(
        title: '2. Meditação Sentada',
        duration: '16:12',
        type: SessionContentType.audio,
        itemId: 'meditacao_sentada',
        path: 'audios/sessaocinco/meditacaosentadacinco.mp3',
        viewerTitle: 'Meditação Sentada',
      ),
      SessionContentItem(
        title: '3. Poema "A Casa de Hóspedes"',
        duration: '',
        type: SessionContentType.pdf,
        itemId: 'poema_casa_hospedes',
        path: 'docs/sessaocinco/poemacasacinco.pdf',
        downloadPath: 'docs/sessaocinco/poemacasacinco.pdf',
        viewerTitle: 'Poema "A Casa de Hóspedes"',
      ),
      SessionContentItem(
        title: '4. Discussão sobre aceitação e emoções',
        duration: '11:34',
        type: SessionContentType.video,
        itemId: 'discussao_aceitacao_emocoes',
        path: 'videos/sessaocinco/discussaocinco.mp4',
        viewerTitle: 'Discusão sobre aceitação e emoções',
      ),
      SessionContentItem(
        title: '5. Revendo os Cinco desafios da Sessão 2',
        duration: '6:06',
        type: SessionContentType.video,
        itemId: 'revisao_cinco_desafios',
        path: 'videos/sessaocinco/revendocinco.mp4',
        viewerTitle: 'Revendo os Cinco desafios da Sessão 2',
      ),
      SessionContentItem(
        title: '6. Movimentos Copy',
        duration: '8:01',
        type: SessionContentType.video,
        itemId: 'movimentos_copy',
        path: 'videos/sessaocinco/movimentoscinco.mp4',
        viewerTitle: 'Movimentos Copy',
      ),
      SessionContentItem(
        title: '7. Movimentos Mindfulness',
        duration: '',
        type: SessionContentType.pdf,
        itemId: 'movimentos_mindfulness',
        path: 'docs/sessaocinco/movimentosmindcinco.pdf',
        downloadPath: 'docs/sessaocinco/movimentosmindcinco.pdf',
        viewerTitle: 'Movimentos Mindfulness',
      ),
      SessionContentItem(
        title: '8. Praticando em Casa',
        duration: '',
        type: SessionContentType.pdf,
        itemId: 'praticando_em_casa',
        path: 'docs/sessaocinco/praticandoemcasacinco.pdf',
        downloadPath: 'docs/sessaocinco/praticandoemcasacinco.pdf',
        viewerTitle: 'Praticando em Casa',
      ),
      SessionContentItem(
        title: '9. Check-out',
        duration: '2:01',
        type: SessionContentType.audio,
        itemId: 'checkout',
        path: 'audios/sessaocinco/checkoutcinco.mp3',
        viewerTitle: 'Check-out',
      ),
    ],
    6: [
      SessionContentItem(
        title: '1. Check-in',
        duration: '1:30',
        type: SessionContentType.audio,
        itemId: 'checkin',
        path: 'audios/sessaoseis/checkinseis.mp3',
        viewerTitle: 'Check-in',
      ),
      SessionContentItem(
        title: '2. Prática dos Pensamentos',
        duration: '14:30',
        type: SessionContentType.audio,
        itemId: 'pratica_pensamentos',
        path: 'audios/sessaoseis/praticadospenseis.mp3',
        viewerTitle: 'Prática dos Pensamentos',
      ),
      SessionContentItem(
        title: '3. Te Recebo Aceito Solto (RAS)',
        duration: '9:46',
        type: SessionContentType.video,
        itemId: 'ras',
        path: 'videos/sessaoseis/rasseis.mp4',
        viewerTitle: 'Te Recebo Aceito Solto (RAS)',
      ),
      SessionContentItem(
        title: '4. Cadeia da reatividade',
        duration: '22:42',
        type: SessionContentType.video,
        itemId: 'cadeira_reatividade',
        path: 'videos/sessaoseis/cadeiaseis.mp4',
        viewerTitle: 'Cadeia da reatividade',
      ),
      SessionContentItem(
        title: '5. Parar Áudio',
        duration: '5:12',
        type: SessionContentType.audio,
        itemId: 'parar_audio',
        path: 'audios/sessaoseis/pararaudioseis.mp3',
        viewerTitle: 'Parar Áudio',
      ),
      SessionContentItem(
        title: '6. Praticando em Casa',
        duration: '',
        type: SessionContentType.pdf,
        itemId: 'praticando_em_casa',
        path: 'docs/sessaoseis/praticandoemcasaseis.pdf',
        downloadPath: 'docs/sessaoseis/praticandoemcasaseis.pdf',
        viewerTitle: 'Praticando em Casa',
      ),
      SessionContentItem(
        title: '7. Check-out',
        duration: '2:55',
        type: SessionContentType.audio,
        itemId: 'checkout',
        path: 'audios/sessaoseis/checkoutseis.mp3',
        viewerTitle: 'Check-out',
      ),
    ],
    7: [
      SessionContentItem(
        title: '1. Check-in',
        duration: '1:28',
        type: SessionContentType.audio,
        itemId: 'checkin',
        path: 'audios/sessaosete/checkinsete.mp3',
        viewerTitle: 'Check-in',
      ),
      SessionContentItem(
        title: '2. Prática Bondade Amorosa',
        duration: '12:36',
        type: SessionContentType.video,
        itemId: 'bondade_amorosa',
        path: 'videos/sessaosete/bondadesete.mp4',
        viewerTitle: 'Prática Bondade Amorosa',
      ),
      SessionContentItem(
        title: '3. Lista de atividades diárias',
        duration: '6:20',
        type: SessionContentType.video,
        itemId: 'lista_atividades_diarias',
        path: 'videos/sessaosete/atividadessete.mp4',
        viewerTitle: 'Lista de atividades diárias',
      ),
      SessionContentItem(
        title: '4. Visualização Atividades Fortalecedoras',
        duration: '6:37',
        type: SessionContentType.video,
        itemId: 'visualizacao_fortalecedoras',
        path: 'videos/sessaosete/visualizacaosete.mp4',
        viewerTitle: 'Visualização Atividades Fortalecedoras',
      ),
      SessionContentItem(
        title: '5. Funil da exaustão',
        duration: '11:14',
        type: SessionContentType.video,
        itemId: 'funil_exaustao',
        path: 'videos/sessaosete/funilsete.mp4',
        viewerTitle: 'Funil da exaustão',
      ),
      SessionContentItem(
        title: '6. Parar Áudio',
        duration: '5:12',
        type: SessionContentType.audio,
        itemId: 'parar_audio',
        path: 'audios/sessaosete/pararaudiosete.mp3',
        viewerTitle: 'Parar Áudio',
      ),
      SessionContentItem(
        title: '7. Praticando em Casa',
        duration: '',
        type: SessionContentType.pdf,
        itemId: 'praticando_em_casa',
        path: 'docs/sessaosete/praticandoemcasasete.pdf',
        downloadPath: 'docs/sessaosete/praticandoemcasasete.pdf',
        viewerTitle: 'Praticando em Casa',
      ),
      SessionContentItem(
        title: '8. Check-out',
        duration: '2:08',
        type: SessionContentType.audio,
        itemId: 'checkout',
        path: 'audios/sessaosete/checkoutsete.mp3',
        viewerTitle: 'Check-out',
      ),
    ],
    8: [
      SessionContentItem(
        title: '1. Check-in',
        duration: '2:59',
        type: SessionContentType.audio,
        itemId: 'checkin',
        path: 'audios/sessaooito/checkineight.mp3',
        viewerTitle: 'Check-in',
      ),
      SessionContentItem(
        title: '2. Poema + Suporte e estratégias para prática continuada',
        duration: '24:24',
        type: SessionContentType.video,
        itemId: 'poema_suporte_estrategias',
        path: 'videos/sessaooito/poemaoito.mp4',
        viewerTitle: 'Poema + Suporte e estratégias para prática continuada',
      ),
      SessionContentItem(
        title: '3. Prática da pedra',
        duration: '8:56',
        type: SessionContentType.video,
        itemId: 'pratica_pedra',
        path: 'videos/sessaooito/praticapedraoito.mp4',
        viewerTitle: 'Prática da pedra',
      ),
      SessionContentItem(
        title: '4. Praticando em Casa',
        duration: '',
        type: SessionContentType.pdf,
        itemId: 'praticando_em_casa',
        path: 'docs/sessaooito/praticandoemcasaoito.pdf',
        downloadPath: 'docs/sessaooito/praticandoemcasaoito.pdf',
        viewerTitle: 'Praticando em Casa',
      ),
      SessionContentItem(
        title: '5. Check-out',
        duration: '1:10',
        type: SessionContentType.audio,
        itemId: 'checkout',
        path: 'audios/sessaooito/checkouteight.mp3',
        viewerTitle: 'Check-out',
      ),
    ],
  };

  static const Map<int, List<SessionMaterialItem>> _materialItemsBySession = {
    1: [
      SessionMaterialItem(
        title: 'Apostila Ser Sessão 1',
        pdfPath: 'docs/materiaisum/apostilasersessaoum.docx.pdf',
        downloadPath: 'docs/materiaisum/apostilasersessaoum.docx',
        pdfTitle: 'Apostila Ser Sessão 1',
      ),
      SessionMaterialItem(
        title: 'Mindfulness copy',
        pdfPath: 'docs/materiaisum/mindfulnesscopyum.pdf',
        downloadPath: 'docs/materiaisum/mindfulnesscopyum.pdf',
        pdfTitle: 'Mindfulness copy',
      ),
      SessionMaterialItem(
        title: 'Postura Deitada',
        pdfPath: 'docs/materiaisum/posturadeitadaum.pdf',
        downloadPath: 'docs/materiaisum/posturadeitadaum.pdf',
        pdfTitle: 'Postura Deitada',
      ),
      SessionMaterialItem(
        title: 'Apresentação Sessão 1',
        pdfPath: 'docs/materiaisum/apresentacaosessaoum.pdf',
        downloadPath: 'docs/materiaisum/apresentacaosessaoum.pdf',
        pdfTitle: 'Apresentação Sessão 1',
      ),
    ],
    2: [
      SessionMaterialItem(
        title: 'Apostila Ser Sessão 2',
        pdfPath: 'docs/materiaisdois/apostilasersessaodois.pdf',
        downloadPath: 'docs/materiaisdois/apostilasersessaodois.docx',
        pdfTitle: 'Apostila Ser Sessão 2',
      ),
      SessionMaterialItem(
        title: 'Posturas Sentada',
        pdfPath: 'docs/materiaisdois/posturasentadaum.pdf',
        downloadPath: 'docs/materiaisdois/posturasentadaum.pdf',
        pdfTitle: 'Posturas Sentada',
      ),
      SessionMaterialItem(
        title: 'Apresentação Sessão 2',
        pdfPath: 'docs/materiaisdois/apresentacaosessaodois.pdf',
        downloadPath: 'docs/materiaisdois/apresentacaosessaodois.pdf',
        pdfTitle: 'Apresentação Sessão 2',
      ),
    ],
    3: [
      SessionMaterialItem(
        title: 'Apostila Ser Sessão 3',
        pdfPath: 'docs/materiaistres/apostilasersessaotres.pdf',
        downloadPath: 'docs/materiaistres/apostilasersessaotres.docx',
        pdfTitle: 'Apostila Ser Sessão 3',
      ),
      SessionMaterialItem(
        title: 'Apresentação Sessão 3',
        pdfPath: 'docs/materiaistres/apresentacaosessaotres.pdf',
        downloadPath: 'docs/materiaistres/apresentacaosessaotres.pdf',
        pdfTitle: 'Apresentação Sessão 3',
      ),
    ],
    4: [
      SessionMaterialItem(
        title: 'Apostila Ser Sessão 4',
        pdfPath: 'docs/materiaisquatro/apostilasersessaoquatro.pdf',
        downloadPath: 'docs/materiaisquatro/apostilasersessaoquatro.docx',
        pdfTitle: 'Apostila Ser Sessão 4',
      ),
      SessionMaterialItem(
        title: 'Lista de Necessidades',
        pdfPath: 'docs/materiaisquatro/listadenecessidadequatro.pdf',
        downloadPath: 'docs/materiaisquatro/listadenecessidadequatro.pdf',
        pdfTitle: 'Lista de Necessidades',
      ),
      SessionMaterialItem(
        title: 'Apresentação Sessão 4',
        pdfPath: 'docs/materiaisquatro/sessaoquatro.pdf',
        downloadPath: 'docs/materiaisquatro/sessaoquatro.pdf',
        pdfTitle: 'Apresentação Sessão 4',
      ),
    ],
    5: [
      SessionMaterialItem(
        title: 'Apostila Ser Sessão 5',
        pdfPath: 'docs/materiaiscinco/apostilaserssaocinco.pdf',
        downloadPath: 'docs/materiaiscinco/apostilasersessaocinco.docx',
        pdfTitle: 'Apostila Ser Sessão 5',
      ),
      SessionMaterialItem(
        title: 'Lista de Sentimentos',
        pdfPath: 'docs/materiaiscinco/listadesentimentocinco.pdf',
        downloadPath: 'docs/materiaiscinco/listadesentimentocinco.pdf',
        pdfTitle: 'Lista de Sentimentos',
      ),
      SessionMaterialItem(
        title: 'Apresentação Sessão 5',
        pdfPath: 'docs/materiaiscinco/apresentacaosessaocinco.pdf',
        downloadPath: 'docs/materiaiscinco/apresentacaosessaocinco.pdf',
        pdfTitle: 'Apresentação Sessão 5',
      ),
    ],
    6: [
      SessionMaterialItem(
        title: 'Apostila Ser Sessão 6',
        pdfPath: 'docs/materiaisseis/apostilasessaoseis.pdf',
        downloadPath: 'docs/materiaisseis/apostilasessaoseis.docx',
        pdfTitle: 'Apostila Ser Sessão 6',
      ),
      SessionMaterialItem(
        title: 'Preencher próxima sessão',
        pdfPath: 'docs/materiaisseis/preencherproximaseis.pdf',
        downloadPath: 'docs/materiaisseis/preencherproximaseis.docx',
        pdfTitle: 'Preencher próxima sessão',
      ),
      SessionMaterialItem(
        title: 'Apresentação Sessão 6',
        pdfPath: 'docs/materiaisseis/apresentacaosessaoseis.pdf',
        downloadPath: 'docs/materiaisseis/apresentacaosessaoseis.pdf',
        pdfTitle: 'Apresentação Sessão 6',
      ),
    ],
    7: [
      SessionMaterialItem(
        title: 'Apostila Ser Sessão 7',
        pdfPath: 'docs/materiaissete/apostilasessaosete.pdf',
        downloadPath: 'docs/materiaissete/apostilasessaosete.docx',
        pdfTitle: 'Apostila Ser Sessão 7',
      ),
      SessionMaterialItem(
        title: 'Preencher na sessão',
        pdfPath: 'docs/materiaissete/trazersessaosete.pdf',
        downloadPath: 'docs/materiaissete/trazersessaosete.docx',
        pdfTitle: 'Preencher na sessão',
      ),
      SessionMaterialItem(
        title: 'Apresentação Sessão 7',
        pdfPath: 'docs/materiaissete/apresentacaosessaosete.pdf',
        downloadPath: 'docs/materiaissete/apresentacaosessaosete.pdf',
        pdfTitle: 'Apresentação Sessão 7',
      ),
    ],
    8: [
      SessionMaterialItem(
        title: 'Apostila Ser Sessão 8',
        pdfPath: 'docs/materiaisum/apostilasessaooito.pdf',
        downloadPath: 'docs/materiaisum/apostilasessaooito.docx',
        pdfTitle: 'Apostila Ser Sessão 8',
      ),
      SessionMaterialItem(
        title: 'Apresentação Sessão 8',
        pdfPath: 'docs/materiaisum/apresentacaosessaooito.pdf',
        downloadPath: 'docs/materiaisum/apresentacaosessaooito.pdf',
        pdfTitle: 'Apresentação Sessão 8',
      ),
    ],
  };
}
