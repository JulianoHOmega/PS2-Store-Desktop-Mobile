import 'package:flutter_test/flutter_test.dart';
import 'package:ps2_store/result_presentation.dart';

void main() {
  test('remove tags HTML e entidades comuns', () {
    expect(ResultPresentation.cleanDescription('<div>OPL &amp; PS2</div>'), 'OPL & PS2');
  });
  test('reconhece ISO e origem', () {
    expect(ResultPresentation.format('https://example.org/game.iso', 'Jogo'), 'ISO');
    expect(ResultPresentation.source('Internet Archive', ''), 'Internet Archive');
  });
  test('categoriza capas antes de launchers', () {
    expect(ResultPresentation.category('OPL Cover Art', '', 'Launchers'), 'Capas e artes');
  });
}
