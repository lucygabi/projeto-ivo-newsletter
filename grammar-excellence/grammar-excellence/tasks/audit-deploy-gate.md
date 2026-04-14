---
task_name: "Audit Deploy Gate"
version: "1.0.0"
status: active
responsible_executor: "@grammar-auditor"
execution_type: Hybrid
elicit: false
input:
  - name: "scope"
    type: "string"
    required: false
    description: "Diretorio frontend a auditar (default: app/)"
  - name: "lang"
    type: "string"
    required: false
    description: "Variante linguistica principal (default: pt-pt)"
  - name: "mode"
    type: "string"
    required: false
    description: "quick (30% amostragem) | full (100%). Default: full"
output:
  - name: "audit_verdict"
    type: "string"
    description: "APPROVED | NEEDS_REVISION | REJECTED | DEPLOY_BLOCKED"
  - name: "audit_score"
    type: "number"
    description: "Pontuacao de qualidade (0-100)"
  - name: "audit_issues"
    type: "array"
    description: "Lista de problemas encontrados com severidade"
  - name: "report"
    type: "string"
    description: "Relatorio formatado completo"
action_items:
  - "Step 1: [DETERMINISTIC] Carregar file-extensions-eligible.yaml e exclude-patterns.yaml"
  - "Step 2: [DETERMINISTIC] Identificar ficheiros elegiveis no scope, filtrar por extensao"
  - "Step 3: [DETERMINISTIC] Contar strings de texto visivel ao utilizador"
  - "Step 4: [AGENT] Verificar integridade tecnica (code blocks, inline code, URLs, imports, JSX, variaveis)"
  - "Step 5: [AGENT] Verificar precisao linguistica (acentos, regras da variante, concordancia, conjugacao)"
  - "Step 6: [AGENT] Verificar completude (amostragem ou 100%, padroes recorrentes)"
  - "Step 7: [AGENT] Verificar consistencia (terminologia cross-file, tom uniforme)"
  - "Step 8: [AGENT] Verificar contexto (significado preservado, tom mantido)"
  - "Step 9: [DETERMINISTIC] Calcular quality score (media ponderada das 5 dimensoes)"
  - "Step 10: [DETERMINISTIC] Aplicar penalizacoes por regressoes (-10 cada)"
  - "Step 11: [DETERMINISTIC] Aplicar override rules (integrity<50 = DEPLOY_BLOCKED, etc.)"
  - "Step 12: [AGENT] Emitir veredicto fundamentado com evidencia"
  - "Step 13: [DETERMINISTIC] Gerar relatorio usando templates/audit-report.md"
acceptance_criteria:
  - "Todas as 5 dimensoes de auditoria foram avaliadas"
  - "Quality score calculado como media ponderada com pesos corretos"
  - "Regressoes detetadas resultam em DEPLOY_BLOCKED independentemente do score"
  - "Integridade abaixo de 50 resulta em DEPLOY_BLOCKED independentemente do score"
  - "Cada issue inclui ficheiro, linha, severidade, descricao e impacto"
  - "Relatorio segue formato padronizado do grammar-auditor"
  - "Veredicto inclui acao recomendada e proximos passos"
references:
  data:
    - "data/audit-dimensions.yaml"
    - "data/verdict-thresholds.yaml"
    - "data/exclude-patterns.yaml"
    - "data/file-extensions-eligible.yaml"
    - "data/technical-terms-whitelist.yaml"
  templates:
    - "templates/audit-report.md"
---

# *audit-deploy-gate

Gate obrigatorio pre-deploy. O Saramago audita todo o conteudo linguistico do frontend antes de autorizar o deploy. Este gate e **bloqueante** -- se falhar, o deploy nao avanca.

## Execution Model

This task uses **Hybrid** execution:
- **Deterministic (Worker):** File discovery, extension filtering, score calculation, penalty application, override rules, report generation
- **Agent:** Integrity verification, precision analysis, completeness assessment, consistency checking, context evaluation, verdict rationale

