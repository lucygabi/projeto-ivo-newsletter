# Grammar Excellence — Source Tree

```
squads/grammar-excellence/
├── squad.yaml                          # Manifest do squad
├── README.md                           # Documentação
├── config/
│   ├── grammar-standards.md            # Standards por variante linguística
│   ├── tech-stack.md                   # Stack tecnológica
│   └── source-tree.md                  # Este ficheiro
├── agents/
│   ├── pt-pt-proofreader.md            # Português Portugal
│   ├── pt-br-proofreader.md            # Português Brasil
│   ├── en-us-proofreader.md            # English USA
│   ├── en-uk-proofreader.md            # English UK
│   ├── fr-proofreader.md              # Français
│   ├── es-proofreader.md              # Español
│   └── grammar-auditor.md             # Auditor (Saramago) — gate pré-deploy
├── tasks/
│   ├── grammar-scan.md                 # Scan e deteção de problemas
│   ├── grammar-correct.md              # Aplicação de correções
│   ├── grammar-review.md               # QA review
│   ├── brandbook-consistency.md        # Consistência brandbook
│   └── audit-deploy-gate.md            # Gate de auditoria pré-deploy
├── workflows/
│   └── full-proofread.yaml             # Workflow completo
├── checklists/
│   └── grammar-quality-gate.md         # Quality gate
├── data/
│   ├── common-corrections-pt-pt.yaml   # Dicionário PT-PT
│   ├── common-corrections-pt-br.yaml   # Dicionário PT-BR
│   ├── common-corrections-en-us.yaml   # Dicionário EN-US
│   ├── common-corrections-en-uk.yaml   # Dicionário EN-UK
│   ├── common-corrections-fr.yaml      # Dicionário FR
│   ├── common-corrections-es.yaml      # Dicionário ES
│   ├── audit-dimensions.yaml           # Dimensões de auditoria
│   ├── exclude-patterns.yaml           # Padrões de exclusão para scan
│   ├── technical-terms-whitelist.yaml   # Whitelist de termos técnicos
│   ├── file-extensions-eligible.yaml   # Extensões elegíveis para scan
│   └── verdict-thresholds.yaml         # Limiares de veredicto quality gate
├── scripts/
│   ├── check-integrity.sh              # Verificação de integridade pós-correção
│   ├── count-eligible-files.sh         # Contagem de ficheiros elegíveis
│   ├── detect-language.sh              # Deteção automática de variante linguística
│   └── validate-quality-gate.sh        # Validação de scoring quality gate
├── templates/
│   └── .gitkeep
└── tools/
    └── .gitkeep
```
