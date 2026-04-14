---
task_name: "Review Grammar"
version: "1.0.0"
status: active
responsible_executor: "@{lang}-proofreader"
execution_type: Agent
elicit: false
input:
  - name: "scope"
    type: "string"
    required: false
    description: "Ficheiros corrigidos a revisar"
  - name: "last_corrections"
    type: "boolean"
    required: false
    description: "Usar correcoes do ultimo grammar-correct"
  - name: "lang"
    type: "string"
    required: true
    description: "Variante linguistica (pt-pt, pt-br, en-us, en-uk, fr, es)"
output:
  - name: "verdict"
    type: "string"
    description: "APPROVED | NEEDS_REVISION | REJECTED"
  - name: "issues"
    type: "array"
    description: "Lista de problemas encontrados na revisao"
  - name: "quality_score"
    type: "number"
    description: "Pontuacao de qualidade (0-100)"
action_items:
  - "Step 1: Carregar correcoes anteriores (--last-corrections) ou analisar ficheiro especificado"
  - "Step 2: Carregar data/verdict-thresholds.yaml para limites de veredicto"
  - "Step 3: Carregar data/audit-dimensions.yaml para pesos de dimensao"
  - "Step 4: Avaliar precisao — correcoes sao realmente melhorias?"
  - "Step 5: Avaliar completude — ficou algum erro por corrigir?"
  - "Step 6: Avaliar formatacao — Markdown/code blocks preservados?"
  - "Step 7: Avaliar consistencia — regras aplicadas uniformemente?"
  - "Step 8: Avaliar contexto — significado original preservado?"
  - "Step 9: Calcular quality_score (media ponderada) e emitir veredicto"
  - "Step 10: Gerar relatorio usando templates/review-verdict.md"
acceptance_criteria:
  - "Todas as 5 dimensoes de qualidade foram avaliadas"
  - "Quality score calculado como media ponderada com pesos corretos"
  - "Veredicto corresponde aos thresholds definidos (>=85 APPROVED, 60-84 NEEDS_REVISION, <60 REJECTED)"
  - "Cada issue encontrada inclui ficheiro, linha, descricao e impacto"
  - "Output segue o formato do template review-verdict.md"
references:
  data:
    - "data/verdict-thresholds.yaml"
    - "data/audit-dimensions.yaml"
  templates:
    - "templates/review-verdict.md"
---

# *grammar-review

Revisao de qualidade das correcoes gramaticais aplicadas. Funciona como QA gate linguistico.

## Uso

```
*grammar-review --last-corrections
*grammar-review --file docs/README.md --lang pt-pt
```

## Flow

```
1. Carregar correcoes anteriores
   +-- Se --last-corrections: usar ultimo grammar-correct
   +-- Se --file: analisar ficheiro especificado

2. Verificacoes de qualidade
   +-- Precisao: Correcoes sao realmente melhorias?
   +-- Completude: Ficou algum erro por corrigir?
   +-- Formatacao: Markdown/code blocks preservados?
   +-- Consistencia: Regras aplicadas uniformemente?
   +-- Contexto: Significado original preservado?
   +-- Brandbook: Tom de voz respeitado?

3. Pontuacao
   +-- Cada verificacao: 0-100
   +-- Media ponderada = quality_score
   +-- Threshold: >= 85 APPROVED, 60-84 NEEDS_REVISION, < 60 REJECTED

4. Emitir veredicto
   +-- APPROVED: Qualidade excelente, pronto para merge
   +-- NEEDS_REVISION: Problemas menores, corrigir e re-review
   +-- REJECTED: Problemas graves, refazer correcoes

5. Output
   +-- Veredicto com justificacao
   +-- Quality score breakdown
   +-- Lista de issues (se houver)
```

## Criterios de Qualidade

| Criterio | Peso | Descricao |
|----------|------|-----------|
| Precisao | 30% | Correcoes sao corretas |
| Completude | 20% | Nada ficou por corrigir |
| Formatacao | 20% | Nenhuma formatacao quebrada |
| Consistencia | 15% | Regras uniformes |
| Contexto | 15% | Significado preservado |

## Known Limitation

The same proofreader agent that performs corrections also performs the review.
This is a known self-review limitation. The grammar-auditor (Saramago) provides
the independent QA gate in the subsequent Audit phase of the full-proofread workflow.
