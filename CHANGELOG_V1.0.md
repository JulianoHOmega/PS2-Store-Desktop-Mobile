# PS2 Store v1.0 - busca ampliada experimental

- Busca inicial OPL; nao exige PS2/homebrew nos termos.
- Consulta duas fontes publicas: GitHub e GitLab.
- Aceita assets ELF, ISO, ZIP, 7Z e RAR sem filtro de compatibilidade.
- Exibe a origem pelo campo de desenvolvedor e URL do projeto.
- Aviso persistente de arquivos nao verificados.
- Mantem historico, downloads e workflows anteriores.

Limitacoes: nao pesquisa toda a web; somente assets de releases nas duas APIs.
APIs podem limitar requisicoes e links podem expirar. Nao ha verificacao de
licenca, autenticidade ou compatibilidade. Compilacao Flutter nao executada
neste ambiente; validar no GitHub Actions.