## Uso

```
@grammar-auditor

*audit-deploy-gate
# -> Audita app/ em PT-PT, modo full (default)

*audit-deploy-gate --scope app/ --lang pt-pt --mode full
# -> Auditoria completa (100% do conteudo)

*audit-deploy-gate --scope app/lib/content/ --mode quick
# -> Apenas ficheiros de conteudo, 30% amostragem
```

## Quando Executar

- **OBRIGATORIO** antes de qualquer deploy do projeto
- **RECOMENDADO** apos cada sessao de correcao gramatical
- **OPCIONAL** durante desenvolvimento para validacao intermedia

## Flow

```
1. [DETERMINISTIC] Identificar ficheiros elegiveis
   +-- Carregar data/file-extensions-eligible.yaml
   +-- Carregar data/exclude-patterns.yaml
   +-- Filtrar por extensao (.tsx, .ts, .jsx, .md, etc.)
   +-- Excluir: node_modules, .next, ficheiros de config
   +-- Focar em: string literals com texto visivel ao utilizador
   +-- Listar ficheiros e contagem de strings

2. [AGENT] Verificar integridade tecnica (peso: 25%)
   +-- Code blocks inalterados
   +-- Inline code intacto
   +-- URLs e links preservados
   +-- Front matter / imports intactos
   +-- JSX structure preservada
   +-- Variaveis e template literals corretos

3. [AGENT] Verificar precisao linguistica (peso: 25%)
   +-- Acentos/diacriticos presentes e corretos
   +-- Regras da variante respeitadas
   +-- Concordancia genero/numero
   +-- Conjugacao verbal
   +-- Sem mistura de variantes (PT-PT com PT-BR)

4. [AGENT] Verificar completude (peso: 20%)
   +-- Amostragem aleatoria para erros nao detetados
   +-- Padroes recorrentes verificados
   +-- Verificacao de termos-chave do projeto

5. [AGENT] Verificar consistencia (peso: 15%)
   +-- Mesma terminologia entre ficheiros
   +-- Tom uniforme
   +-- Regras aplicadas de forma homogenea

6. [AGENT] Verificar contexto (peso: 15%)
   +-- Significado original preservado
   +-- Tom pedagogico mantido (para curso)
   +-- Nenhuma frase ambigua introduzida

7. [DETERMINISTIC] Calcular quality score
   +-- Media ponderada das 5 dimensoes
   +-- Penalizacoes por regressoes (-10 cada)
   +-- Override rules aplicadas

8. [AGENT+DETERMINISTIC] Emitir veredicto
   +-- >= 85: APPROVED -- deploy autorizado
   +-- 60-84: NEEDS_REVISION -- devolver aos revisores
   +-- < 60: REJECTED -- refazer correcoes
   +-- Regressao ou integrity<50: DEPLOY_BLOCKED -- corrigir antes de tudo

9. [DETERMINISTIC] Gerar relatorio
   +-- Formato padronizado do grammar-auditor
```

## Integracao com Deploy

```
Fluxo pre-deploy:

  @{lang}-proofreader *grammar-scan --scope app/
         |
  @{lang}-proofreader *grammar-correct --from-scan
         |
  @grammar-auditor *audit-deploy-gate --scope app/
         |
  Se APPROVED -> @devops pode fazer deploy
  Se outro veredicto -> BLOQUEAR deploy, corrigir primeiro
```

## Criterios de Bloqueio Imediato

Independentemente do score, o deploy e **BLOQUEADO** se:

| Criterio | Exemplo |
|----------|---------|
| Regressao detetada | Texto correto ficou incorreto apos correcao |
| Code block corrompido | Codigo dentro de ``` alterado |
| URL/link partido | Link modificado ou truncado |
| Variavel alterada | ${variable} ou {{placeholder}} modificado |
| Mistura de variantes | PT-PT e PT-BR no mesmo ficheiro |
| Integridade < 50 | Multiplas zonas protegidas corrompidas |
