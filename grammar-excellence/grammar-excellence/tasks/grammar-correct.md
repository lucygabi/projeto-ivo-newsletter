---
task_name: "Correct Grammar"
version: "1.0.0"
status: active
responsible_executor: "@{lang}-proofreader"
execution_type: Agent
elicit: true
input:
  - name: "file"
    type: "string"
    required: false
    description: "Ficheiro a corrigir (ou --from-scan para usar ultimo scan)"
  - name: "from_scan"
    type: "boolean"
    required: false
    description: "Usar resultados do ultimo grammar-scan como input"
  - name: "lang"
    type: "string"
    required: true
    description: "Variante linguistica (pt-pt, pt-br, en-us, en-uk, fr, es)"
  - name: "mode"
    type: "string"
    required: false
    description: "auto (aplica tudo) | interactive (confirma cada correcao) | dry-run (mostra sem aplicar). Default: interactive"
output:
  - name: "corrections"
    type: "object"
    description: "Lista de correcoes aplicadas com antes/depois"
  - name: "diff"
    type: "string"
    description: "Diferencas antes/depois por correcao"
  - name: "stats"
    type: "object"
    description: "Contagem de correcoes por tipo"
action_items:
  - "Step 1: Carregar contexto — scan report (se --from-scan) ou analisar ficheiro especificado"
  - "Step 2: Carregar data/common-corrections-{lang}.yaml para padroes conhecidos"
  - "Step 3: Carregar data/technical-terms-whitelist.yaml para termos protegidos"
  - "Step 4: Identificar e marcar todas as zonas protegidas (code blocks, inline code, URLs, front matter, variaveis)"
  - "Step 5: Aplicar correcoes conforme mode (auto/interactive/dry-run)"
  - "Step 6: Gerar diff antes/depois para cada correcao"
  - "Step 7: Produzir relatorio usando templates/correction-report.md"
  - "Step 8: Sugerir *grammar-review para validacao"
acceptance_criteria:
  - "Todas as correcoes sao gramaticalmente validas na variante alvo"
  - "Zero alteracoes em zonas protegidas (code blocks, inline code, URLs, front matter, variaveis)"
  - "Cada correcao inclui contexto (3 linhas antes/depois)"
  - "Termos tecnicos em ingles preservados conforme whitelist"
  - "Brandbook terminology respeitada (se brandbook disponivel)"
  - "Output inclui diff e estatisticas de correcoes"
references:
  data:
    - "data/common-corrections-{lang}.yaml"
    - "data/technical-terms-whitelist.yaml"
  templates:
    - "templates/correction-report.md"
---

# *grammar-correct

Aplica correcoes gramaticais preservando formatacao, code blocks e termos tecnicos.

## Uso

```
*grammar-correct --file docs/README.md --lang pt-pt --mode interactive
*grammar-correct --from-scan --mode auto
*grammar-correct --file docs/guide.md --lang en-us --mode dry-run
```

## Flow

```
1. Carregar contexto
   +-- Se --from-scan: carregar ultimo relatorio de scan
   +-- Se --file: analisar ficheiro especificado
   +-- Se brandbook disponivel: carregar terminologia

2. Proteger zonas intocaveis
   +-- Code blocks (``` ... ```)
   +-- Inline code (`...`)
   +-- URLs e links
   +-- Variaveis e placeholders (${...}, {{...}})
   +-- Front matter YAML (--- ... ---)
   +-- Termos tecnicos em ingles (via data/technical-terms-whitelist.yaml)

3. Aplicar correcoes (conforme mode)
   +-- auto: Aplicar todas as correcoes silenciosamente
   +-- interactive: Mostrar cada correcao e pedir confirmacao
   |   +-- [A]ceitar | [R]ejeitar | [E]ditar | [S]kip all similar
   +-- dry-run: Mostrar diff sem aplicar

4. Gerar diff
   +-- Mostrar antes/depois por correcao
   +-- Preservar contexto (3 linhas)
   +-- Highlight das alteracoes

5. Output
   +-- Numero de correcoes aplicadas
   +-- Diff resumido
   +-- Sugerir: *grammar-review para validacao
```

## Regras de Protecao

| Zona | Acao |
|------|------|
| Code blocks | NUNCA tocar |
| Inline code | NUNCA tocar |
| URLs | NUNCA tocar |
| Front matter | NUNCA tocar |
| Nomes proprios | Verificar capitalizacao apenas |
| Termos tecnicos | Manter em ingles (conforme whitelist) |
| Brandbook terms | Usar versao do brandbook |
