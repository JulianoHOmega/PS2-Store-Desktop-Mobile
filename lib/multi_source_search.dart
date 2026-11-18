import 'dart:convert';
import 'dart:io';
import 'package:xml/xml.dart';
import 'github_search.dart';
import 'search_quality.dart';
import 'site_index_search.dart';

/// Public APIs only. A result is not a compatibility, safety or rights check.
class MultiSourceSearch {
  static final extensions = RegExp(r'\.(elf|iso|zip|7z|rar)$', caseSensitive: false);

  Future<dynamic> _json(HttpClient client, Uri uri) async {
    final request = await client.getUrl(uri).timeout(const Duration(seconds: 15));
    request.headers.set(HttpHeaders.userAgentHeader, 'PS2Store/1.0');
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close().timeout(const Duration(seconds: 20));
    final body = await utf8.decoder.bind(response).join().timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw HttpException('${uri.host}: HTTP ${response.statusCode}');
    return jsonDecode(body);
  }

  bool _validUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }

  Future<List<GitHubResult>> search(String term) async {
    final query = term.trim().isEmpty ? 'OPL' : term.trim();
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
    final results = <GitHubResult>[];
    try {
      // Independent providers: a failure in one must not discard the other.
      await Future.wait([_github(client, query, results), _gitlab(client, query, results), _archive(client, query, results), _sourceForge(client, query, results), _codeberg(client, query, results), _additionalSites(query, results)]);
      final seen = <String>{};
      results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
      // One visible card per project; releases/assets from the same project do not flood the screen.
      return results.where((r) {
        final key = r.projectUrl.toLowerCase().replaceAll(RegExp(r'/+$'), '');
        return seen.add(key.isEmpty ? r.downloadUrl.toLowerCase() : key);
      }).toList();
    } finally {
      client.close(force: true);
    }
  }


  Future<void> _additionalSites(String query, List<GitHubResult> out) async {
    try { out.addAll(await SiteIndexSearch().search(query)); }
    catch (_) { /* Other providers remain available. */ }
  }

  Future<String> _text(HttpClient client, Uri uri) async {
    final request = await client.getUrl(uri).timeout(const Duration(seconds: 12));
    request.headers.set(HttpHeaders.userAgentHeader, 'PS2Store/1.1 (public file index)');
    final response = await request.close().timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw HttpException('HTTP ${response.statusCode}');
    return utf8.decoder.bind(response).join().timeout(const Duration(seconds: 20));
  }

  /// Internet Archive: public advanced search plus per-item metadata for real files.
  Future<void> _archive(HttpClient client, String query, List<GitHubResult> out) async {
    try {
      final clean = query.replaceAll(RegExp(r'[^\w\s.-]'), ' ').trim();
      final data = await _json(client, Uri.https('archive.org', '/advancedsearch.php', {
        'q': '($clean) AND mediatype:(software)',
        'fl[]': 'identifier', 'rows': '45', 'page': '1', 'output': 'json',
      })) as Map<String, dynamic>;
      final docs = ((data['response'] as Map?)?['docs'] as List?) ?? [];
      for (final raw in docs.take(30)) {
        try {
          final id = (raw as Map)['identifier']?.toString() ?? '';
          if (!RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(id)) continue;
          final metadata = await _json(client, Uri.https('archive.org', '/metadata/$id')) as Map<String, dynamic>;
          final files = (metadata['files'] as List?) ?? [];
          final itemMeta = (metadata['metadata'] as Map?) ?? {};
          for (final f in files) {
            if (f is! Map) continue;
            final filename = f['name']?.toString() ?? '';
            if (!extensions.hasMatch(filename)) continue;
            final url = Uri.https('archive.org', '/download/$id/$filename').toString();
            final title = itemMeta['title']?.toString() ?? id;
            final desc = itemMeta['description']?.toString() ?? 'Arquivo publico no Internet Archive';
            out.add(GitHubResult(id: 'archive/$id/$filename', title: '$title — $filename',
              description: desc.length > 250 ? desc.substring(0, 250) : desc,
              version: 'Arquivo', license: 'Nao verificada', downloadUrl: url,
              projectUrl: 'https://archive.org/details/$id',
              sizeBytes: int.tryParse(f['size']?.toString() ?? '') ?? 0,
              category: SearchQuality.category(title, desc), developer: 'Internet Archive • $id',
              relevanceScore: SearchQuality.score(title, desc, filename, query)));
            break;
          }
        } catch (_) { /* An item can be unavailable independently. */ }
      }
    } catch (_) { /* The remaining sources are still usable. */ }
  }

  /// SourceForge public directory and per-project RSS feeds. No API key required.
  /// SourceForge may change its HTML or block automated requests; fail gracefully.
  Future<void> _sourceForge(HttpClient client, String query, List<GitHubResult> out) async {
    try {
      final html = await _text(client, Uri.https('sourceforge.net', '/directory/', {'q': query}));
      final projects = <String>{};
      for (final match in RegExp(r"""href=["'](?:https://sourceforge\.net)?/projects/([a-zA-Z0-9_-]+)/""", caseSensitive: false).allMatches(html)) {
        projects.add(match.group(1)!);
        if (projects.length >= 12) break;
      }
      for (final slug in projects) {
        try {
          final xmlText = await _text(client, Uri.https('sourceforge.net', '/projects/$slug/rss', {'path': '/'}));
          final doc = XmlDocument.parse(xmlText);
          for (final item in doc.findAllElements('item').take(12)) {
            final link = item.getElement('link')?.innerText.trim() ?? '';
            final name = item.getElement('title')?.innerText.trim() ?? '';
            final filename = Uri.tryParse(link)?.pathSegments.where((e) => e.isNotEmpty).lastOrNull ?? '';
            if (!extensions.hasMatch(filename) && !extensions.hasMatch(name)) continue;
            if (!_validUrl(link)) continue;
            out.add(GitHubResult(id: 'sourceforge/$slug/$link', title: '$slug — ${name.isEmpty ? filename : name}',
              description: 'Arquivo publicado no SourceForge; nao verificado', version: 'Arquivo',
              license: 'Nao verificada', downloadUrl: link,
              projectUrl: 'https://sourceforge.net/projects/$slug/', sizeBytes: 0,
              category: SearchQuality.category(slug, name), developer: 'SourceForge • $slug',
              relevanceScore: SearchQuality.score(slug, name, filename, query)));
            break;
          }
        } catch (_) { /* Feed unavailable. */ }
      }
    } catch (_) { /* Directory unavailable. */ }
  }

  /// Codeberg: public Forgejo repository search and release assets.
  /// Projects without releases are ignored; each provider fails independently.
  Future<void> _codeberg(HttpClient client, String query, List<GitHubResult> out) async {
    try {
      final data = await _json(client, Uri.https('codeberg.org', '/api/v1/repos/search', {
        'q': query, 'limit': '25',
      })) as Map<String, dynamic>;
      final repos = (data['data'] as List?) ?? [];
      for (final raw in repos.take(20)) {
        if (raw is! Map) continue;
        final fullName = raw['full_name']?.toString() ?? '';
        if (!RegExp(r'^[\w.-]+/[\w.-]+$').hasMatch(fullName)) continue;
        try {
          final releases = await _json(client, Uri.https('codeberg.org', '/api/v1/repos/$fullName/releases', {'limit': '5'})) as List;
          for (final release in releases) {
            if (release is! Map) continue;
            for (final asset in (release['assets'] as List?) ?? []) {
              if (asset is! Map) continue;
              final filename = asset['name']?.toString() ?? '';
              final url = asset['browser_download_url']?.toString() ?? '';
              if (!extensions.hasMatch(filename) || !_validUrl(url)) continue;
              final description = raw['description']?.toString() ?? '';
              out.add(GitHubResult(
                id: 'codeberg/$fullName/$filename', title: '$fullName — $filename',
                description: description, version: release['tag_name']?.toString() ?? 'Arquivo',
                license: 'Nao verificada', downloadUrl: url,
                projectUrl: raw['html_url']?.toString() ?? 'https://codeberg.org/$fullName',
                sizeBytes: (asset['size'] as num?)?.toInt() ?? 0,
                category: SearchQuality.category(fullName, description),
                developer: 'Codeberg • $fullName',
                relevanceScore: SearchQuality.score(fullName, description, filename, query),
              ));
            }
          }
        } catch (_) { /* Repositorio sem releases acessiveis. */ }
      }
    } catch (_) { /* A pesquisa nas outras fontes continua funcionando. */ }
  }

  Future<void> _github(HttpClient client, String query, List<GitHubResult> out) async {
    try {
      final data = await _json(client, Uri.https('api.github.com', '/search/repositories', {
        'q': query, 'per_page': '35', 'sort': 'best-match',
      })) as Map<String, dynamic>;
      for (final raw in (data['items'] as List<dynamic>? ?? []).take(20)) {
        final repo = raw as Map<String, dynamic>;
        final name = repo['full_name']?.toString() ?? '';
        if (!RegExp(r'^[\w.-]+/[\w.-]+$').hasMatch(name)) continue;
        try {
          final releases = await _json(client, Uri.https('api.github.com', '/repos/$name/releases', {'per_page': '3'})) as List<dynamic>;
          for (final item in releases) {
            final release = item as Map<String, dynamic>;
            for (final rawAsset in (release['assets'] as List<dynamic>? ?? [])) {
              final asset = rawAsset as Map<String, dynamic>;
              final filename = asset['name']?.toString() ?? '';
              final url = asset['browser_download_url']?.toString() ?? '';
              if (!extensions.hasMatch(filename) || !_validUrl(url)) continue;
              out.add(GitHubResult(
                id: 'github/$name/$filename', title: '$name — $filename',
                description: repo['description']?.toString() ?? 'Arquivo publicado no GitHub',
                version: release['tag_name']?.toString() ?? 'Nao informada',
                license: (repo['license'] is Map ? repo['license']['spdx_id']?.toString() : null) ?? 'Nao informada',
                downloadUrl: url, projectUrl: repo['html_url']?.toString() ?? '',
                sizeBytes: (asset['size'] as num?)?.toInt() ?? 0,
                category: SearchQuality.category(name, repo['description']?.toString() ?? ''),
                developer: 'GitHub • ${repo['owner']?['login'] ?? 'desconhecido'}',
                relevanceScore: SearchQuality.score(name, repo['description']?.toString() ?? '', '', query),
              ));
            }
          }
        } catch (_) { /* Repositorios sem releases ou limite da API. */ }
      }
    } catch (_) { /* A outra fonte continua funcionando. */ }
  }

  Future<void> _gitlab(HttpClient client, String query, List<GitHubResult> out) async {
    try {
      final projects = await _json(client, Uri.https('gitlab.com', '/api/v4/projects', {
        'search': query, 'simple': 'true', 'per_page': '20',
      })) as List<dynamic>;
      for (final raw in projects.take(15)) {
        final project = raw as Map<String, dynamic>;
        final id = project['id'];
        if (id is! num) continue;
        try {
          final releases = await _json(client, Uri.https('gitlab.com', '/api/v4/projects/${id.toInt()}/releases', {'per_page': '3'})) as List<dynamic>;
          for (final rawRelease in releases) {
            final release = rawRelease as Map<String, dynamic>;
            final links = (release['assets'] as Map<String, dynamic>?)?['links'] as List<dynamic>? ?? [];
            for (final rawLink in links) {
              final link = rawLink as Map<String, dynamic>;
              final url = link['direct_asset_url']?.toString() ?? link['url']?.toString() ?? '';
              final filename = Uri.tryParse(url)?.pathSegments.lastOrNull ?? '';
              if (!extensions.hasMatch(filename) || !_validUrl(url)) continue;
              final name = project['name']?.toString() ?? 'Projeto';
              out.add(GitHubResult(
                id: 'gitlab/$id/$url', title: '$name — $filename',
                description: project['description']?.toString() ?? 'Arquivo publicado no GitLab',
                version: release['tag_name']?.toString() ?? 'Nao informada',
                license: 'Nao informada', downloadUrl: url,
                projectUrl: project['web_url']?.toString() ?? '', sizeBytes: 0,
                category: SearchQuality.category(name, project['description']?.toString() ?? ''),
                developer: 'GitLab • ${project['path_with_namespace'] ?? name}',
                relevanceScore: SearchQuality.score(name, project['description']?.toString() ?? '', '', query),
              ));
            }
          }
        } catch (_) { /* Sem releases publicos. */ }
      }
    } catch (_) { /* A outra fonte continua funcionando. */ }
  }
}
