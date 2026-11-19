from pathlib import Path
p = Path('linux/runner/my_application.cc')
s = p.read_text()
# The generated Linux runner creates a GtkWindow and sets its title here.
needle = 'gtk_window_set_title(window, "ps2_store");'
# Some Flutter versions use GTK_HEADER_BAR or another title value. Locate the first window title statement.
import re
m = re.search(r'gtk_window_set_title\(window,\s*"[^"]*"\);', s)
if not m:
    raise SystemExit('Runner Linux mudou: nao encontrei gtk_window_set_title(window, ...).')
insert = """// PS2 Store: carregar icone de janela do diretorio do executavel.
  gchar *exe_path = g_file_read_link("/proc/self/exe", NULL);
  if (exe_path != NULL) {
    gchar *exe_dir = g_path_get_dirname(exe_path);
    gchar *icon_path = g_build_filename(exe_dir, "ps2-store.png", NULL);
    gtk_window_set_icon_from_file(window, icon_path, NULL);
    g_free(icon_path);
    g_free(exe_dir);
    g_free(exe_path);
  }
  """
s=s[:m.end()]+'\n  '+insert+s[m.end():]
p.write_text(s)
print('Runner Linux configurado.')
