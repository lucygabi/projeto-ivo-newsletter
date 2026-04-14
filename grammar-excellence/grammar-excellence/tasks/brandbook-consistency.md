---
task_name: "Check Brandbook Consistency"
version: "1.0.0"
status: active
responsible_executor: "@{lang}-proofreader"
execution_type: Agent
elicit: true
input:
  - name: "scope"
    type: "string"
    required: true
    description: "Diretorio ou ficheiro(s) a verificar"
  - name: "brandbook_path"
    type: "string"
    required: false
    description: "Caminho para o brandbook (auto-detect se nao fornecido)"
  - name: "lang"
    type: "string"
    required: true
    description: "Variante linguistica (pt-pt, pt-br, en-us, en-uk, fr, es)"
output:
  - name: "deviations"
    type: "array"
    description: "Lista de desvios do brandbook com ficheiro, linha e correcao sugerida"
  - name: "terminology_issues"
    type: "array"
    description: "Termos incorretos vs termos aprovados pelo brandbook"
  - name: "tone_issues"
    type: "array"
    description: "Desvios de tom de voz relativamente ao brandbook"
  - name: "consistency_score"
    type: "number"
    description: "Pontuacao de consistencia com brandbook (0-100)"
action_items:
  - "Step 1: Localizar brandbook (--brandbook_path ou auto-detect em docs/brandbook*, docs/brand-*, docs/identidade*)"
  - "Step 2: Se brandbook nao encontrado, informar utilizador e abortar (nao inventar regras)"
  - "Step 3: Extrair regras do brandbook — terminologia, tom de voz, nome da marca, taglines"
  - "Step 4: Analisar conteudo do scope contra regras extraidas"
  - "Step 5: Verificar terminologia contra lista aprovada/proibida"
  - "Step 6: Avaliar tom de voz vs guidelines do brandbook"
  - "Step 7: Verificar nome da marca (capitalizacao, formato)"
  - "Step 8: Detetar claims nao aprovados"
  - "Step 9: Gerar relatorio usando templates/brandbook-report.md"
acceptance_criteria:
  - "Brandbook foi localizado e as suas regras foram extraidas corretamente"
  - "Cada desvio inclui referencia a seccao do brandbook violada"
  - "Terminologia verificada contra lista completa do brandbook"
  - "Tom de voz avaliado com exemplos concretos de desvio"
  - "Consistency score calculado com base em desvios encontrados"
  - "Se brandbook nao encontrado, task reporta ausencia sem inventar regras"
references:
  data: []
  templates:
    - "templates/brandbook-report.md"
---

# *brandbook-consistency

Verifica consistencia do conteudo com o brandbook da marca -- terminologia, tom de voz e identidade.

## Uso

```
*brandbook-consistency --scope docs/ --lang pt-pt
*brandbook-consistency --file docs/website-copy.md --brandbook docs/brandbook.md
```

## Precondition

This task requires a brandbook file to exist. If no brandbook is found (neither via
`--brandbook_path` nor via auto-detect), the task reports "No brandbook found" and
produces no deviations. It does NOT invent brandbook rules.

## Flow

```
1. Localizar brandbook
   +-- Se --brandbook_path: usar caminho fornecido
   +-- Auto-detect: procurar em docs/brandbook*, docs/brand-*, docs/identidade*
   +-- Se nao encontrado: reportar ausencia e terminar (NO BRANDBOOK FOUND)

2. Extrair regras do brandbook
   +-- Terminologia aprovada vs proibida
   +-- Tom de voz (formal/informal, tecnico/acessivel)
   +-- Nome da marca e variacoes aprovadas
   +-- Taglines e slogans oficiais
   +-- Regras especificas de comunicacao

3. Analisar conteudo
   +-- Verificar terminologia contra lista aprovada
   +-- Avaliar tom de voz vs guidelines
   +-- Verificar nome da marca (capitalizacao, formato)
   +-- Detetar claims nao aprovados
   +-- Verificar consistencia entre ficheiros

4. Gerar relatorio
   +-- Desvios de terminologia (termo usado -> termo correto)
   +-- Desvios de tom de voz
   +-- Inconsistencias entre ficheiros
   +-- Consistency score (0-100)
   +-- Sugestoes de correcao

5. Output
   +-- Relatorio formatado com acoes recomendadas
```

## Formato de Output

```
Brandbook Consistency Report -- {LANG}
========================================

TERMINOLOGIA
  docs/about.md L5: "empresa" -> "organizacao" (brandbook: S3.2)
  docs/about.md L12: "clientes" -> "parceiros" (brandbook: S4.1)

TOM DE VOZ
  docs/copy.md L8: Tom demasiado informal para contexto corporativo
  docs/copy.md L23: Usar voz ativa (brandbook: S2.1)

NOME DA MARCA
  docs/README.md L1: "callback" -> "CALLBACK" (capitalizacao oficial)

--------------------------------------
Consistency Score: 72/100
3 terminologia | 2 tom de voz | 1 nome da marca
```
