# 🎮 PS2 Store — Desktop & Mobile

**Versão 2.0 · Windows · Linux · Android**

Aplicativo multiplataforma desenvolvido em **Flutter** para pesquisar jogos e arquivos relacionados ao PlayStation 2 na internet. Quando uma fonte disponibiliza um link direto, o aplicativo pode apresentar a opção de download; caso contrário, encaminha o usuário à página de origem.

> **Aviso:** este projeto não é afiliado à Sony ou à marca PlayStation. A disponibilidade e os direitos de uso de arquivos encontrados em sites externos são responsabilidade de seus respectivos titulares e usuários. Use apenas conteúdos que você tenha autorização para baixar e distribuir.

## ✨ Funcionalidades

- Pesquisa de jogos e arquivos em fontes online.
- Busca inteligente, com tolerância a erros de digitação e variações de títulos.
- Interface para Windows, Linux e Android.
- Exibição de links diretos quando disponíveis e de páginas de origem nos demais casos.
- Código aberto e contribuições da comunidade por meio de Pull Requests.

## 📥 Downloads — v2.0

Acesse a **[Release v2.0.0](https://github.com/JulianoHOmega/PS2-Store-Desktop-Mobile/releases/tag/v2.0.0)** para conferir todos os arquivos publicados.

| Plataforma | Download |
| --- | --- |
| 🪟 Windows | [PS2Store-Windows.2.zip](https://github.com/JulianoHOmega/PS2-Store-Desktop-Mobile/releases/download/v2.0.0/PS2Store-Windows.2.zip) |
| 🐧 Linux | [PS2Store-Linux.tar.gz](https://github.com/JulianoHOmega/PS2-Store-Desktop-Mobile/releases/download/v2.0.0/PS2Store-Linux.tar.gz) |
| 📱 Android | [app-release.apk](https://github.com/JulianoHOmega/PS2-Store-Desktop-Mobile/releases/download/v2.0.0/app-release.apk) |

## 🚀 Instalação

**Windows:** baixe o ZIP, extraia todo o conteúdo para uma pasta e execute o aplicativo presente na pasta extraída. Mantenha os arquivos de suporte juntos.

**Linux:** baixe o `.tar.gz`, extraia o conteúdo e execute o binário do aplicativo. Algumas distribuições podem exigir bibliotecas de sistema compatíveis com Flutter desktop.

**Android:** baixe o APK e instale-o no dispositivo. O Android pode solicitar autorização para instalar aplicativos dessa origem.

A pesquisa requer acesso à internet. Sites externos podem ficar indisponíveis ou limitar requisições.

## 🛠️ Desenvolvimento

Requisitos: [Flutter SDK](https://docs.flutter.dev/get-started/install) e ferramentas da plataforma que você deseja compilar.

```bash
git clone https://github.com/JulianoHOmega/PS2-Store-Desktop-Mobile.git
cd PS2-Store-Desktop-Mobile
flutter pub get
flutter analyze
flutter test
```

Para executar localmente, conforme o sistema:

```bash
flutter run -d windows
flutter run -d linux
flutter run -d android
```

Para compilar versões de distribuição:

```bash
flutter build windows --release
flutter build linux --release
flutter build apk --release
```

O projeto utiliza **GitHub Actions** para compilar os pacotes das plataformas. Verifique os fluxos em `.github/workflows/`.

## 🤝 Como contribuir

Contribuições são bem-vindas! Você pode abrir uma [Issue](https://github.com/JulianoHOmega/PS2-Store-Desktop-Mobile/issues) para relatar problemas ou propor melhorias e enviar um [Pull Request](https://github.com/JulianoHOmega/PS2-Store-Desktop-Mobile/pulls) com alterações.

Leia o [guia de contribuição](CONTRIBUTING.md) antes de enviar código. Evite incluir jogos comerciais, ROMs, ISOs protegidas, chaves, tokens ou links que violem direitos de terceiros.

## 📄 Licença

O código original do projeto é disponibilizado sob a [Licença MIT](LICENSE), **desde que os respectivos titulares tenham autorizado essa distribuição**. Dependências, marcas e conteúdos de terceiros mantêm suas próprias licenças e direitos.

---

Projeto mantido por [JulianoHOmega](https://github.com/JulianoHOmega). PlayStation e PS2 são marcas de seus respectivos proprietários.
