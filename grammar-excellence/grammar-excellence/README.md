# Grammar Excellence Squad

Squad de excelência para correção gramatical multilíngue com precisão nativa em 6 variantes linguísticas.

## Línguas Suportadas

| Código | Variante | Agente |
|--------|----------|--------|
| PT-PT | Português (Portugal) | `@pt-pt-proofreader` |
| PT-BR | Português (Brasil) | `@pt-br-proofreader` |
| EN-US | English (USA) | `@en-us-proofreader` |
| EN-UK | English (UK) | `@en-uk-proofreader` |
| FR | Français | `@fr-proofreader` |
| ES | Español | `@es-proofreader` |

## Agentes Especializados

### Proofreaders (6 variantes)
Cada proofreader domina as nuances da sua variante linguística e aplica correções com precisão nativa.

### Grammar Auditor (Saramago)
Auditor independente que valida todas as correções antes do deploy. Funciona como gate bloqueante no workflow `full-proofread`.

## Âmbito de Correção

- **Documentação** — Markdown, READMEs, guides, stories
- **Copy** — Textos de UI/UX, mensagens de erro, labels
- **Brandbook** — Consistência com tom de voz, terminologia aprovada, identidade da marca

## Tasks Disponíveis

| Task | Descrição |
|------|-----------|
| `grammar-scan` | Analisa ficheiros e identifica problemas gramaticais |
| `grammar-correct` | Aplica correções preservando formatação e código |
| `grammar-review` | QA review das correções aplicadas |
| `brandbook-consistency` | Verifica consistência com brandbook e tom de voz |
| `audit-deploy-gate` | Gate de auditoria pré-deploy (bloqueante) |

## Workflow

```
grammar-scan → grammar-correct → grammar-review → brandbook-consistency → audit-deploy-gate → report
```

## Scripts

Scripts bash executáveis para automação e validação:

| Script | Descrição | Uso |
|--------|-----------|-----|
| `check-integrity.sh` | Verifica integridade técnica após correções (code blocks, URLs, variáveis, front matter) | `./scripts/check-integrity.sh <path> [--json]` |
| `count-eligible-files.sh` | Conta e lista ficheiros elegíveis para scan gramatical | `./scripts/count-eligible-files.sh <dir> [--lang <lang>] [--json]` |
| `detect-language.sh` | Deteta automaticamente a variante linguística de um ficheiro | `./scripts/detect-language.sh <file> [--json]` |
| `validate-quality-gate.sh` | Valida scoring do quality gate e emite veredicto | `./scripts/validate-quality-gate.sh <results.json> [--json]` |

Todos os scripts suportam `--help` para documentação completa e `--json` para output estruturado.

## Data

| Ficheiro | Descrição |
|----------|-----------|
| `common-corrections-pt-pt.yaml` | Dicionário de correções PT-PT (ortografia, vocabulário, gramática) |
| `common-corrections-pt-br.yaml` | Dicionário de correções PT-BR |
| `file-extensions-eligible.yaml` | Extensões de ficheiro elegíveis para scanning |
| `verdict-thresholds.yaml` | Limiares e pesos para veredictos do quality gate |

## Quality Gate

O quality gate avalia 5 dimensões com pesos configuráveis:

| Dimensão | Peso | Mínimo |
|----------|------|--------|
| Precisão Linguística | 30% | 50 |
| Preservação de Conteúdo | 25% | 70 |
| Consistência | 20% | 40 |
| Brandbook | 15% | 30 |
| Formatação | 10% | 40 |

**Veredictos:**

| Score | Veredicto | Ação |
|-------|-----------|------|
| >= 85 | APPROVED | Pronto para merge |
| 60-84 | NEEDS_REVISION | Corrigir issues e re-review |
| < 60 | REJECTED | Refazer correções |

## Uso Rápido

```bash
# Ativar agente específico
@pt-pt-proofreader

# Executar scan completo
*grammar-scan --lang all --scope docs/

# Corrigir ficheiro específico
*grammar-correct --file docs/README.md --lang pt-pt

# Review de qualidade
*grammar-review --last-corrections

# Detetar língua de um ficheiro
./scripts/detect-language.sh docs/guide.md

# Contar ficheiros elegíveis
./scripts/count-eligible-files.sh docs/ --lang pt-pt

# Verificar integridade pós-correção
./scripts/check-integrity.sh docs/ --json

# Validar quality gate
./scripts/validate-quality-gate.sh results.json --json
```

## Princípios de Excelência

1. **Precisão nativa** — Cada agente domina as nuances da sua variante
2. **Zero falsos positivos** — Preferir não corrigir a corrigir mal
3. **Preservar intenção** — Manter o significado original do autor
4. **Consistência** — Aplicar regras uniformemente em todo o projeto
5. **Brandbook first** — Terminologia e tom de voz da marca têm prioridade
6. **Integridade técnica** — Correções nunca alteram código, URLs ou variáveis
