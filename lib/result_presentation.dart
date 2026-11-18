class DownloadCancelled implements Exception {
  const DownloadCancelled();
}

class ResultPresentation {
  static String cleanDescription(String input) {
    return input
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll(RegExp(r'&nbsp;|&#160;', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'&amp;', caseSensitive: false), '&')
      .replaceAll(RegExp(r'&lt;', caseSensitive: false), '<')
      .replaceAll(RegExp(r'&gt;', caseSensitive: false), '>')
      .replaceAll(RegExp(r'&quot;', caseSensitive: false), '"')
      .replaceAll(RegExp(r'&#39;|&apos;', caseSensitive: false), "'")
      .replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String source(String developer, String projectUrl) {
    final text = '$developer $projectUrl'.toLowerCase();
    if (text.contains('archive.org') || text.contains('internet archive')) return 'Internet Archive';
    if (text.contains('sourceforge')) return 'SourceForge';
    if (text.contains('gitlab')) return 'GitLab';
    if (text.contains('github')) return 'GitHub';
    return 'Outras';
  }

  static String format(String url, String title) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
    final combined = '$path $title'.toLowerCase();
    for (final ext in ['iso', 'elf', 'zip', '7z', 'rar']) {
      if (RegExp(r'\.' + ext + r'(?=\b|\s|\?|$)', caseSensitive: false).hasMatch(combined)) return ext.toUpperCase();
    }
    return 'Outro';
  }

  static String category(String title, String description, String fallback) {
    final text = '$title ${cleanDescription(description)}'.toLowerCase();
    if (RegExp(r'\b(cover art|covers|capas|artwork|box art)\b').hasMatch(text)) return 'Capas e artes';
    if (RegExp(r'\b(theme|themes|tema|temas|skin)\b').hasMatch(text)) return 'Temas';
    if (RegExp(r'\b(emulator|emulador|emulation|retroarch)\b').hasMatch(text)) return 'Emuladores';
    if (RegExp(r'\b(file manager|file browser|ulaunchelf|wlaunchelf)\b').hasMatch(text)) return 'Arquivos';
    if (RegExp(r'\b(open ps2 loader|launcher|loader)\b').hasMatch(text) || RegExp(r'(^|[^a-z])opl([^a-z]|$)').hasMatch(title.toLowerCase())) return 'Launchers';
    return fallback;
  }
}
