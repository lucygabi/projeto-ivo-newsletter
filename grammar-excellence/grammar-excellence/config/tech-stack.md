# Grammar Excellence — Tech Stack

## Core

- **AI Engine:** Claude (Anthropic) — análise e correção gramatical
- **Formato:** Markdown (.md), YAML (.yaml), texto puro
- **Framework:** AIOX Squad Architecture (task-first)

## Ficheiros Suportados

| Extensão | Tipo | Processamento |
|----------|------|--------------|
| `.md` | Markdown | Parse completo, preservar syntax |
| `.yaml` / `.yml` | YAML | Apenas valores string |
| `.json` | JSON | Apenas valores string |
| `.txt` | Texto puro | Processamento direto |
| `.html` | HTML | Apenas conteúdo de texto, preservar tags |

## Integrações

- **Brandbook:** Leitura de ficheiros de brandbook do projeto
- **Git:** Diff-aware para correções incrementais
- **AIOX Core:** Herança de standards via config.extends
