import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'github_search.dart';
import 'download_history.dart';

const remoteCatalogUrl = String.fromEnvironment('CATALOG_URL', defaultValue: '');

void main() => runApp(const Ps2StoreApp());

class StoreApp {
  final String id, title, description, category, version, license, downloadUrl, cover, projectUrl;
  final int sizeBytes;
  final String developer;
  const StoreApp({required this.id, required this.title, required this.description,
    required this.category, required this.version, required this.license,
    required this.downloadUrl, required this.cover, this.projectUrl = '', this.sizeBytes = 0, this.developer = 'Nao informado'});
  factory StoreApp.fromJson(Map<String, dynamic> json) {
    String value(String key, [String fallback = '']) => json[key]?.toString() ?? fallback;
    return StoreApp(id: value('id'), title: value('title', 'Sem titulo'),
      description: value('description'), category: value('category', 'Outros'),
      version: value('version', '—'), license: value('license', 'Nao informada'),
      downloadUrl: value('download_url', value('url')), cover: value('cover'),
      projectUrl: value('project_url'), developer: value('developer', 'Nao informado'), sizeBytes: int.tryParse(value('size_bytes')) ?? 0);
  }
}

class Ps2StoreApp extends StatelessWidget {
  const Ps2StoreApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'PS2 Store', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, brightness: Brightness.dark,
      colorSchemeSeed: const Color(0xff368ce7), scaffoldBackgroundColor: const Color(0xff091322)),
    home: const StoreHome());
}

class StoreHome extends StatefulWidget {
  const StoreHome({super.key});
  @override
  State<StoreHome> createState() => _StoreHomeState();
}

class _StoreHomeState extends State<StoreHome> {
  List<StoreApp> apps = [];
  String search = '', category = 'Todos', status = 'Carregando catalogo...', source = 'Local';
  bool busy = false;
  bool searchingOnline = false;
  double progress = 0;
  double downloadSpeed = 0;
  int downloadedBytes = 0;
  int totalDownloadBytes = -1;
  String? lastSavedPath;
  List<DownloadRecord> completedDownloads = [];
  final DownloadHistoryStore historyStore = DownloadHistoryStore();

  Future<void> loadDownloadHistory() async {
    try {
      final records = await historyStore.load();
      if (mounted) setState(() => completedDownloads = records);
    } catch (e) {
      if (mounted) setState(() => status = 'Historico indisponivel: $e');
    }
  }

  Future<void> recordDownload(StoreApp app, String filename, String location) async {
    final record = DownloadRecord(
      title: app.title, filename: filename, location: location,
      sourceUrl: app.downloadUrl, completedAt: DateTime.now().toUtc());
    final updated = [record, ...completedDownloads].take(100).toList();
    if (mounted) setState(() => completedDownloads = updated);
    try {
      await historyStore.save(updated);
    } catch (e) {
      if (mounted) setState(() => status = 'Download concluido; falha ao salvar historico: $e');
    }
  }

