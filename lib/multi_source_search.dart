import 'dart:convert';
import 'dart:io';
import 'github_search.dart';
import 'search_quality.dart';

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
      await Future.wait([_github(client, query, results), _gitlab(client, query, results)]);
      final seen = <String>{};
      results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
      return results.where((r) => seen.add(r.downloadUrl.toLowerCase())).toList();
    } finally {
      client.close(force: true);
    }
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
