# PS2 Store v0.6 — metadados e downloads

- Exibe tamanho do asset de GitHub Releases quando disponível.
- Exibe URL do projeto e licença declarada na tela de detalhes.
- Identifica explicitamente compatibilidade com PS2 como **não verificada**.
- Botão **Abrir Downloads** no Windows e Linux.
- Contador e histórico resumido dos downloads concluídos **na sessão atual** (não persistente).
- Mantém busca GitHub, salvamento em Downloads e workflow da v0.5.

## Limitações

- Não foi implementada verificação automática de autenticidade, segurança ou compatibilidade dos ELF/ZIP/7z.
- A pesquisa continua limitada a GitHub Releases; resultados podem ser irrelevantes.
- Histórico é apenas da sessão, não persiste após fechar o aplicativo.
- A compilação Flutter não foi executada neste ambiente; valide via GitHub Actions.
