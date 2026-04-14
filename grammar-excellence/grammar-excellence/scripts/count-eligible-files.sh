#!/bin/bash
# count-eligible-files.sh — Count and list files eligible for grammar scanning
# Usage: ./count-eligible-files.sh <directory> [--lang <lang>] [--json]
#
# Reads eligible extensions from data/file-extensions-eligible.yaml
# Lists files by extension with counts and optional language filtering.
#
# Exit codes:
#   0 — Success
#   2 — Invalid arguments

set -euo pipefail

# --- Defaults ---
TARGET="${1:-.}"
LANG_FILTER=""
JSON_OUTPUT=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQUAD_DIR="$(dirname "$SCRIPT_DIR")"
EXTENSIONS_FILE="${SQUAD_DIR}/data/file-extensions-eligible.yaml"

# --- Help ---
show_help() {
    cat <<'HELP'
Usage: count-eligible-files.sh <directory> [--lang <lang>] [--json]

Count and list files eligible for grammar scanning.

Arguments:
  <directory>       Directory to scan (default: current directory)
  --lang <lang>     Filter by language heuristic (pt-pt, pt-br, en-us, en-uk, fr, es)
  --json            Output results in JSON format

Extensions are read from data/file-extensions-eligible.yaml.
If the config file is missing, defaults to: .md .yaml .yml .txt .html

Examples:
  ./count-eligible-files.sh docs/
  ./count-eligible-files.sh . --lang pt-pt
  ./count-eligible-files.sh src/ --json
  ./count-eligible-files.sh . --lang en-us --json
HELP
}

# --- Parse args ---
POSITIONAL=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --json) JSON_OUTPUT=true; shift ;;
        --lang) LANG_FILTER="$2"; shift 2 ;;
        --help|-h) show_help; exit 0 ;;
        -*) echo "Error: Unknown option '$1'" >&2; exit 2 ;;
        *) POSITIONAL+=("$1"); shift ;;
    esac
done
set -- "${POSITIONAL[@]+"${POSITIONAL[@]}"}"
TARGET="${1:-.}"

if [[ ! -d "$TARGET" ]]; then
    echo "Error: '$TARGET' is not a directory" >&2
    exit 2
fi

# --- Load extensions from YAML (simple parser) ---
load_extensions() {
    if [[ -f "$EXTENSIONS_FILE" ]]; then
        # Extract lines with "- .ext" pattern
        grep -oP '^\s*-\s+\K\.\w+' "$EXTENSIONS_FILE" 2>/dev/null | sort -u
    else
        # Fallback defaults
        echo ".md"
        echo ".yaml"
        echo ".yml"
        echo ".txt"
        echo ".html"
    fi
}

EXTENSIONS=()
while IFS= read -r ext; do
    EXTENSIONS+=("$ext")
done < <(load_extensions)

# --- Build find expression ---
FIND_ARGS=()
first=true
for ext in "${EXTENSIONS[@]}"; do
    if $first; then
        FIND_ARGS+=("(" "-name" "*${ext}")
        first=false
    else
        FIND_ARGS+=("-o" "-name" "*${ext}")
    fi
done
FIND_ARGS+=(")")

# Exclusions
EXCLUDE_ARGS=(
    "!" "-path" "*/node_modules/*"
    "!" "-path" "*/.git/*"
    "!" "-path" "*/.aiox-core/*"
    "!" "-path" "*/dist/*"
    "!" "-path" "*/build/*"
    "!" "-path" "*/coverage/*"
    "!" "-path" "*/__pycache__/*"
    "!" "-path" "*/.next/*"
    "!" "-path" "*/vendor/*"
)

