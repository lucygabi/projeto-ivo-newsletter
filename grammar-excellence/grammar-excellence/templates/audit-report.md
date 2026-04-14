# Grammar Audit Report

**Date:** {{date}}
**Auditor:** Saramago (Grammar Auditor)
**Language:** {{lang}}
**Scope:** {{scope}}
**Mode:** {{mode}}

## Verdict: {{verdict}}

**Quality Score:** {{quality_score}}/100

## Dimension Scores

| Dimension | Weight | Score | Status |
|-----------|--------|-------|--------|
| Precisao Linguistica | 25% | {{precision_score}}/100 | {{precision_status}} |
| Integridade Tecnica | 25% | {{integrity_score}}/100 | {{integrity_status}} |
| Completude | 20% | {{completeness_score}}/100 | {{completeness_status}} |
| Consistencia | 15% | {{consistency_score}}/100 | {{consistency_status}} |
| Contexto | 15% | {{context_score}}/100 | {{context_status}} |

## Issues Found

### Critical
{{#if critical_issues}}
{{#each critical_issues}}
- {{description}} ({{file}}:{{line}})
{{/each}}
{{else}}
No critical issues found.
{{/if}}

### Major
{{#if major_issues}}
{{#each major_issues}}
- {{description}} ({{file}}:{{line}})
{{/each}}
{{else}}
No major issues found.
{{/if}}

### Minor
{{#if minor_issues}}
{{#each minor_issues}}
- {{description}} ({{file}}:{{line}})
{{/each}}
{{else}}
No minor issues found.
{{/if}}

## Blocking Conditions Checked

| Condition | Status |
|-----------|--------|
| Regression detected | {{regression_status}} |
| Code block corrupted | {{codeblock_status}} |
| URL/link broken | {{url_status}} |
| Variable altered | {{variable_status}} |
| Mixed variants | {{mixed_variant_status}} |
| Front matter corrupted | {{frontmatter_status}} |
| Markdown structure broken | {{markdown_status}} |
| Encoding corrupted | {{encoding_status}} |

## Audit Methodology

| Step | Description | Result |
|------|-------------|--------|
| 1 | Random sampling (20% of files) | {{sampling_result}} |
| 2 | Variant purity check | {{variant_purity_result}} |
| 3 | Technical integrity verification | {{integrity_result}} |
| 4 | Consistency cross-check | {{consistency_result}} |
| 5 | Context preservation review | {{context_result}} |

## Deploy Decision

{{#if verdict == "APPROVED"}}
**DEPLOY AUTHORIZED** — Quality score {{quality_score}}/100 meets threshold (>=85)
{{else if verdict == "DEPLOY_BLOCKED"}}
**DEPLOY BLOCKED** — {{blocking_reason}}
Action required: {{blocking_action}}
{{else if verdict == "NEEDS_REVISION"}}
**DEPLOY NOT AUTHORIZED** — Score {{quality_score}}/100 below threshold
Return to proofreader with the following feedback:
{{revision_feedback}}
{{else}}
**DEPLOY NOT AUTHORIZED** — {{verdict}}: {{verdict_reason}}
Full re-correction required. Major issues:
{{rejection_details}}
{{/if}}

---
_Audited by Saramago — Grammar Excellence Squad v1.0_
