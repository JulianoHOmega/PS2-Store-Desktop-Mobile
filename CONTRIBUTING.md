# 🤝 Contribuindo com a PS2 Store

Obrigado pelo interesse em melhorar a PS2 Store! O projeto aceita correções de bugs, melhorias de acessibilidade, desempenho, compatibilidade e documentação.

## Antes de começar

1. Confira as [Issues existentes](https://github.com/JulianoHOmega/PS2-Store-Desktop-Mobile/issues) para evitar trabalho duplicado.
2. Para mudanças grandes, abra uma Issue descrevendo a proposta antes de implementar.
3. Respeite as licenças de código, imagens e demais materiais utilizados.

## Fluxo recomendado

1. Faça um **fork** do repositório.
2. Crie uma branch descritiva, como `fix/android-search` ou `feat/search-feedback`.
3. Faça alterações pequenas, organizadas e documentadas.
4. Execute, sempre que possível:

```bash
flutter pub get
flutter analyze
flutter test
```

5. Teste a plataforma afetada (Windows, Linux ou Android) e descreva os resultados.
6. Faça commits com mensagens claras, como `fix: tratar falha de conexão no Android`.
7. Envie um **Pull Request** para a branch `main`, explicando o problema, a solução e como reproduzir/testar.

## O que incluir em um Pull Request

- Resumo da mudança e motivação.
- Issue relacionada, quando houver.
- Plataformas testadas e comandos executados.
- Capturas de tela para mudanças visuais, se aplicável.
- Limitações conhecidas ou possíveis efeitos colaterais.

## Boas práticas

- Preserve o funcionamento nas três plataformas.
- Não altere fluxos de compilação sem justificar a necessidade.
- Não adicione dependências desnecessárias.
- Trate erros de rede de forma explícita; falha de conexão não deve parecer busca sem resultados.
- Nunca envie credenciais, tokens, senhas ou dados pessoais ao repositório.
- Não inclua ROMs, ISOs, jogos comerciais, arquivos protegidos ou meios de contornar restrições de direitos autorais.
- Respeite os termos dos sites consultados, limites de API e direitos dos titulares dos conteúdos.

## Relatando bugs

Ao abrir uma Issue, informe a versão da PS2 Store, plataforma e versão do sistema operacional, passos para reproduzir, resultado esperado, resultado observado e mensagens de erro (sem dados sensíveis).

## Revisão e integração

Pull Requests podem ser revisados e receber pedidos de ajustes. A decisão de integrar alterações cabe aos mantenedores. Contribuir não dá acesso direto de escrita à branch principal.

## Código de conduta

Mantenha a comunicação respeitosa, objetiva e construtiva. Críticas técnicas são bem-vindas; ataques pessoais, assédio e divulgação de informações privadas não são aceitos.
