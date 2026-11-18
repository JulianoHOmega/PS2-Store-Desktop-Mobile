# PS2 Store v2.0 — candidata a versão estável

Base: v1.5.1 validada pelo usuário.

## Pesquisa
- Campo de pesquisa limpo durante a digitação, sem mensagem prematura de ausência de resultados.
- Botão "Buscar"; Enter/ação de pesquisa no teclado executa a mesma busca.
- Removido João13 Traduções da lista de sites externos.
- Paginação visual em blocos de 30 resultados com botão "Mostrar mais".
- Contagem de resultados por origem para facilitar diagnóstico de fontes.
- Busca multifontes, ordenação por relevância, agrupamento de projetos e filtros preservados.

## Downloads
- Fila sequencial: selecionar Baixar enquanto outro download está ativo adiciona à fila.
- Pausar e continuar durante a transferência ativa; a pausa suspende o consumo de dados pelo app e depende da conexão continuar disponível. Não é retomada após reiniciar o aplicativo.
- Remover itens pendentes da fila; tentar novamente último download com falha.
- Cancelar e limpeza de arquivo parcial preservados.
- Histórico, progresso, velocidade e Downloads preservados.

## Estabilidade
- Nenhum aplicativo demonstrativo no catálogo local.
- Fundo Omega e nome PS2 STORE by JulianoHOmega preservados.
- Workflow GitHub Actions anterior mantido.

## Validação pendente
- Flutter SDK não está disponível no ambiente de edição: compilação e testes Dart/Flutter não executados aqui.
- Compilar e testar no GitHub Actions em Windows, Linux e Android.
- Testar pausa, cancelamento, fila e falhas de conexão com arquivos grandes.
- As fontes externas podem não responder ou não oferecer links diretos.
