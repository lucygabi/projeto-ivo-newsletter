#!/bin/bash
# validate-quality-gate.sh — Validate quality gate scoring
# Usage: ./validate-quality-gate.sh <checklist-results-json> [--json]
#
# Reads verdict thresholds from data/verdict-thresholds.yaml
# Outputs: APPROVED, NEEDS_REVISION, or REJECTED with score
#
# Input JSON format:
# {
#   "linguistic_accuracy": 90,
#   "content_preservation": 85,
#   "consistency": 80,
#   "brandbook": 75,
#   "formatting": 95
# }
#
# Exit codes:
#   0 — APPROVED
#   1 — NEEDS_REVISION or REJECTED
#   2 — Invalid arguments

set -euo pipefail

# --- Defaults ---
INPUT_FILE=""
JSON_OUTPUT=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQUAD_DIR="$(dirname "$SCRIPT_DIR")"
THRESHOLDS_FILE="${SQUAD_DIR}/data/verdict-thresholds.yaml"

# --- Default thresholds (fallback if YAML not available) ---
THRESHOLD_APPROVED=85
THRESHOLD_NEEDS_REVISION=60
# Weights (must sum to 100)
W_LINGUISTIC=30
W_PRESERVATION=25
W_CONSISTENCY=20
W_BRANDBOOK=15
W_FORMATTING=10
# Minimum per-dimension
MIN_LINGUISTIC=50
MIN_PRESERVATION=70
MIN_CONSISTENCY=40
MIN_BRANDBOOK=30
MIN_FORMATTING=40

# --- Help ---
show_help() {
    cat <<'HELP'
Usage: validate-quality-gate.sh <checklist-results-json> [--json]

Validate quality gate scoring for grammar corrections.

Arguments:
  <checklist-results-json>   Path to JSON file with dimension scores (0-100)
  --json                     Output results in JSON format

Input JSON format:
  {
    "linguistic_accuracy": 90,
    "content_preservation": 85,
    "consistency": 80,
    "brandbook": 75,
    "formatting": 95
  }

Verdicts:
  APPROVED         Score >= 85 and all dimensions above minimum
  NEEDS_REVISION   Score 60-84 or one dimension below minimum
  REJECTED         Score < 60

Thresholds are read from data/verdict-thresholds.yaml (with built-in fallbacks).

Examples:
  ./validate-quality-gate.sh results.json
  ./validate-quality-gate.sh results.json --json
  echo '{"linguistic_accuracy":90,"content_preservation":85,"consistency":80,"brandbook":75,"formatting":95}' | ./validate-quality-gate.sh /dev/stdin
HELP
}

# --- Parse args ---
for arg in "$@"; do
    case "$arg" in
        --json) JSON_OUTPUT=true ;;
        --help|-h) show_help; exit 0 ;;
        -*) echo "Error: Unknown option '$arg'" >&2; exit 2 ;;
        *) [[ -z "$INPUT_FILE" ]] && INPUT_FILE="$arg" ;;
    esac
done

if [[ -z "$INPUT_FILE" ]]; then
    echo "Error: No input file specified" >&2
    show_help
    exit 2
fi

if [[ ! -r "$INPUT_FILE" ]]; then
    echo "Error: Cannot read '$INPUT_FILE'" >&2
    exit 2
fi

