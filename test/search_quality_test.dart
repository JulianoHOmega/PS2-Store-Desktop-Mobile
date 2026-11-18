import 'package:flutter_test/flutter_test.dart';
import 'package:ps2_store/search_quality.dart';

void main() {
  test('prioriza repositorios com contexto PS2', () {
    expect(SearchQuality.relevant('ps2-homebrew', 'Ferramenta para PS2', ''), isTrue);
    expect(SearchQuality.relevant('desktop-client', 'Um cliente de desktop', ''), isFalse);
  });
  test('categorias sao heuristicas', () {
    expect(SearchQuality.category('Open PS2 Loader', ''), 'Launchers');
    expect(SearchQuality.category('PS2 File Manager', ''), 'Arquivos');
  });
  test('busca por nome aumenta relevancia', () {
    expect(SearchQuality.score('OPL', 'PS2 homebrew', '', 'OPL'),
      greaterThan(SearchQuality.score('outro', 'PS2 homebrew', '', 'OPL')));
  });
}
