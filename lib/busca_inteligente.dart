/// Busca aproximada para títulos de jogos. Sem dependências externas.
class BuscaInteligente {
  static const _acentos = {
    'á':'a','à':'a','â':'a','ã':'a','ä':'a','é':'e','ê':'e','è':'e',
    'ë':'e','í':'i','ì':'i','î':'i','ï':'i','ó':'o','ò':'o','ô':'o',
    'õ':'o','ö':'o','ú':'u','ù':'u','û':'u','ü':'u','ç':'c','ñ':'n'
  };

  static String normalizar(String texto) {
    final minusculo = texto.toLowerCase().split('').map((c) => _acentos[c] ?? c).join();
    return minusculo.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static int _distancia(String a, String b) {
    var anterior = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final atual = List<int>.filled(b.length + 1, 0)..[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final custo = a[i - 1] == b[j - 1] ? 0 : 1;
        atual[j] = [atual[j - 1] + 1, anterior[j] + 1, anterior[j - 1] + custo].reduce((x, y) => x < y ? x : y);
      }
      anterior = atual;
    }
    return anterior[b.length];
  }

  static bool _parecido(String termo, String palavra) {
    if (termo == palavra) return true;
    if (termo.length >= 3 && palavra.startsWith(termo)) return true;
    final limite = termo.length <= 2 ? 0 : termo.length <= 6 ? 1 : 2;
    return _distancia(termo, palavra) <= limite;
  }

  static double pontuacao(String consulta, String titulo) {
    final q = normalizar(consulta);
    final t = normalizar(titulo);
    if (q.isEmpty || t.isEmpty) return 0;
    if (q == t) return 1;
    if (t.contains(q)) return 0.96;
    final termos = q.split(' ');
    final palavras = t.split(' ');
    final usados = <int>{};
    var acertos = 0;
    for (final termo in termos) {
      var indice = -1;
      for (var i = 0; i < palavras.length; i++) {
        if (usados.contains(i) || !_parecido(termo, palavras[i])) continue;
        if (indice < 0 || _distancia(termo, palavras[i]) < _distancia(termo, palavras[indice])) indice = i;
        if (termo == palavras[i]) break;
      }
      if (indice >= 0) { usados.add(indice); acertos++; }
    }
    // Exige todos os termos para evitar resultados não relacionados.
    if (acertos != termos.length) return 0;
    return 0.85 - (palavras.length - termos.length).abs() * 0.015;
  }

  /// Corrige consultas quando ha um titulo conhecido muito proximo.
  /// Nao presume que um resultado remoto exista ou que o arquivo seja autorizado.
  static const titulosConhecidos = <String>[
    'God of War', 'God of War II', 'Shadow of the Colossus',
    'Resident Evil 4', 'Grand Theft Auto San Andreas',
    'Metal Gear Solid 3', 'Final Fantasy X', 'Silent Hill 2',
  ];

  static String corrigirConsulta(String consulta) {
    final q = normalizar(consulta);
    if (q.isEmpty) return consulta;
    String? melhor;
    var nota = 0.0;
    for (final titulo in titulosConhecidos) {
      final atual = pontuacao(consulta, titulo);
      if (atual > nota) { nota = atual; melhor = titulo; }
    }
    // So corrige consultas com correspondencia forte; outras seguem intactas.
    return nota >= 0.78 ? melhor! : consulta;
  }

  /// Retorna itens originais, ordenados por relevância.
  static List<T> buscar<T>(Iterable<T> itens, String consulta, String Function(T) titulo) {
    if (normalizar(consulta).isEmpty) return [];
    final encontrados = <({T item, double nota, int ordem})>[];
    var ordem = 0;
    for (final item in itens) {
      final nota = pontuacao(consulta, titulo(item));
      if (nota >= 0.65) encontrados.add((item: item, nota: nota, ordem: ordem));
      ordem++;
    }
    encontrados.sort((a, b) {
      final cmp = b.nota.compareTo(a.nota);
      return cmp != 0 ? cmp : a.ordem.compareTo(b.ordem);
    });
    return encontrados.map((e) => e.item).toList();
  }
}
