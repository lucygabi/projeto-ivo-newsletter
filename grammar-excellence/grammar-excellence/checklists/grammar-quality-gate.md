# Grammar Quality Gate Checklist

Quality gate para validacao de correcoes gramaticais antes de aprovacao.

## Scoring Model

- Each item has a **weight**: BLOCKING, CRITICAL (10pts), MAJOR (5pts), or MINOR (2pts)
- **BLOCKING** items cause instant FAIL regardless of total score
- Non-blocking items contribute to a 0-100 score based on PASS/FAIL
- Maximum possible score = sum of all non-blocking item weights
- Final score = (passed weight / max weight) * 100

## Verdict Thresholds

| Score | Verdict | Action |
|-------|---------|--------|
| 85-100 | APPROVED | Pronto para merge/deploy |
| 60-84 | NEEDS_REVISION | Corrigir issues e re-review |
| 0-59 | REJECTED | Refazer correcoes |
| Any BLOCKING FAIL | DEPLOY_BLOCKED | Corrigir item bloqueante primeiro |

---

## Checklist

### Precisao Linguistica

- [ ] **PL-01: Correcoes gramaticalmente corretas** [CRITICAL - 10pts]
  - PASS: Todas as correcoes aplicadas sao validas na variante alvo. Zero falsos positivos.
  - FAIL: Uma ou mais correcoes introduzem erro gramatical ou alteram texto correto.
  - Se FAIL: Identificar correcoes incorretas. Run `*grammar-correct --mode interactive` para reverter.

- [ ] **PL-02: Regras da variante respeitadas** [CRITICAL - 10pts]
  - PASS: Todas as correcoes seguem as regras da variante declarada (PT-PT, PT-BR, etc.).
  - FAIL: Correcao aplica regra de variante errada (ex: gerundio brasileiro em texto PT-PT).
  - Se FAIL: Reverificar variante do ficheiro. Run `*grammar-correct --lang {variante-correta}`.

- [ ] **PL-03: Concordancia genero e numero** [MAJOR - 5pts]
  - PASS: Zero erros de concordancia em todo o scope auditado.
  - FAIL: Pelo menos 1 erro de concordancia de genero ou numero.
  - Se FAIL: Run `*grammar-scan --severity error` para listar erros de concordancia.

- [ ] **PL-04: Conjugacao verbal correta** [MAJOR - 5pts]
  - PASS: Todos os verbos conjugados corretamente em todos os tempos.
  - FAIL: Pelo menos 1 erro de conjugacao verbal.
  - Se FAIL: Run `*grammar-scan --severity error` e filtrar por conjugacao.

- [ ] **PL-05: Pontuacao conforme norma** [MINOR - 2pts]
  - PASS: Pontuacao segue as regras da variante (virgulas, pontos, ponto-e-virgula).
  - FAIL: Erros de pontuacao que afetam leitura ou significado.
  - Se FAIL: Revisao manual de pontuacao nos ficheiros afetados.

### Preservacao de Conteudo

- [ ] **PC-01: Code blocks inalterados** [BLOCKING]
  - PASS: Nenhum caracter dentro de code blocks (``` ... ```) foi modificado.
  - FAIL: Qualquer alteracao dentro de code blocks.
  - Se FAIL: DEPLOY_BLOCKED. Reverter alteracao imediatamente. Run `*integrity-check`.

- [ ] **PC-02: Inline code inalterado** [BLOCKING]
  - PASS: Nenhum caracter dentro de inline code (`...`) foi modificado.
  - FAIL: Qualquer alteracao dentro de inline code.
  - Se FAIL: DEPLOY_BLOCKED. Reverter alteracao. Run `*integrity-check`.

- [ ] **PC-03: URLs e links intactos** [BLOCKING]
  - PASS: Todos os URLs e links funcionam e nao foram modificados.
  - FAIL: Qualquer URL/link alterado, truncado ou partido.
  - Se FAIL: DEPLOY_BLOCKED. Restaurar URLs originais. Run `*integrity-check`.

- [ ] **PC-04: Front matter YAML intacto** [BLOCKING]
  - PASS: Front matter YAML (--- ... ---) com todas as chaves e valores preservados.
  - FAIL: Qualquer chave ou valor do front matter alterado.
  - Se FAIL: DEPLOY_BLOCKED. Restaurar front matter original.

- [ ] **PC-05: Variaveis e placeholders intactos** [BLOCKING]
  - PASS: Todos os ${...}, {{...}}, e template literals preservados.
  - FAIL: Qualquer variavel ou placeholder alterado.
  - Se FAIL: DEPLOY_BLOCKED. Restaurar variaveis originais. Run `*integrity-check`.

- [ ] **PC-06: Significado original preservado** [CRITICAL - 10pts]
  - PASS: Nenhuma frase teve o seu significado alterado pelas correcoes.
  - FAIL: Pelo menos 1 frase com significado diferente apos correcao.
  - Se FAIL: Reverter correcao que alterou significado. Aplicar correcao alternativa que preserve sentido.

### Consistencia

- [ ] **CO-01: Regras aplicadas uniformemente** [MAJOR - 5pts]
  - PASS: Cada regra aplicada cobre 100% das ocorrencias no scope.
  - FAIL: Regra aplicada parcialmente (ex: "contacto" corrigido em 3 de 5 ficheiros).
  - Se FAIL: Run `*consistency-check --scope {scope}` para listar inconsistencias.