# --- Detect language of a file (lightweight) ---
detect_lang_quick() {
    local file="$1"
    local sample
    sample=$(head -c 2000 "$file" 2>/dev/null) || return

    # PT-PT markers
    if echo "$sample" | grep -qiP '(ficheiro|utilizador|contacto|facto|ecrã|telemóvel|está a |pequeno-almoço)'; then
        echo "pt-pt"; return
    fi
    # PT-BR markers
    if echo "$sample" | grep -qiP '(arquivo|usuário|contato|fato|tela|celular|está fazendo|café da manhã)'; then
        echo "pt-br"; return
    fi
    # EN-UK markers
    if echo "$sample" | grep -qiP '\b(colour|favour|organisation|specialise|analyse|centre|licence)\b'; then
        echo "en-uk"; return
    fi
    # EN-US markers
    if echo "$sample" | grep -qiP '\b(color|favor|organization|specialize|analyze|center|license)\b'; then
        echo "en-us"; return
    fi
    # FR markers
    if echo "$sample" | grep -qP '[«»]|(\bune?\b.*\b(est|sont|avec)\b)'; then
        echo "fr"; return
    fi
    # ES markers
    if echo "$sample" | grep -qP '[¿¡ñ]|(\b(una?|los?|las?|del?)\b.*\b(es|son|con)\b)'; then
        echo "es"; return
    fi

    echo "unknown"
}

# --- Collect files ---
declare -A EXT_COUNTS
declare -A EXT_FILES
TOTAL=0

while IFS= read -r -d '' file; do
    # Language filter
    if [[ -n "$LANG_FILTER" ]]; then
        file_lang=$(detect_lang_quick "$file")
        [[ "$file_lang" != "$LANG_FILTER" ]] && continue
    fi

    ext=".${file##*.}"
    EXT_COUNTS["$ext"]=$(( ${EXT_COUNTS["$ext"]:-0} + 1 ))
    EXT_FILES["$ext"]="${EXT_FILES["$ext"]:-}${file}"$'\n'
    TOTAL=$((TOTAL + 1))
done < <(find "$TARGET" -type f "${FIND_ARGS[@]}" "${EXCLUDE_ARGS[@]}" -print0 2>/dev/null)

# --- Output ---
if $JSON_OUTPUT; then
    echo "{"
    echo "  \"directory\": \"${TARGET}\","
    [[ -n "$LANG_FILTER" ]] && echo "  \"language_filter\": \"${LANG_FILTER}\"," || echo "  \"language_filter\": null,"
    echo "  \"total_files\": ${TOTAL},"
    echo "  \"by_extension\": {"

    first=true
    for ext in $(echo "${!EXT_COUNTS[@]}" | tr ' ' '\n' | sort); do
        $first || echo ","
        printf '    "%s": %d' "$ext" "${EXT_COUNTS[$ext]}"
        first=false
    done
    echo ""
    echo "  },"

    echo "  \"files\": ["
    first=true
    for ext in $(echo "${!EXT_FILES[@]}" | tr ' ' '\n' | sort); do
        while IFS= read -r file; do
            [[ -z "$file" ]] && continue
            $first || echo ","
            printf '    "%s"' "$file"
            first=false
        done <<< "${EXT_FILES[$ext]}"
    done
    echo ""
    echo "  ]"
    echo "}"
else
    echo "=== Grammar Excellence — Eligible Files ==="
    echo ""
    echo "Directory:  ${TARGET}"
    [[ -n "$LANG_FILTER" ]] && echo "Language:   ${LANG_FILTER}"
    echo "Total:      ${TOTAL} file(s)"
    echo ""

    if (( TOTAL > 0 )); then
        echo "--- By Extension ---"
        for ext in $(echo "${!EXT_COUNTS[@]}" | tr ' ' '\n' | sort); do
            printf "  %-10s %d file(s)\n" "$ext" "${EXT_COUNTS[$ext]}"
        done
        echo ""

        echo "--- File List ---"
        for ext in $(echo "${!EXT_FILES[@]}" | tr ' ' '\n' | sort); do
            while IFS= read -r file; do
                [[ -z "$file" ]] && continue
                echo "  ${file}"
            done <<< "${EXT_FILES[$ext]}"
        done
    else
        echo "No eligible files found."
    fi
fi

exit 0