  void showDownloadHistory() => showDialog<void>(context: context, builder: (context) => AlertDialog(
    title: const Text('Historico de downloads'),
    content: SizedBox(width: 550, height: 380, child: completedDownloads.isEmpty
      ? const Center(child: Text('Nenhum download registrado.'))
      : ListView.builder(itemCount: completedDownloads.length, itemBuilder: (context, index) {
          final item = completedDownloads[index];
          return ListTile(
            leading: const Icon(Icons.download_done),
            title: Text(item.filename, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${item.title}\n${item.completedAt.toLocal()}\n${item.location}',
              maxLines: 3, overflow: TextOverflow.ellipsis),
          );
        })),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))],
  ));

  String fileSize(int bytes) => bytes <= 0 ? 'Tamanho nao informado'
    : bytes >= 1048576 ? '${(bytes / 1048576).toStringAsFixed(1)} MB'
    : '${(bytes / 1024).toStringAsFixed(0)} KB';

  Future<void> openDownloadsFolder() async {
    if (Platform.isAndroid) return;
    try {
      final folder = await getDownloadsDirectory();
      if (folder == null) throw const FileSystemException('Pasta Downloads indisponivel');
      if (Platform.isWindows) {
        await Process.start('explorer.exe', [folder.path], mode: ProcessStartMode.detached);
      } else if (Platform.isLinux) {
        await Process.start('xdg-open', [folder.path], mode: ProcessStartMode.detached);
      }
    } catch (e) {
      if (mounted) setState(() => status = 'Nao foi possivel abrir Downloads: $e');
    }
  }
  @override
  void initState() { super.initState(); loadCatalog(); loadDownloadHistory(); }

  Future<void> loadCatalog() async {
    setState(() => status = 'Carregando catalogo...');
    try {
      String content;
      String loadedFrom = 'Catalogo local';
      if (remoteCatalogUrl.isNotEmpty) {
        final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
        try {
          final req = await client.getUrl(Uri.parse(remoteCatalogUrl));
          final res = await req.close().timeout(const Duration(seconds: 20));
          if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
          content = await utf8.decoder.bind(res).join();
          loadedFrom = 'Online';
        } finally { client.close(force: true); }
      } else {
        content = await rootBundle.loadString('assets/catalog.json');
      }
      final decoded = jsonDecode(content) as Map<String, dynamic>;
      final raw = (decoded['games'] ?? decoded['apps']) as List<dynamic>;
      final parsed = raw.map((e) => StoreApp.fromJson(e as Map<String, dynamic>)).toList();
      if (!mounted) return;
      setState(() { apps = parsed; source = loadedFrom; status = '${parsed.length} aplicativos no catalogo'; category = 'Todos'; });
    } catch (e) {
      if (!mounted) return;
      setState(() => status = 'Falha ao carregar catalogo: $e');
    }
  }

  Future<void> searchOnline() async {
    if (busy || searchingOnline) return;
    setState(() { searchingOnline = true; status = 'Consultando projetos publicos no GitHub...'; });
    try {
      final results = await GitHubHomebrewSearch().search(search);
      if (!mounted) return;
      setState(() {
        apps = results.map((r) => StoreApp(
          id: r.id, title: r.title, description: r.description,
          category: r.category, version: r.version, license: r.license, developer: r.developer,
          downloadUrl: r.downloadUrl, cover: '',
          projectUrl: r.projectUrl, sizeBytes: r.sizeBytes,
        )).toList();
        source = 'GitHub (Releases publicos)';
        category = 'Todos';
        status = '${results.length} resultados relevantes; compatibilidade e seguranca NAO verificadas';
      });
    } catch (e) {
      if (mounted) setState(() => status = 'Busca online indisponivel: $e');
    } finally {
      if (mounted) setState(() => searchingOnline = false);
    }
  }

  Future<void> download(StoreApp app) async {
    if (busy) return;
    final uri = Uri.tryParse(app.downloadUrl);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http') || uri.host.isEmpty) {
      setState(() => status = 'Este aplicativo nao possui um link valido.'); return;
    }
    setState(() { busy = true; progress = 0; downloadSpeed = 0; downloadedBytes = 0; totalDownloadBytes = -1; status = 'Iniciando download de ${app.title}...'; });
    HttpClient? client;
    File? temp;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
      final req = await client.getUrl(uri);
      final res = await req.close().timeout(const Duration(seconds: 30));
      if (res.statusCode != HttpStatus.ok) throw HttpException('Servidor retornou HTTP ${res.statusCode}');
      final filename = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      final safeName = filename.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      if (safeName.isEmpty || safeName == '.' || safeName == '..') throw const FormatException('Nome de arquivo invalido');
      final Directory folder;
      if (Platform.isAndroid) {
        folder = await getTemporaryDirectory();
      } else {
        final downloads = await getDownloadsDirectory();
        if (downloads == null) throw const FileSystemException('Pasta Downloads nao encontrada');
        folder = downloads;
      }
      await folder.create(recursive: true);
      final target = File('${folder.path}${Platform.pathSeparator}$safeName');
      if (!Platform.isAndroid && await target.exists()) {
        throw const FileSystemException('Arquivo ja existe na pasta Downloads');
      }
      temp = File('${folder.path}${Platform.pathSeparator}${DateTime.now().microsecondsSinceEpoch}_$safeName.part');
      final sink = temp.openWrite();
      var received = 0;
      final watch = Stopwatch()..start();
      var lastUpdateMs = 0;
      try {
        await for (final chunk in res) {
          sink.add(chunk);
          received += chunk.length;
          // Evita reconstruir toda a interface a cada pequeno bloco de rede.
          final elapsedMs = watch.elapsedMilliseconds;
          if (mounted && (elapsedMs - lastUpdateMs >= 250 ||
              (res.contentLength > 0 && received >= res.contentLength))) {
            lastUpdateMs = elapsedMs;
            setState(() {
              downloadedBytes = received;
              totalDownloadBytes = res.contentLength;
              downloadSpeed = elapsedMs > 0 ? received * 1000 / elapsedMs : 0;
              progress = res.contentLength > 0 ?
                  (received / res.contentLength).clamp(0.0, 1.0) : 0;
              status = 'Baixando $safeName';
            });
          }
        }
      } finally { await sink.close(); }
      if (mounted) setState(() { downloadedBytes = received; totalDownloadBytes = res.contentLength; progress = 1; });
      if (res.contentLength >= 0 && received != res.contentLength) throw const HttpException('Download incompleto');
      if (Platform.isAndroid) {
        // O Android usa o seletor nativo: o usuario pode escolher Downloads.
        final saved = await FlutterFileDialog.saveFile(params: SaveFileDialogParams(
          sourceFilePath: temp.path, fileName: safeName));
        if (saved == null) {
          if (mounted) setState(() => status = 'Salvamento cancelado.');
        } else {
          if (mounted) setState(() { lastSavedPath = null; status = 'Arquivo salvo no local escolhido.'; });
          await recordDownload(app, safeName, saved);
        }
      } else {
        await temp.rename(target.path);
        temp = null;
        if (mounted) setState(() { lastSavedPath = target.path; status = 'Download concluido: ${target.path}'; });
        await recordDownload(app, safeName, target.path);
      }
    } catch (e) {
      if (mounted) setState(() => status = 'Falha no download: $e');
    } finally {
      try { if (temp != null && await temp.exists()) await temp.delete(); } catch (_) {}
      client?.close(force: true);
      if (mounted) setState(() => busy = false);
    }
  }

  void showDetails(StoreApp app) => showDialog<void>(context: context, builder: (context) => AlertDialog(
    title: Text(app.title), content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
      children: [Text(app.description), const SizedBox(height: 16), Text('Categoria: ${app.category}'),
        Text('Versao: ${app.version}'), Text('Desenvolvedor: ${app.developer}'),
        Text('Licenca declarada: ${app.license}'),
        Text('Tamanho: ${fileSize(app.sizeBytes)}'),
        Text('Compatibilidade e seguranca: NAO VERIFICADAS',
          style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
        if (app.projectUrl.isNotEmpty) SelectableText('Projeto: ${app.projectUrl}'),
        const SizedBox(height: 12), Text(app.downloadUrl.isEmpty ? 'Download indisponivel' : app.downloadUrl,
          style: const TextStyle(fontSize: 12, color: Colors.lightBlueAccent))]))),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
      FilledButton.icon(onPressed: app.downloadUrl.isEmpty || busy ? null : () { Navigator.pop(context); download(app); },
        icon: const Icon(Icons.download), label: const Text('Baixar'))]));

  @override
  Widget build(BuildContext context) {
    final categories = ['Todos', ...{for (final a in apps) a.category}];
    final filtered = apps.where((a) => (category == 'Todos' || a.category == category) &&
      '${a.title} ${a.description} ${a.developer} ${a.category}'.toLowerCase().contains(search.toLowerCase())).toList();
    return Scaffold(appBar: AppBar(title: const Text('PS2 STORE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
      actions: [IconButton(tooltip: 'Voltar ao catalogo local', onPressed: busy || searchingOnline ? null : loadCatalog, icon: const Icon(Icons.refresh))]),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1150),
        child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Biblioteca digital de homebrews', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5), Text('Fonte: $source  •  $status', maxLines: 3, overflow: TextOverflow.ellipsis),
          if (busy) Padding(padding: const EdgeInsets.only(top: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            LinearProgressIndicator(value: progress > 0 ? progress : null),
            const SizedBox(height: 4), Text(
              '${fileSize(downloadedBytes)} recebidos'
              '${totalDownloadBytes > 0 ? ' de ${fileSize(totalDownloadBytes)}' : ''}'
              ' • ${(downloadSpeed / 1024).toStringAsFixed(0)} KB/s'
              '${totalDownloadBytes > 0 ? ' • ${(progress * 100).toStringAsFixed(0)}%' : ''}',
              style: const TextStyle(fontSize: 12)),
          ])),
          const SizedBox(height: 18), TextField(onChanged: (v) => setState(() => search = v),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Pesquisar homebrews e utilitarios', border: OutlineInputBorder())),
          const SizedBox(height: 10), Row(children: [
            FilledButton.icon(onPressed: busy || searchingOnline ? null : searchOnline,
              icon: const Icon(Icons.public), label: const Text('Buscar no GitHub')),
            const SizedBox(width: 12),
            if (searchingOnline) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            const Spacer(),
            if (!Platform.isAndroid) TextButton.icon(onPressed: openDownloadsFolder,
              icon: const Icon(Icons.folder_open), label: const Text('Abrir Downloads')),
            TextButton.icon(onPressed: showDownloadHistory, icon: const Icon(Icons.history),
              label: Text('Historico (${completedDownloads.length})')),
          ]),
          const SizedBox(height: 12), SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
            for (final c in categories) Padding(padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(label: Text(c), selected: c == category, onSelected: (_) => setState(() => category = c)))
          ])),
          const SizedBox(height: 12), Expanded(child: filtered.isEmpty ? const Center(child: Text('Nenhum aplicativo listado. Use Buscar no GitHub para encontrar projetos publicos.')) :
            LayoutBuilder(builder: (context, constraints) => GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: constraints.maxWidth > 900 ? 3 : constraints.maxWidth > 550 ? 2 : 1,
                mainAxisExtent: 185, mainAxisSpacing: 12, crossAxisSpacing: 12),
              itemCount: filtered.length, itemBuilder: (context, i) {
                final app = filtered[i];
                return Card(clipBehavior: Clip.antiAlias, child: InkWell(onTap: () => showDetails(app), child: Padding(
                  padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [const Icon(Icons.sports_esports, color: Colors.lightBlueAccent), const SizedBox(width: 10),
                      Expanded(child: Text(app.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)))]),
                    const SizedBox(height: 8), Text(app.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4), Text('Autor: ${app.developer}', maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.white70)),
                    const Spacer(), Row(children: [Expanded(child: Text('${app.category} • v${app.version} • ${fileSize(app.sizeBytes)}',
                        overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))),
                      Icon(app.downloadUrl.isEmpty ? Icons.info_outline : Icons.download, size: 20)])
                  ]))));
              })))
        ])))));
  }
}
