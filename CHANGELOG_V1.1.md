# v1.1 — Pesquisa ampliada

- Adicionada busca em itens de software do Internet Archive por API publica e seus arquivos ISO/ELF/ZIP/7Z/RAR.
- Adicionada tentativa de descoberta de projetos SourceForge pelo diretorio publico e RSS; pode nao funcionar caso o site limite consultas automatizadas.
- Mantidos GitHub e GitLab.
- Agrupamento: um resultado por projeto/item, evitando dezenas de arquivos do mesmo projeto na tela.
- Relevancia: busca OPL prioriza nome exato e Open PS2 Loader; rebaixa OPLUS e OPL3.
- Avisos de arquivos nao verificados e indicacao da fonte mantidos.
- Compatibilidade nao e requisito de pesquisa.
- Adicionada dependencia Dart xml para leitura de feeds RSS.
- Workflow build.yml preservado.

**Nao foi possivel executar Flutter neste ambiente.** Validar GitHub Actions e downloads reais.