- [ ] **CO-02: Sem mistura de variantes** [CRITICAL - 10pts]
  - PASS: Cada ficheiro usa exclusivamente UMA variante linguistica.
  - FAIL: Ficheiro mistura vocabulario/regras de 2+ variantes.
  - Se FAIL: Identificar variante predominante do ficheiro. Run `*grammar-correct` com variante correta.

- [ ] **CO-03: Terminologia consistente entre ficheiros** [MAJOR - 5pts]
  - PASS: Mesmo conceito usa mesmo termo em todos os ficheiros do scope.
  - FAIL: Conceito referido com termos diferentes em ficheiros diferentes.
  - Se FAIL: Escolher termo canonico. Run `*consistency-check` e uniformizar.

- [ ] **CO-04: Capitalizacao uniforme** [MINOR - 2pts]
  - PASS: Nomes proprios, marcas e termos tecnicos com capitalizacao consistente.
  - FAIL: Capitalizacao inconsistente do mesmo termo entre ocorrencias.
  - Se FAIL: Definir capitalizacao canonica e uniformizar.

### Brandbook (se aplicavel)

- [ ] **BB-01: Terminologia conforme brandbook** [MAJOR - 5pts]
  - PASS: Todos os termos usados correspondem a lista aprovada do brandbook.
  - FAIL: Termos proibidos pelo brandbook encontrados.
  - Se FAIL: Run `*brandbook-consistency` para lista completa de desvios.
  - SKIP: Se nenhum brandbook disponivel, marcar N/A (nao conta para score).

- [ ] **BB-02: Tom de voz respeitado** [MAJOR - 5pts]
  - PASS: Tom e registo do texto alinham com guidelines do brandbook.
  - FAIL: Desvio de tom (ex: demasiado informal para contexto corporativo).
  - Se FAIL: Run `*brandbook-consistency` e ajustar tom.
  - SKIP: Se nenhum brandbook disponivel, marcar N/A.

- [ ] **BB-03: Nome da marca no formato correto** [MINOR - 2pts]
  - PASS: Nome da marca escrito conforme brandbook em todas as ocorrencias.
  - FAIL: Nome da marca com capitalizacao/formato incorreto.
  - Se FAIL: Uniformizar conforme brandbook.
  - SKIP: Se nenhum brandbook disponivel, marcar N/A.

- [ ] **BB-04: Sem claims nao aprovados** [MAJOR - 5pts]
  - PASS: Nenhuma afirmacao sobre a marca que nao esteja no brandbook.
  - FAIL: Claims nao verificaveis ou nao aprovados encontrados.
  - Se FAIL: Remover ou reformular claims. Consultar brandbook.
  - SKIP: Se nenhum brandbook disponivel, marcar N/A.

### Formatacao

- [ ] **FM-01: Markdown rendering nao afetado** [CRITICAL - 10pts]
  - PASS: Documento renderiza corretamente (headers, lists, tables, links).
  - FAIL: Correcao quebrou rendering Markdown (header sem #, lista sem -, etc.).
  - Se FAIL: Reverter correcao que quebrou formatacao. Replicar com preservacao.

- [ ] **FM-02: Espacamento e indentacao preservados** [MINOR - 2pts]
  - PASS: Indentacao (tabs/spaces) e espacamento entre secoes inalterados.
  - FAIL: Indentacao alterada ou espacamento modificado.
  - Se FAIL: Restaurar espacamento original.

- [ ] **FM-03: Sem linhas em branco indevidas** [MINOR - 2pts]
  - PASS: Nenhuma linha em branco adicionada ou removida sem razao.
  - FAIL: Linhas em branco extras ou linhas em branco removidas.
  - Se FAIL: Restaurar estrutura de linhas original.

- [ ] **FM-04: Encoding UTF-8 correto** [MAJOR - 5pts]
  - PASS: Todos os caracteres especiais (acentos, cedilhas, etc.) corretamente encoded em UTF-8.
  - FAIL: Caracteres corrompidos (mojibake) ou encoding incorreto.
  - Se FAIL: Reconverter ficheiro para UTF-8. Verificar editor/tool encoding settings.

---

## Score Calculation

### Weight Summary

| Category | Items | Max Weight |
|----------|-------|------------|
| Precisao Linguistica | PL-01 to PL-05 | 32pts |
| Preservacao de Conteudo | PC-06 (non-blocking) | 10pts |
| Consistencia | CO-01 to CO-04 | 22pts |
| Brandbook | BB-01 to BB-04 | 17pts |
| Formatacao | FM-01 to FM-04 | 19pts |
| **Total (non-blocking)** | | **100pts** |

Note: BLOCKING items (PC-01 to PC-05) do not contribute to the score -- they are binary gates.
If any BLOCKING item fails, verdict is DEPLOY_BLOCKED regardless of score.

Brandbook items marked N/A are excluded from both numerator and denominator.

### Calculation Formula

```
max_weight = sum of all applicable non-blocking item weights
passed_weight = sum of weights for PASS items
score = round(passed_weight / max_weight * 100)
```

### Override Rules

1. Any BLOCKING item FAIL = DEPLOY_BLOCKED (score irrelevant)
2. PL-01 FAIL + PL-02 FAIL = REJECTED (precision collapse)
3. CO-02 FAIL (variant mixing) in pre-deploy = DEPLOY_BLOCKED
