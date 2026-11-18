/// Heuristicas de relevancia. Nao constituem verificacao de seguranca,
/// compatibilidade com PS2 ou autorizacao de redistribuicao.
class SearchQuality {
  static const _ps2Terms = ['playstation 2', 'playstation2', 'ps2', 'ps2sdk', 'ps2dev', 'homebrew ps2', 'opl', 'ulaunchelf', 'wlaunchelf'];
  static const _unrelated = ['ps3', 'ps4', 'ps5', 'playstation 3', 'playstation 4', 'playstation 5', 'retroarch desktop', 'android only'];

  static bool relevant(String repoName, String description, String topics) {
    final s = '$repoName $description $topics'.toLowerCase();
    if (!_ps2Terms.any(s.contains)) return false;
    if (_unrelated.any(s.contains) && !_ps2Terms.take(6).any(s.contains)) return false;
    return true;
  }

  static String category(String name, String description) {
    final s = '$name $description'.toLowerCase();
    if (['emulator', 'emulador', 'snes', 'nes', 'gameboy', 'megadrive'].any(s.contains)) return 'Emuladores';
    if (['file manager', 'file browser', 'ulaunchelf', 'wlaunchelf', 'explorer'].any(s.contains)) return 'Arquivos';
    if (['open ps2 loader', 'opl', 'launcher', 'loader'].any(s.contains)) return 'Launchers';
    if (['game', 'jogo', 'platformer'].any(s.contains)) return 'Jogos homebrew';
    return 'Utilitarios';
  }

  static int score(String name, String description, String topics, String query) {
    final s = '$name $description $topics'.toLowerCase();
    final n = name.toLowerCase();
    var points = 0;
    if (n.contains('ps2') || n.contains('playstation2')) points += 4;
    if (s.contains('ps2sdk') || s.contains('ps2dev')) points += 3;
    if (s.contains('playstation 2') || s.contains('homebrew')) points += 2;
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty && n.contains(q)) points += 3;
    if (q == 'opl') {
      if (RegExp(r'(^|[^a-z])opl([^a-z]|$)').hasMatch(n)) points += 12;
      if (s.contains('open ps2 loader')) points += 18;
      if (s.contains('oplus') || s.contains('opl3')) points -= 20;
    }
    return points;
  }
}
