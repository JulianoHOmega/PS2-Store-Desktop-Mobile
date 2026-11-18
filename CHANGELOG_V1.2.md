# PS2 Store v1.2 — interface e downloads

- Campo de pesquisa começa vazio (busca vazia usa o termo padrão OPL no provedor, mas não preenche o campo).
- Removida a linha fixa "Fonte: ..."; status aparece apenas quando relevante.
- Botão Cancelar download encerra a conexão ativa e apaga o arquivo temporário .part.
- Filtros locais por formato (ISO, ELF, ZIP, 7Z, RAR) e origem.
- Descrições HTML convertidas para texto legível.
- Classificação de capas e temas aprimorada.
- Avisos de compatibilidade não verificada preservados.
- build.yml sem alterações.

**Não compilado localmente:** validar GitHub Actions e teste de cancelamento em Windows/Android/Linux.