# --- Load thresholds from YAML (simple parsing) ---
if [[ -f "$THRESHOLDS_FILE" ]]; then
    val=$(grep -A1 'approved:' "$THRESHOLDS_FILE" | grep 'min_score:' | grep -oP '\d+' | head -1 2>/dev/null) && THRESHOLD_APPROVED="${val:-$THRESHOLD_APPROVED}"
    val=$(grep -A1 'needs_revision:' "$THRESHOLDS_FILE" | grep 'min_score:' | grep -oP '\d+' | head -1 2>/dev/null) && THRESHOLD_NEEDS_REVISION="${val:-$THRESHOLD_NEEDS_REVISION}"

    # Weights
    val=$(grep 'linguistic_accuracy:' "$THRESHOLDS_FILE" | tail -1 | grep -oP '\d+' | head -1 2>/dev/null) && W_LINGUISTIC="${val:-$W_LINGUISTIC}"
    val=$(grep 'content_preservation:' "$THRESHOLDS_FILE" | tail -1 | grep -oP '\d+' | head -1 2>/dev/null) && W_PRESERVATION="${val:-$W_PRESERVATION}"
    val=$(grep 'consistency:' "$THRESHOLDS_FILE" | tail -1 | grep -oP '\d+' | head -1 2>/dev/null) && W_CONSISTENCY="${val:-$W_CONSISTENCY}"
    val=$(grep 'brandbook:' "$THRESHOLDS_FILE" | tail -1 | grep -oP '\d+' | head -1 2>/dev/null) && W_BRANDBOOK="${val:-$W_BRANDBOOK}"
    val=$(grep 'formatting:' "$THRESHOLDS_FILE" | tail -1 | grep -oP '\d+' | head -1 2>/dev/null) && W_FORMATTING="${val:-$W_FORMATTING}"

    # Minimums from minimum_per_dimension section
    val=$(sed -n '/minimum_per_dimension/,/^[^ ]/p' "$THRESHOLDS_FILE" | grep 'linguistic_accuracy:' | grep -oP '\d+' | head -1 2>/dev/null) && MIN_LINGUISTIC="${val:-$MIN_LINGUISTIC}"
    val=$(sed -n '/minimum_per_dimension/,/^[^ ]/p' "$THRESHOLDS_FILE" | grep 'content_preservation:' | grep -oP '\d+' | head -1 2>/dev/null) && MIN_PRESERVATION="${val:-$MIN_PRESERVATION}"
    val=$(sed -n '/minimum_per_dimension/,/^[^ ]/p' "$THRESHOLDS_FILE" | grep 'consistency:' | grep -oP '\d+' | head -1 2>/dev/null) && MIN_CONSISTENCY="${val:-$MIN_CONSISTENCY}"
    val=$(sed -n '/minimum_per_dimension/,/^[^ ]/p' "$THRESHOLDS_FILE" | grep 'brandbook:' | grep -oP '\d+' | head -1 2>/dev/null) && MIN_BRANDBOOK="${val:-$MIN_BRANDBOOK}"
    val=$(sed -n '/minimum_per_dimension/,/^[^ ]/p' "$THRESHOLDS_FILE" | grep 'formatting:' | grep -oP '\d+' | head -1 2>/dev/null) && MIN_FORMATTING="${val:-$MIN_FORMATTING}"
fi

# --- Parse input JSON (lightweight — no jq dependency) ---
extract_json_value() {
    local key="$1"
    local json="$2"
    echo "$json" | grep -oP "\"${key}\"\s*:\s*\K\d+" | head -1
}

INPUT_JSON=$(cat "$INPUT_FILE")

S_LINGUISTIC=$(extract_json_value "linguistic_accuracy" "$INPUT_JSON")
S_PRESERVATION=$(extract_json_value "content_preservation" "$INPUT_JSON")
S_CONSISTENCY=$(extract_json_value "consistency" "$INPUT_JSON")
S_BRANDBOOK=$(extract_json_value "brandbook" "$INPUT_JSON")
S_FORMATTING=$(extract_json_value "formatting" "$INPUT_JSON")

# Validate all scores present
for var_name in S_LINGUISTIC S_PRESERVATION S_CONSISTENCY S_BRANDBOOK S_FORMATTING; do
    if [[ -z "${!var_name:-}" ]]; then
        echo "Error: Missing dimension in input JSON. Required: linguistic_accuracy, content_preservation, consistency, brandbook, formatting" >&2
        exit 2
    fi
done

# --- Calculate weighted score ---
WEIGHTED_SCORE=$(( (S_LINGUISTIC * W_LINGUISTIC + S_PRESERVATION * W_PRESERVATION + S_CONSISTENCY * W_CONSISTENCY + S_BRANDBOOK * W_BRANDBOOK + S_FORMATTING * W_FORMATTING) / 100 ))

# --- Check per-dimension minimums ---
declare -a DIMENSION_FAILURES=()

(( S_LINGUISTIC < MIN_LINGUISTIC )) && DIMENSION_FAILURES+=("linguistic_accuracy: ${S_LINGUISTIC} < ${MIN_LINGUISTIC}")
(( S_PRESERVATION < MIN_PRESERVATION )) && DIMENSION_FAILURES+=("content_preservation: ${S_PRESERVATION} < ${MIN_PRESERVATION}")
(( S_CONSISTENCY < MIN_CONSISTENCY )) && DIMENSION_FAILURES+=("consistency: ${S_CONSISTENCY} < ${MIN_CONSISTENCY}")
(( S_BRANDBOOK < MIN_BRANDBOOK )) && DIMENSION_FAILURES+=("brandbook: ${S_BRANDBOOK} < ${MIN_BRANDBOOK}")
(( S_FORMATTING < MIN_FORMATTING )) && DIMENSION_FAILURES+=("formatting: ${S_FORMATTING} < ${MIN_FORMATTING}")

