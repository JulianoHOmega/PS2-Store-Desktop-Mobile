import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

const remoteCatalogUrl = String.fromEnvironment('CATALOG_URL', defaultValue: '');

void main() => runApp(const Ps2StoreApp());

class StoreApp {
  final String id, title, description, category, version, license, downloadUrl, cover;
  const StoreApp({required this.id, required this.title, required this.description,
    required this.category, required this.version, required this.license,
    required this.downloadUrl, required this.cover});
  factory StoreApp.fromJson(Map<String, dynamic> json) {
    String value(String key, [String fallback = '']) => json[key]?.toString() ?? fallback;
    return StoreApp(id: value('id'), title: value('title', 'Sem titulo'),
      description: value('description'), category: value('category', 'Outros'),
      version: value('version', '—'), license: value('license', 'Nao informada'),
      downloadUrl: value('download_url', value('url')), cover: value('cover'));
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
  double progress = 0;
  @override
  void initState() { super.initState(); loadCatalog(); }

  Future<void> loadCatalog() async {
    setState(() => status = 'Carregando catalogo...');
    try {
      String content;
      String loadedFrom = 'Local (demonstracao)';
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

  Future<void> download(StoreApp app) async {
    if (busy) return;
    final uri = Uri.tryParse(app.downloadUrl);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http') || uri.host.isEmpty) {
      setState(() => status = 'Este aplicativo nao possui um link valido.'); return;
    }
    setState(() { busy = true; progress = 0; status = 'Iniciando download de ${app.title}...'; });
    HttpClient? client;
    File? temp;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
      final req = await client.getUrl(uri);
      final res = await req.close().timeout(const Duration(seconds: 30));
      if (res.statusCode != HttpStatus.ok) throw HttpException('HTTP ${res.statusCode}');
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory('${dir.path}${Platform.pathSeparator}PS2Store${Platform.pathSeparator}Downloads');
      await folder.create(recursive: true);
      final filename = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      final safeName = filename.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      if (safeName.isEmpty || safeName == '.' || safeName == '..') throw const FormatException('Nome de arquivo invalido');
      final target = File('${folder.path}${Platform.pathSeparator}$safeName');
      temp = File('${target.path}.part');
      final sink = temp.openWrite();
      var received = 0;
      try {
        await for (final chunk in res) {
          sink.add(chunk);
          received += chunk.length;
          if (mounted) setState(() {
            progress = res.contentLength > 0 ? received / res.contentLength : 0;
            status = 'Baixando $safeName: ${(received / 1048576).toStringAsFixed(1)} MB';
          });
        }
      } finally { await sink.close(); }
      if (res.contentLength >= 0 && received != res.contentLength) throw const HttpException('Download incompleto');
      if (await target.exists()) throw const FileSystemException('Arquivo ja existe; renomeie ou mova antes de baixar novamente');
      await temp.rename(target.path);
      temp = null;
      if (mounted) setState(() => status = 'Download concluido: ${target.path}');
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
        Text('Versao: ${app.version}'), Text('Licenca: ${app.license}'),
        const SizedBox(height: 12), Text(app.downloadUrl.isEmpty ? 'Download indisponivel' : app.downloadUrl,
          style: const TextStyle(fontSize: 12, color: Colors.lightBlueAccent))]))),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
      FilledButton.icon(onPressed: app.downloadUrl.isEmpty || busy ? null : () { Navigator.pop(context); download(app); },
        icon: const Icon(Icons.download), label: const Text('Baixar'))]));

  @override
  Widget build(BuildContext context) {
    final categories = ['Todos', ...{for (final a in apps) a.category}];
    final filtered = apps.where((a) => (category == 'Todos' || a.category == category) &&
      '${a.title} ${a.description}'.toLowerCase().contains(search.toLowerCase())).toList();
    return Scaffold(appBar: AppBar(title: const Text('PS2 STORE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
      actions: [IconButton(tooltip: 'Atualizar catalogo', onPressed: busy ? null : loadCatalog, icon: const Icon(Icons.refresh))]),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1150),
        child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Biblioteca digital de homebrews', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5), Text('Fonte: $source  •  $status', maxLines: 3, overflow: TextOverflow.ellipsis),
          if (busy) Padding(padding: const EdgeInsets.only(top: 10), child: LinearProgressIndicator(value: progress > 0 ? progress : null)),
          const SizedBox(height: 18), TextField(onChanged: (v) => setState(() => search = v),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Pesquisar homebrews e utilitarios', border: OutlineInputBorder())),
          const SizedBox(height: 12), SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
            for (final c in categories) Padding(padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(label: Text(c), selected: c == category, onSelected: (_) => setState(() => category = c)))
          ])),
          const SizedBox(height: 12), Expanded(child: filtered.isEmpty ? const Center(child: Text('Nenhum aplicativo encontrado')) :
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
                    const Spacer(), Row(children: [Text('${app.category} • v${app.version}', style: const TextStyle(fontSize: 12)),
                      const Spacer(), Icon(app.downloadUrl.isEmpty ? Icons.info_outline : Icons.download, size: 20)])
                  ]))));
              })))
        ])))));
  }
}
