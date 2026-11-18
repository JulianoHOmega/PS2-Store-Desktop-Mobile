import 'dart:convert';
import 'dart:io';

/// Pesquisa limitada a repositorios publicos; nao e um indice de toda a web.
class GitHubResult {
  final String id, title, description, version, license, downloadUrl;
  const GitHubResult({required this.id, required this.title, required this.description,
    required this.version, required this.license, required this.downloadUrl});
}

class GitHubHomebrewSearch {
  Future<dynamic> _get(HttpClient client, Uri uri) async {
    final req = await client.getUrl(uri).timeout(const Duration(seconds: 15));
    req.headers.set(HttpHeaders.userAgentHeader, 'PS2Store/0.5');
    req.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
    final res = await req.close().timeout(const Duration(seconds: 20));
    final body = await utf8.decoder.bind(res).join().timeout(const Duration(seconds: 20));
    if (res.statusCode != HttpStatus.ok) {
      throw HttpException('GitHub HTTP ${res.statusCode} (limite de API ou recurso indisponivel)');
    }
    return jsonDecode(body);
  }

  Future<List<GitHubResult>> search(String userQuery) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
    try {
      final query = userQuery.trim();
      // Sempre exige PS2/homebrew no termo para evitar resultados genericos.
      final q = query.isEmpty ? 'ps2 homebrew' : 'ps2 homebrew $query';
      final uri = Uri.https('api.github.com', '/search/repositories', {
        'q': q, 'sort': 'updated', 'order': 'desc', 'per_page': '12',
      });
      final data = await _get(client, uri) as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>? ?? []);
      final results = <GitHubResult>[];
      // Limita consultas para respeitar rate limits da API publica.
      for (final raw in items.take(8)) {
        final repo = raw as Map<String, dynamic>;
        final fullName = repo['full_name']?.toString() ?? '';
        if (!RegExp(r'^[\w.-]+/[\w.-]+$').hasMatch(fullName)) continue;
        dynamic release;
        try {
          release = await _get(client, Uri.https('api.github.com', '/repos/$fullName/releases/latest'));
        } on HttpException {
          continue; // Repositorios sem release publicado.
        }
        final releaseData = release as Map<String, dynamic>;
        final assets = releaseData['assets'] as List<dynamic>? ?? [];
        for (final assetRaw in assets) {
          final asset = assetRaw as Map<String, dynamic>;
          final name = asset['name']?.toString() ?? '';
          if (!RegExp(r'\.(elf|zip|7z)$', caseSensitive: false).hasMatch(name)) continue;
          final url = asset['browser_download_url']?.toString() ?? '';
          final parsed = Uri.tryParse(url);
          if (parsed == null || parsed.scheme != 'https' || parsed.host != 'github.com') continue;
          final license = repo['license'] is Map ? (repo['license']['spdx_id']?.toString() ?? 'Nao informada') : 'Nao informada';
          results.add(GitHubResult(
            id: '$fullName/$name', title: '${repo['name']} — $name',
            description: repo['description']?.toString() ?? 'Projeto publico no GitHub; compatibilidade nao verificada.',
            version: releaseData['tag_name']?.toString() ?? 'Sem versao',
            license: license, downloadUrl: url,
          ));
          break; // Um arquivo por repositorio nesta primeira versao.
        }
      }
      return results;
    } finally {
      client.close(force: true);
    }
  }
}
