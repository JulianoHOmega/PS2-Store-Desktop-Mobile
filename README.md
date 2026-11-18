# PS2 Store Desktop & Mobile v0.3

Projeto Flutter para Windows, Linux e Android. Este pacote e **completo**, nao e um patch.

## Repositorio novo
1. Crie um repositorio GitHub vazio (sem README, .gitignore ou licenca automatica).
2. Extraia este ZIP. Envie **o conteudo** da pasta extraida para a raiz do repositorio, incluindo `.github/workflows/build.yml`.
3. Na aba Actions, acompanhe os jobs Windows, Linux e Android. Se nao iniciar automaticamente, use Run workflow.
4. Baixe os arquivos em Artifacts: PS2Store-Windows, PS2Store-Linux e PS2Store-Android-APK.
5. No Windows, extraia o ZIP de Windows inteiro e execute o .exe dentro da pasta extraida. Nao mova apenas o .exe.

## Correcao do erro anterior
Os pacotes anteriores nao continham `test/`, e `flutter create` gerava automaticamente um `test/widget_test.dart` de exemplo com importacao incorreta. Como `flutter analyze` verifica tambem testes, o job Windows falhava. Este pacote inclui **test/catalog_test.dart** valido, com `flutter_test` no `pubspec.yaml`, antes de `flutter create`. Assim o Flutter nao precisa gerar um teste padrao e os testes reais sao executados.

## Estado
O catalogo incluso e demonstrativo. Os links de download podem ser exemplos e nao devem ser tratados como arquivos reais. A busca automatica na internet ainda nao foi implementada. Este pacote foi revisado estruturalmente, mas nao compilado localmente por ausencia do Flutter SDK; GitHub Actions fara a validacao.

## Correcao v0.3.1
O workflow remove test/widget_test.dart que o comando flutter create gera automaticamente, mantendo o teste real test/catalog_test.dart. Inclui flutter_lints para analysis_options.yaml gerado pelo Flutter.

No GitHub, envie todos os arquivos para a raiz e crie .github/workflows/build.yml com o conteudo fornecido se a interface nao permitir enviar pastas ocultas.
