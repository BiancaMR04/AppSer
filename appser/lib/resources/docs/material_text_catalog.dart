class MaterialTextCatalog {
  static String? forMaterial({
    required int sessionNumber,
    required String normalizedTitle,
    required String normalizedPdfTitle,
  }) {
    final title = normalizedTitle.trim();
    final pdfTitle = normalizedPdfTitle.trim();

    final isListaNecessidades = sessionNumber == 4 &&
        (title.contains('lista de necessidades') ||
            pdfTitle.contains('lista de necessidades'));

    final isPoemaCasaHospedes = sessionNumber == 5 &&
        (title.contains('casa de hÃ³spedes') ||
            title.contains('casa de hospedes') ||
            pdfTitle.contains('casa de hÃ³spedes') ||
            pdfTitle.contains('casa de hospedes'));

    final isMovimentosMindfulness = sessionNumber == 5 &&
        (title.contains('movimentos mindfulness') ||
            pdfTitle.contains('movimentos mindfulness'));

    final isPreencherSessao = sessionNumber == 7 &&
        (title.contains('preencher na sess') ||
            pdfTitle.contains('preencher na sess'));

    if (isListaNecessidades) return _sessao4ListaNecessidades;
    if (isPoemaCasaHospedes) return _sessao5PoemaCasaHospedes;
    if (isMovimentosMindfulness) return _sessao5MovimentosMindfulness;
    if (isPreencherSessao) return _sessao7PreencherSessao;

    return null;
  }

  static const String _sessao4ListaNecessidades = '''
LISTA DE NECESSIDADES HUMANAS UNIVERSAIS
Essa lista Ã© um compilado, revisado pelo Instituto CNV Brasil, das listas de distintos autores da CNV, incluindo Marshall Rosenberg.

HONESTIDADE
AUTENTICIDADE
INTEGRIDADE
PRESENÃ‡A
AUTONOMIA
ESCOLHA
LIBERDADE
ESPAÃ‡O
ESPONTANEIDADE
EXPRESSÃƒO
SIGNIFICADO
COMPREENSÃƒO
CELEBRAÃ‡ÃƒO
CLAREZA
CONTRIBUIÃ‡ÃƒO
SENTIDO
LUTO
INSPIRAÃ‡ÃƒO
REALIZAÃ‡ÃƒO
EVOLUÃ‡ÃƒO
ESPERANÃ‡A
APRENDIZADO
DESAFIOS
DESCOBERTA
CRIATIVIDADE
VALORIZAÃ‡ÃƒO
CRESCIMENTO
CONEXÃƒO
EMPATIA
ACEITAÃ‡ÃƒO
PERTENCIMENTO
COOPERAÃ‡ÃƒO
COMUNICAÃ‡ÃƒO
INTERDEPENDÃŠNCIA
COMPROMETIMENTO
COERÃŠNCIA
RECONHECIMENTO
RESPEITO
SEGURANÃ‡A
ESTABILIDADE
APOIO
SUPORTE
AFETO
CONFORTO
SUSTENTABILIDADE
PROTEÃ‡ÃƒO
PAZ
BELEZA
COMUNHÃƒO
BEM-ESTAR
EQUIDADE
HARMONIA
INSPIRAÃ‡ÃƒO
ORDEM
EXPRESSÃƒO ESPIRITUAL
LAZER
DIVERSÃƒO
HUMOR
FACILIDADE
VARIEDADE
AR
ÃGUA
ALIMENTO
MOVIMENTO
DESCANSO/SONO
EXPRESSÃƒO SEXUAL
ABRIGO
TOQUE
SAÃšDE

Pode ser que vocÃª reconheÃ§a uma necessidade que nÃ£o estÃ¡ nesta lista, lhe convidamos a sempre buscar ir Ã  fundo e ir se perguntando â€œAo conseguir isso, o que estarei ganhando?â€ Desta forma vocÃª vai encontrando a necessidade central do momento.
Fonte: www.institutocnvbrasil.com.br
''';

  static const String _sessao5PoemaCasaHospedes = '''
Poema
CASA DE HÃ“SPEDES
â€œO ser humano Ã© uma casa de hÃ³spedes.
Toda manhÃ£ uma nova visita.
Uma alegria, uma depressÃ£o, uma maldade,
Um momento de consciÃªncia aparece,
Como visitante inesperado.

Receba bem e entretenha a todos!
Mesmo que seja uma multidÃ£o de mÃ¡goas
Que varrem violentamente sua casa
E a esvaziam de sua mobÃ­lia.

Ainda assim, trate cada hÃ³spede honrosamente.
Ele pode o estar limpando
Para alguma nova alegria.
O pensamento sombrio, a vergonha, a malÃ­cia,
Receba-os Ã  porta rindo.
E convide-os a entrar.
Seja grato pelo que vier,
Porque cada um foi enviado
Como um guia do alÃ©m.â€
Rumi
''';

  static const String _sessao5MovimentosMindfulness = '''
POSTURAS E MOVIMENTOS MINDFUL

Posi\u00E7\u00E3o da montanha
Posicionar os p\u00E9s na largura do quadril, coluna reta, joelhos destravados, ombros relaxados e c\u00F3ccix ligeiramente abaixado. Quando voc\u00EA inspirar, levantar os bra\u00E7os e quando expirar volte-os para baixo pela lateral observando o peso dos bra\u00E7os, at\u00E9 alcan\u00E7ar os quadris.

"Tirando uma camiseta"
Na inspira\u00E7\u00E3o, v\u00E1 movendo seus bra\u00E7os cruzados para cima, como se estivesse tirando uma camiseta e na expira\u00E7\u00E3o v\u00E1 terminando o movimento.

Tirando uma camiseta ao contr\u00E1rio
Na inspira\u00E7\u00E3o v\u00E1 subindo os bra\u00E7os pela lateral do corpo e na expira\u00E7\u00E3o cruzando-os \u00E0 frente como um 'x'.

Colhendo uma fruta
Inspirando v\u00E1 subindo o bra\u00E7o como se estivesse colhendo uma fruta de uma \u00E1rvore, esticando um bra\u00E7o para alcan\u00E7ar, fazendo um alongamento por alguns segundos e notando o que acontece com a respira\u00E7\u00E3o. Deixe-a fluir constantemente. Expirando v\u00E1 descendo lentamente o bra\u00E7o, notando se h\u00E1 diferen\u00E7a entre um bra\u00E7o e outro. Fa\u00E7a com o outro bra\u00E7o.

Dobrar para frente
A partir da posi\u00E7\u00E3o da montanha, dobre seus joelhos se precisar, e dobre seu corpo para frente, deixando suas m\u00E3os penduradas em dire\u00E7\u00E3o ao ch\u00E3o ou segure os cotovelos opostos, somente deixe o corpo pendurado como uma boneca de pano, enquanto voc\u00EA respira at\u00E9 as costas. Sinta-se livre para dobrar os joelhos o quanto for necess\u00E1rio. Depois de alguns minutos, desenrole seu corpo at\u00E9 ficar de p\u00E9. Fa\u00E7a isso bem devagar, uma v\u00E9rtebra de cada vez.

Posi\u00E7\u00E3o de descanso final
Complete sua pr\u00E1tica de movimentos descansando sua coluna no solo, com seus bra\u00E7os ao lado, mas um pouco longe do corpo, palmas das m\u00E3os viradas para cima, e os p\u00E9s ca\u00EDdos para os lados. Permita que o peso do seu corpo fique todo no ch\u00E3o e mantenha sua respira\u00E7\u00E3o natural. Fique nesta posi\u00E7\u00E3o por pelo menos 5 minutos, permanecendo presente e consciente sobre a experi\u00EAncia do seu corpo e sua mente.
''';

  static const String _sessao7PreencherSessao = '''
PLANILHA DE ATIVIDADES DI\u00C1RIAS

Liste atividades, pessoas e situa\u00E7\u00F5es que voc\u00EA associe com o estresse e emo\u00E7\u00F5es desafiadoras, ou que aumentem suas d\u00FAvidas em rela\u00E7\u00E3o a si mesmo. Descreva como voc\u00EA normalmente se sente quando se envolve nessas atividades.

Liste atividades, pessoas e situa\u00E7\u00F5es que voc\u00EA associe com prazer e que aumentem a sua autoconfian\u00E7a em rela\u00E7\u00E3o a si mesmo. Perceba como normalmente se sente quando se envolve nessas atividades.
''';
}
