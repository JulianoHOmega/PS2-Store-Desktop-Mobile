# PS2 Store — Ícones e Releases automáticas

## O que foi modificado
- Windows: ícone do EXE e da janela via `windows/runner/resources/app_icon.ico` (aplicado após `flutter create`).
- Android: ícones `mipmap-*` criados antes da compilação; permissão INTERNET mantida.
- Linux: ícone da janela GTK e ícone do lançador `.desktop`. O pacote inclui `install.sh` para instalar o atalho no menu de aplicativos.
- GitHub Actions: compila nos pushes normais; quando uma tag `v*` é enviada, publica automaticamente os três arquivos na Release correspondente.

## Como aplicar
1. Faça backup do repositório. Copie o conteúdo do ZIP para a raiz do repositório, substituindo o `build.yml` e preservando seus arquivos `README.md`, `LICENSE` e `CONTRIBUTING.md` mais recentes (caso existam).
2. Faça commit das alterações no branch `main`.
3. Confirme que o GitHub Actions compila as três plataformas com sucesso. O workflow gera estruturas nativas dinamicamente, por isso a configuração dos ícones ocorre após `flutter create`.
4. Crie uma tag nova **v2.0.1** (não reutilize `v2.0.0`): no GitHub, Releases → Draft a new release → Choose a tag → Create new tag `v2.0.1` on `main` → Publish release. O push da tag dispara o workflow que anexará os três arquivos automaticamente à Release. Se a Release for publicada antes do build terminar, os arquivos aparecerão após a conclusão.
5. Para Linux: extraia o `.tar.gz` e execute `bash install.sh` dentro da pasta extraída para instalar o atalho e o ícone no menu.

## Importante
- A publicação automática requer `Settings → Actions → General → Workflow permissions` com permissões adequadas. Este workflow pede `contents: write` **somente no job de Release**. Políticas da organização podem impedir essa permissão.
- O Android compilado pelo workflow usa a assinatura padrão de release do Flutter se você não configurar sua própria chave. **Antes de distribuir atualizações a usuários existentes**, configure assinatura estável do APK: mudar a chave pode impedir atualização por cima de um APK instalado.
- Este pacote não foi compilado em runners Windows, Linux e Android neste ambiente. Verifique os logs dos três jobs e instale os executáveis para validar os ícones.
- Para Windows, se o Explorer mantiver o ícone antigo, limpe o cache de ícones ou altere o nome do executável no pacote antes de concluir que o recurso falhou.
