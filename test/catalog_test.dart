import 'package:flutter_test/flutter_test.dart';
import 'package:ps2_store/main.dart';

void main() {
  test('Converte um item do catalogo corretamente', () {
    final app = StoreApp.fromJson({
      'id': 'demo',
      'title': 'Aplicativo demonstrativo',
      'category': 'Utilitarios',
      'download_url': 'https://example.org/app.elf',
    });
    expect(app.id, 'demo');
    expect(app.title, 'Aplicativo demonstrativo');
    expect(app.downloadUrl, 'https://example.org/app.elf');
  });
}
