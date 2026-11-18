import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// External site shortcuts. These are browser searches, not indexed results or direct download links.
class ExternalSite {
  final String name, url;
  const ExternalSite(this.name, this.url);
}
const externalSites = <ExternalSite>[
  ExternalSite('Retro Jogos', 'https://www.retro-jogos.com/'),
  ExternalSite('CH1N — jogos traduzidos', 'https://www.ch1n.com.br/2020/06/170-jogos-traduzidos-playstation-2.html?m=1'),
  ExternalSite('ROMs Português', 'https://romsportugues.com/category/playstation-2-ps2/'),
  ExternalSite('Jogos Traduzidos', 'https://jogostraduzidos.com.br/'),
  ExternalSite('Allves Games', 'https://allvesgames.com/jogos-de-ps2-traduzidos-ou-dublados-em-portugues-lista/'),
  ExternalSite('Dubs Gamer', 'https://dubsgamer.com/'),
  ExternalSite('Vimm’s Lair', 'https://vimm.net/'),
  ExternalSite('CoolROM Austrália', 'https://coolrom.com.au/roms/ps2/'),
  ExternalSite('HexRom', 'https://hexrom.com/'),
  ExternalSite('RomsFun', 'https://romsfun.com/'),
  ExternalSite('Retrostic', 'https://www.retrostic.com/pt'),
  ExternalSite('RomsGames', 'https://www.romsgames.net/'),
  ExternalSite('Emuparadise', 'https://www.emuparadise.me/'),
  ExternalSite('GamesGX', 'https://www.gamesgx.net/'),
];

Future<void> showExternalSites(BuildContext context, String query) async {
  final term = query.trim().isEmpty ? 'PS2 ISO ZIP' : query.trim();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Pesquisar em outros sites'),
      content: SizedBox(width: 580, height: 450, child: ListView.builder(
        itemCount: externalSites.length,
        itemBuilder: (context, index) {
          final site = externalSites[index];
          return ListTile(
            title: Text(site.name),
            subtitle: Text(Uri.parse(site.url).host),
            trailing: const Icon(Icons.open_in_new),
            onTap: () async {
              final domain = Uri.parse(site.url).host.replaceFirst(RegExp(r'^www\.'), '');
              final searchUrl = Uri.https('www.google.com', '/search', {'q': 'site:$domain $term'});
              final ok = await launchUrl(searchUrl, mode: LaunchMode.externalApplication);
              if (!ok && dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Nao foi possivel abrir o navegador.')));
              }
            },
          );
        },
      )),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Fechar'))],
    ),
  );
}