# --- Determine verdict ---
VERDICT="REJECTED"
if (( WEIGHTED_SCORE >= THRESHOLD_APPROVED )) && (( ${#DIMENSION_FAILURES[@]} == 0 )); then
    VERDICT="APPROVED"
elif (( WEIGHTED_SCORE >= THRESHOLD_NEEDS_REVISION )); then
    VERDICT="NEEDS_REVISION"
fi

# Force NEEDS_REVISION if score is high but dimensions fail
if [[ "$VERDICT" == "APPROVED" ]] && (( ${#DIMENSION_FAILURES[@]} > 0 )); then
    VERDICT="NEEDS_REVISION"
fi

# --- Output ---
if $JSON_OUTPUT; then
    echo "{"
    echo "  \"weighted_score\": ${WEIGHTED_SCORE},"
    echo "  \"verdict\": \"${VERDICT}\","
    echo "  \"dimensions\": {"
    echo "    \"linguistic_accuracy\": {\"score\": ${S_LINGUISTIC}, \"weight\": ${W_LINGUISTIC}, \"minimum\": ${MIN_LINGUISTIC}},"
    echo "    \"content_preservation\": {\"score\": ${S_PRESERVATION}, \"weight\": ${W_PRESERVATION}, \"minimum\": ${MIN_PRESERVATION}},"
    echo "    \"consistency\": {\"score\": ${S_CONSISTENCY}, \"weight\": ${W_CONSISTENCY}, \"minimum\": ${MIN_CONSISTENCY}},"
    echo "    \"brandbook\": {\"score\": ${S_BRANDBOOK}, \"weight\": ${W_BRANDBOOK}, \"minimum\": ${MIN_BRANDBOOK}},"
    echo "    \"formatting\": {\"score\": ${S_FORMATTING}, \"weight\": ${W_FORMATTING}, \"minimum\": ${MIN_FORMATTING}}"
    echo "  },"
    echo "  \"thresholds\": {"
    echo "    \"approved\": ${THRESHOLD_APPROVED},"
    echo "    \"needs_revision\": ${THRESHOLD_NEEDS_REVISION}"
    echo "  },"
    echo "  \"dimension_failures\": ["
    first=true
    for failure in "${DIMENSION_FAILURES[@]+"${DIMENSION_FAILURES[@]}"}"; do
        $first || echo ","
        printf '    "%s"' "$failure"
        first=false
    done
    echo ""
    echo "  ]"
    echo "}"
else
    echo "=== Grammar Excellence — Quality Gate Validation ==="
    echo ""
    echo "Weighted Score:  ${WEIGHTED_SCORE}/100"
    echo "Verdict:         ${VERDICT}"
    echo ""
    echo "--- Dimension Scores ---"
    printf "  %-25s %3d/100  (weight: %2d%%, min: %2d)\n" "Linguistic Accuracy" "$S_LINGUISTIC" "$W_LINGUISTIC" "$MIN_LINGUISTIC"
    printf "  %-25s %3d/100  (weight: %2d%%, min: %2d)\n" "Content Preservation" "$S_PRESERVATION" "$W_PRESERVATION" "$MIN_PRESERVATION"
    printf "  %-25s %3d/100  (weight: %2d%%, min: %2d)\n" "Consistency" "$S_CONSISTENCY" "$W_CONSISTENCY" "$MIN_CONSISTENCY"
    printf "  %-25s %3d/100  (weight: %2d%%, min: %2d)\n" "Brandbook" "$S_BRANDBOOK" "$W_BRANDBOOK" "$MIN_BRANDBOOK"
    printf "  %-25s %3d/100  (weight: %2d%%, min: %2d)\n" "Formatting" "$S_FORMATTING" "$W_FORMATTING" "$MIN_FORMATTING"
    echo ""

    if (( ${#DIMENSION_FAILURES[@]} > 0 )); then
        echo "--- Dimension Failures ---"
        for failure in "${DIMENSION_FAILURES[@]}"; do
            echo "  FAIL: ${failure}"
        done
        echo ""
    fi

    echo "--- Thresholds ---"
    echo "  APPROVED:        >= ${THRESHOLD_APPROVED}"
    echo "  NEEDS_REVISION:  >= ${THRESHOLD_NEEDS_REVISION}"
    echo "  REJECTED:        < ${THRESHOLD_NEEDS_REVISION}"

    echo ""
    case "$VERDICT" in
        APPROVED)
            echo "Result: APPROVED — Quality gate passed. Ready for merge."
            ;;
        NEEDS_REVISION)
            echo "Result: NEEDS_REVISION — Fix identified issues and re-submit."
            ;;
        REJECTED)
            echo "Result: REJECTED — Score too low. Restart correction cycle."
            ;;
    esac
fi

# Exit code
[[ "$VERDICT" == "APPROVED" ]] && exit 0
exit 1
