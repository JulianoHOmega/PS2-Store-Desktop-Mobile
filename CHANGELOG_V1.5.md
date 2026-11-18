# PS2 Store v1.5 — Busca unificada (experimental)

- O mesmo botão **Buscar na internet** consulta as cinco fontes anteriores e tenta consultar os 15 sites adicionais.
- Os resultados disponíveis são combinados nos mesmos cartões e filtros.
- Os sites externos são consultados por páginas públicas HTML, sem contornar bloqueios. Sites indisponíveis ou que dependam de JavaScript podem retornar zero resultados.
- Links diretamente identificados como `.iso`, `.zip`, `.elf`, `.7z` ou `.rar` disponibilizam download; páginas de catálogo aparecem com botão **Abrir página original**, sem fingir que são arquivos.
- O botão separado para os 15 sites foi removido.
- Mantidos o fundo Omega, o nome JulianoHOmega, o histórico, os filtros e o cancelamento.
- Adicionada dependência `html` e testes unitários do extrator.

**Não há garantia de resultados de todos os 15 sites em cada pesquisa.** A estrutura dos sites muda e algumas fontes bloqueiam requisições automatizadas. Compilação Flutter ainda não executada neste ambiente.
