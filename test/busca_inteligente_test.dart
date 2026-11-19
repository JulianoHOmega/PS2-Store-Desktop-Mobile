import 'package:flutter_test/flutter_test.dart';
import 'package:ps2_store/busca_inteligente.dart';

void main() {
  test('erros de digitacao e palavras omitidas', () {
    expect(BuscaInteligente.corrigirConsulta('gos of war'), 'God of War');
    expect(BuscaInteligente.corrigirConsulta('shadow of colossus'), 'Shadow of the Colossus');
    expect(BuscaInteligente.corrigirConsulta('shadw of the colossus'), 'Shadow of the Colossus');
    expect(BuscaInteligente.pontuacao('resident evl 4', 'Resident Evil 4'), greaterThan(0.65));
  });
  test('sem falso positivo para consulta desconhecida', () {
    expect(BuscaInteligente.corrigirConsulta('minha pesquisa especial'), 'minha pesquisa especial');
  });
}
