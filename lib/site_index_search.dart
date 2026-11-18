import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'external_sites.dart';
import 'github_search.dart';
import 'search_quality.dart';

/// Best-effort public HTML indexing. Never invents downloadable files: a page
/// without a direct file URL is presented as a catalog page, not a download.
class SiteIndexSearch {
  static final fileExt = RegExp(r'\.(iso|zip|elf|7z|rar)(?:$|[?#])', caseSensitive: false);
  static final excluded = RegExp(r'^(#|javascript:|mailto:|tel:)', caseSensitive: false);
  static final noise = RegExp(r'^(home|inicio|início|menu|download|downloads|next|previous|voltar|ler mais|read more)$', caseSensitive: false);

  static List<GitHubResult> extract(String markup, Uri page, String query, String siteName) {
    final document = html_parser.parse(markup);
    final matches = <GitHubResult>[];
    final seen = <String>{};
    final words = query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 1).toList();
    if (words.isEmpty) return matches;
    for (final dom.Element link in document.querySelectorAll('a[href]')) {
      final href = link.attributes['href']?.trim() ?? '';
      if (href.isEmpty || excluded.hasMatch(href)) continue;
      final url = page.resolve(href);
      if (url.scheme != 'https' && url.scheme != 'http') continue;
      // Do not follow links to unrelated domains or third-party ad redirects.
      final rootHost = page.host.replaceFirst(RegExp(r'^www\.'), '');
      final targetHost = url.host.replaceFirst(RegExp(r'^www\.'), '');
      if (targetHost != rootHost && !targetHost.endsWith('.$rootHost')) continue;
      final label = link.text.replaceAll(RegExp(r'\s+'), ' ').trim();
      final title = label.isNotEmpty ? label : Uri.decodeComponent(url.pathSegments.isEmpty ? '' : url.pathSegments.last);
      if (title.length < 4 || title.length > 180 || noise.hasMatch(title)) continue;
      final haystack = '$title ${url.path}'.toLowerCase();
      if (!words.any(haystack.contains)) continue;
      if (!seen.add(url.replace(fragment: '').toString())) continue;
      final directFile = fileExt.hasMatch(url.path);
      matches.add(GitHubResult(
        id: 'site/${page.host}/${url.toString()}',
        title: title,
        description: directFile ? 'Arquivo listado em $siteName' : 'Pagina do catalogo de $siteName; abra a pagina para consultar os arquivos.',
        version: directFile ? 'Arquivo' : 'Pagina', license: 'Nao verificada',
        downloadUrl: directFile ? url.toString() : '',
        projectUrl: url.toString(), sizeBytes: 0,
        category: SearchQuality.category(title, ''), developer: siteName,
        relevanceScore: SearchQuality.score(title, url.path, '', query),
      ));
      if (matches.length >= 12) break;
    }
    return matches;
  }

  Future<List<GitHubResult>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    client.maxConnectionsPerHost = 2;
    try {
      final tasks = externalSites.map((site) => _searchSite(client, site, query));
      final batches = await Future.wait(tasks);
      return batches.expand((batch) => batch).toList();
    } finally {
      client.close(force: true);
    }
  }

  Future<List<GitHubResult>> _searchSite(HttpClient client, ExternalSite site, String query) async {
    final base = Uri.parse(site.url);
    // WordPress-style search and the supplied public index page. Sites which
    // reject automated requests simply contribute no results.
    final candidates = <Uri>[
      base.replace(path: '/', queryParameters: {'s': query}),
      base,
    ];
    for (final uri in candidates) {
      try {
        final req = await client.getUrl(uri).timeout(const Duration(seconds: 5));
        req.headers.set(HttpHeaders.userAgentHeader, 'PS2Store/1.5 (public catalog search)');
        req.headers.set(HttpHeaders.acceptHeader, 'text/html');
        final response = await req.close().timeout(const Duration(seconds: 7));
        if (response.statusCode != 200) { await response.drain<void>(); continue; }
        final type = response.headers.contentType?.mimeType ?? '';
        if (type.isNotEmpty && type != 'text/html' && type != 'application/xhtml+xml') {
          await response.drain<void>(); continue;
        }
        final bytes = <int>[];
        await for (final chunk in response.timeout(const Duration(seconds: 7))) {
          bytes.addAll(chunk);
          if (bytes.length > 800000) break;
        }
        final parsed = extract(utf8.decode(bytes, allowMalformed: true), uri, query, site.name);
        if (parsed.isNotEmpty) return parsed;
      } catch (_) { /* Unavailable source is not a fabricated result. */ }
    }
    return [];
  }
}
