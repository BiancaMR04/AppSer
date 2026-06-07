class PraticandoEmCasaTextCatalog {
  static String forSession(int sessionNumber) {
    return _bySession[sessionNumber] ??
        'Texto do "Praticando em Casa" ainda não foi cadastrado para a sessão '
            '$sessionNumber.';
  }

  // Cole aqui o texto do "Praticando em Casa" (Sessão X) como string multilinha.
  // Dica: mantenha títulos e listas usando apenas quebras de linha.
  static const Map<int, String> _bySession = {
    1: _sessao1,
    2: _sessao2,
    3: _sessao3,
    4: _sessao4,
    5: _sessao5,
    6: _sessao6,
    7: _sessao7,
    8: _sessao8,
  };

  static const String _sessao1 = '''
PRATICANDO EM CASA DA SEGUINTE FORMA
Momentos para reflexão
- Lendo o folheto da sessão 1
- Completando a planilha da sessão 1

Momentos para experiência
- Trazendo mindfulness para a vida diária (refeições)
- Praticando escaneamento corporal 1x ao dia

Próxima semana: trazer 5 livros (tamanhos variados)
''';

  static const String _sessao2 = '''
Momentos para reflexão
Lendo o folheto da sessão 2
Completando a planilha da sessão 2

Momentos para experiência
Mindfulness para a vida diária
Explorando e sentindo o toque: calor, suavidade, aspereza etc.
Tocar algum tecido ou sentir o toque de alguma roupa ou corpo
Tocar um bichinho e sentir o toque dele
Sentir o calor do sol na pele

Praticando Escaneamento Corporal e Montanha
''';

  static const String _sessao3 = '''
Momentos para reflexão
Lendo o folheto da sessão3
Completando a planilha da sessão 3

Momentos para experiência
Caminhada mindful ao menos 2x na semana
Meditação da respiração
Mindfulness para a vida diária
PARAR (prática formal e informal)
Explorando diferentes tonalidades nos sons
Diferentes volumes e texturas no som de um trânsito intenso
Fluidez no som de crianças brincando no parque e assim como música as vezes mais alta e as vezes mais baixa etc
Som de pássaros etc

Para a próxima semana:
Providencia um objeto que consiga segurar
''';

  static const String _sessao4 = '''
Momentos para reflexão
Lendo o folheto da sessão 4
Completando a planilha usando PARAR em situações desafiadoras
Completando a planilha de acompanhamento diário de práticas

Momentos para experiência
Meditação Sentada ou escaneamento
PARAR em situações desafiadoras

Mindfulness para a vida diária
Explorando a consciência de ver: diferentes cores, sombras, brilho etc
''';

  static const String _sessao5 = '''
Momentos para reflexão
Lendo o folheto da sessão 5
Completando a planilha da sessão 5

Momentos para experiência
Meditação Sentada
Escaneamento
Movimentos
PARAR em situações desafiadoras ou
Mindfulness para a vida diária
Consciência das emoções e como as mesmas produzem sensações no corpo
''';

  static const String _sessao6 = '''
Momentos para reflexão
Lendo o folheto da sessão 6
Completando a planilha da sessão 6

Momentos para experiência
Escolher meditações que mais se identifica
Ir aumentando tempo
Experimentar praticar sem áudios
PARAR em situações desafiadoras
PARAR durante diferentes momentos do dia
Mindfulness para a vida diária
Consciência dos pensamentos e como nos relacionamos com ele

Para a próxima semana:
Por favor tenham as planilhas de atividades diárias (sessão) à mão e tragam uma folha de papel sulfite e caneta
''';

  static const String _sessao7 = '''
Momentos para reflexão
Lendo o folheto da sessão 7
Completando a planilha da sessão 7

Momentos para experiência
Bondade amorosa
Diário: 3 atividades fortalecedoras
PARAR (experimentar de olhos abertos)
Mindfulness para a vida diária

Observar como você se relaciona com as atividades

Para a próxima semana:
Uma pedra da sua escolha, folhas de papel, caneta e envelope
''';

  static const String _sessao8 = '''
Momentos para reflexão
Explorar links
“Auxiliar na Manutenção da Prática”

Momentos para experiência
Escaneamento Corporal
Montanha
Práticas da Respiração
Meditação Sentada
Movimentos de Mindfulness
Caminhada Mindful
PARAR
Bondade Amorosa
Mindfulness para a vida diária
''';
}
