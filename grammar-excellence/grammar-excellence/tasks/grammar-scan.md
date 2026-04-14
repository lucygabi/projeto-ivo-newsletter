---
task_name: "Scan Grammar"
version: "1.0.0"
status: active
responsible_executor: "@{lang}-proofreader"
execution_type: Hybrid
elicit: true
input:
  - name: "scope"
    type: "string"
    required: true
    description: "Diretorio ou ficheiro(s) a analisar"
  - name: "lang"
    type: "string"
    required: true
    description: "Variante linguistica (pt-pt, pt-br, en-us, en-uk, fr, es, all)"
  - name: "severity"
    type: "string"
    required: false
    description: "Nivel minimo a reportar (error, warning, info). Default: warning"
output:
  - name: "scan_report"
    type: "object"
    description: "Lista de problemas encontrados por ficheiro com severidade e sugestao"
  - name: "summary"
    type: "object"
    description: "Contagem total por severidade (errors, warnings, info)"
  - name: "files_affected"
    type: "array"
    description: "Lista de ficheiros com problemas"
action_items:
  - "Step 1: Elicitar parametros em falta (scope, lang, severity)"
  - "Step 2: Carregar file-extensions-eligible.yaml e exclude-patterns.yaml (DETERMINISTIC)"
  - "Step 3: Listar ficheiros elegiveis filtrando por extensao e excluindo padroes (DETERMINISTIC)"
  - "Step 4: Para cada ficheiro, identificar lingua do conteudo se --lang all (AGENT)"
  - "Step 5: Aplicar regras da variante linguistica usando common-corrections-{lang}.yaml (AGENT)"
  - "Step 6: Classificar cada problema por severidade (error > warning > info) (AGENT)"
  - "Step 7: Registar: ficheiro, linha, problema, regra, sugestao (AGENT)"
  - "Step 8: Gerar relatorio agrupado por ficheiro usando scan-report.md template (DETERMINISTIC)"
  - "Step 9: Mostrar summary e sugerir *grammar-correct --from-scan"
acceptance_criteria:
  - "Todos os ficheiros elegiveis no scope foram analisados"
  - "Zonas protegidas (code blocks, inline code, URLs, front matter) foram excluidas da analise"
  - "Cada problema inclui ficheiro, linha, severidade, descricao e sugestao"
  - "Output segue o formato do template scan-report.md"
  - "Summary mostra contagens corretas por severidade"
references:
  data:
    - "data/file-extensions-eligible.yaml"
    - "data/exclude-patterns.yaml"
    - "data/common-corrections-{lang}.yaml"
  templates:
    - "templates/scan-report.md"
---

# *grammar-scan

Analisa ficheiros do projeto e identifica problemas gramaticais na variante linguistica especificada.

## Execution Model

This task uses **Hybrid** execution:
- **Deterministic (Worker):** File discovery, extension filtering, exclusion pattern matching, report formatting
- **Agent:** Language detection, grammar rule application, severity classification, contextual analysis

## Uso

```
*grammar-scan --lang pt-pt --scope docs/
*grammar-scan --lang all --scope .
*grammar-scan --file docs/README.md --lang en-us
```

## Flow

```
1. Elicitar parametros (se nao fornecidos)
   +-- scope: Que diretorio/ficheiros analisar?
   +-- lang: Que lingua(s)? (pt-pt | pt-br | en-us | en-uk | fr | es | all)
   +-- severity: Nivel minimo? (error | warning | info)

2. [DETERMINISTIC] Detetar ficheiros elegiveis
   +-- Carregar data/file-extensions-eligible.yaml
   +-- Carregar data/exclude-patterns.yaml
   +-- Filtrar por extensao (.md, .yaml, .json, .txt, .html, .tsx, .ts, .jsx)
   +-- Excluir: node_modules, .git, .aiox-core, code blocks
   +-- Listar ficheiros encontrados

3. [AGENT] Analisar cada ficheiro
   +-- Identificar lingua do conteudo (se --lang all)
   +-- Carregar data/common-corrections-{lang}.yaml
   +-- Aplicar regras da variante linguistica
   +-- Classificar por severidade (error > warning > info)
   +-- Registar: ficheiro, linha, problema, regra, sugestao

4. [DETERMINISTIC] Gerar relatorio
   +-- Carregar templates/scan-report.md
   +-- Agrupar por ficheiro
   +-- Ordenar por severidade
   +-- Mostrar summary (X errors, Y warnings, Z info)
   +-- Sugerir: *grammar-correct --from-scan

5. Output formatado
   +-- Tabela com: Ficheiro | Linha | Severidade | Problema | Sugestao
```

## Formato de Output

```
Grammar Scan Report -- {LANG}
===============================

FILE: docs/guia-utilizador.md
  L12 [ERROR]   "contato" -> "contacto" (vocabulario PT-PT)
  L45 [WARNING] "estou fazendo" -> "estou a fazer" (gerundio -> a+infinitivo)
  L78 [INFO]    Virgula opcional antes de "e" em enumeracao

FILE: docs/README.md
  L3  [ERROR]   "usuario" -> "utilizador" (vocabulario PT-PT)

-----------------------------
Summary: 2 errors, 1 warning, 1 info | 2 files affected
Run *grammar-correct --from-scan to apply fixes
```
