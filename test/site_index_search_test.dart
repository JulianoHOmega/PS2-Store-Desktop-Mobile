import 'package:flutter_test/flutter_test.dart';
import 'package:ps2_store/site_index_search.dart';

void main() {
  test('site catalog pages are not presented as direct downloads', () {
    final items = SiteIndexSearch.extract(
      '<a href="/ps2/opl-guide">OPL Guide</a><a href="/files/OPL.zip">OPL ZIP</a>',
      Uri.parse('https://example.com/'), 'OPL', 'Exemplo');
    expect(items.length, 2);
    expect(items.first.downloadUrl, isEmpty);
    expect(items.first.projectUrl, contains('opl-guide'));
    expect(items.last.downloadUrl, endsWith('OPL.zip'));
  });
  test('unrelated external links and irrelevant titles are discarded', () {
    final items = SiteIndexSearch.extract(
      '<a href="https://elsewhere.com/opl.zip">OPL ZIP</a><a href="/other">Other</a>',
      Uri.parse('https://example.com/'), 'OPL', 'Exemplo');
    expect(items, isEmpty);
  });
}
