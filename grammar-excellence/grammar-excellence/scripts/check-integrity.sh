#!/bin/bash
# check-integrity.sh — Verify technical integrity after grammar corrections
# Usage: ./check-integrity.sh <file-or-directory> [--json]
#
# Checks performed:
#   1. Code blocks: opening/closing ``` pairs must be balanced
#   2. Front matter: YAML front matter (---) must be properly closed
#   3. URLs: extracted URLs must have valid format
#   4. Variables: ${...} and {{...}} patterns must be well-formed
#   5. Inline code: backtick pairs must be balanced (per line)
#
# Exit codes:
#   0 — All checks passed
#   1 — Errors found
#   2 — Invalid arguments

set -euo pipefail

# --- Defaults ---
TARGET="${1:-.}"
JSON_OUTPUT=false
ERRORS=0
WARNINGS=0
FILES_CHECKED=0
declare -a ERROR_DETAILS=()
declare -a WARNING_DETAILS=()

# --- Help ---
show_help() {
    cat <<'HELP'
Usage: check-integrity.sh <file-or-directory> [--json]

Verify technical integrity of files after grammar corrections.

Arguments:
  <file-or-directory>   Path to check (default: current directory)
  --json                Output results in JSON format

Checks:
  - Code block pairs (``` must be balanced)
  - YAML front matter closure (--- pairs)
  - URL format validity
  - Variable pattern integrity (${...}, {{...}})
  - Inline code backtick balance (per line)

Exit codes:
  0   All checks passed
  1   Errors found
  2   Invalid arguments

Examples:
  ./check-integrity.sh docs/
  ./check-integrity.sh README.md --json
  ./check-integrity.sh . --json
HELP
}

# --- Parse args ---
for arg in "$@"; do
    case "$arg" in
        --json) JSON_OUTPUT=true ;;
        --help|-h) show_help; exit 0 ;;
    esac
done

if [[ ! -e "$TARGET" ]]; then
    echo "Error: '$TARGET' does not exist" >&2
    exit 2
fi

# --- Add error/warning helpers ---
add_error() {
    local file="$1"
    local check="$2"
    local message="$3"
    ERRORS=$((ERRORS + 1))
    ERROR_DETAILS+=("${file}|${check}|${message}")
}

add_warning() {
    local file="$1"
    local check="$2"
    local message="$3"
    WARNINGS=$((WARNINGS + 1))
    WARNING_DETAILS+=("${file}|${check}|${message}")
}

# --- Check a single file ---
check_file() {
    local file="$1"
    FILES_CHECKED=$((FILES_CHECKED + 1))
    local content
    content=$(cat "$file" 2>/dev/null) || return 0

    # 1. Code blocks: count ``` occurrences — must be even
    local code_fence_count
    code_fence_count=$(grep -c '^\s*```' <<< "$content" 2>/dev/null || echo "0")
    if (( code_fence_count % 2 != 0 )); then
        add_error "$file" "code_blocks" "Unbalanced code fences: ${code_fence_count} occurrences (expected even number)"
    fi

    # 2. Front matter: if file starts with ---, must have a closing ---
    local first_line
    first_line=$(head -n 1 "$file" 2>/dev/null)
    if [[ "$first_line" == "---" ]]; then
        # Count --- lines (excluding the first); need at least one closing
        local fm_closing
        fm_closing=$(tail -n +2 <<< "$content" | grep -c '^\s*---\s*$' 2>/dev/null || echo "0")
        if (( fm_closing < 1 )); then
            add_error "$file" "front_matter" "YAML front matter opened but never closed"
        fi
    fi

    # 3. URLs: extract and validate format
    local urls
    urls=$(grep -oE 'https?://[^ )"'"'"'>\]]+' <<< "$content" 2>/dev/null || true)
    if [[ -n "$urls" ]]; then
        while IFS= read -r url; do
            # Basic format check: must have a domain part
            if ! [[ "$url" =~ ^https?://[a-zA-Z0-9] ]]; then
                add_warning "$file" "urls" "Possibly malformed URL: ${url}"
            fi
            # Check for common broken patterns
            if [[ "$url" =~ \.\. ]] || [[ "$url" =~ [[:space:]] ]]; then
                add_warning "$file" "urls" "Suspicious URL pattern: ${url}"
            fi
        done <<< "$urls"
    fi

    # 4. Variables: check ${...} and {{...}} are well-formed
    # ${...} — must have matching closing brace
    local dollar_open dollar_close
    dollar_open=$(grep -o '\${' <<< "$content" | wc -l 2>/dev/null || echo "0")
    dollar_close=$(grep -oP '\$\{[^}]*\}' <<< "$content" | wc -l 2>/dev/null || echo "0")
    if (( dollar_open > dollar_close )); then
        add_error "$file" "variables" "Unclosed \${...} variable pattern: ${dollar_open} opens vs ${dollar_close} closes"
    fi

    # {{...}} — must have matching closing braces
    local mustache_open mustache_close
    mustache_open=$(grep -o '{{' <<< "$content" | wc -l 2>/dev/null || echo "0")
    mustache_close=$(grep -o '}}' <<< "$content" | wc -l 2>/dev/null || echo "0")
    if (( mustache_open != mustache_close )); then
        add_error "$file" "variables" "Unbalanced {{...}} pattern: ${mustache_open} opens vs ${mustache_close} closes"
    fi

    # 5. Inline code: check backtick balance per line (skip code fence lines)
    local line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        # Skip code fence lines
        [[ "$line" =~ ^[[:space:]]*\`\`\` ]] && continue
        # Count single backticks (not triple)
        local cleaned
        cleaned=$(sed 's/```//g' <<< "$line")
        local tick_count
        tick_count=$(tr -cd '`' <<< "$cleaned" | wc -c 2>/dev/null || echo "0")
        if (( tick_count % 2 != 0 )); then
            add_warning "$file" "inline_code" "Line ${line_num}: unbalanced backticks (${tick_count} found)"
        fi
    done <<< "$content"
}

# --- Find and check eligible files ---
if [[ -f "$TARGET" ]]; then
    check_file "$TARGET"
elif [[ -d "$TARGET" ]]; then
    while IFS= read -r -d '' file; do
        check_file "$file"
    done < <(find "$TARGET" -type f \( -name "*.md" -o -name "*.yaml" -o -name "*.yml" -o -name "*.txt" -o -name "*.html" -o -name "*.mdx" -o -name "*.htm" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/.aiox-core/*" ! -path "*/dist/*" ! -path "*/build/*" -print0 2>/dev/null)
else
    echo "Error: '$TARGET' is not a file or directory" >&2
    exit 2
fi

# --- Output results ---
if $JSON_OUTPUT; then
    # Build JSON output
    echo "{"
    echo "  \"target\": \"${TARGET}\","
    echo "  \"files_checked\": ${FILES_CHECKED},"
    echo "  \"errors\": ${ERRORS},"
    echo "  \"warnings\": ${WARNINGS},"
    echo "  \"status\": \"$([ $ERRORS -eq 0 ] && echo "PASS" || echo "FAIL")\","

    # Error details
    echo "  \"error_details\": ["
    local first=true
    for detail in "${ERROR_DETAILS[@]+"${ERROR_DETAILS[@]}"}"; do
        IFS='|' read -r d_file d_check d_msg <<< "$detail"
        $first || echo ","
        printf '    {"file": "%s", "check": "%s", "message": "%s"}' "$d_file" "$d_check" "$d_msg"
        first=false
    done
    echo ""
    echo "  ],"

    # Warning details
    echo "  \"warning_details\": ["
    first=true
    for detail in "${WARNING_DETAILS[@]+"${WARNING_DETAILS[@]}"}"; do
        IFS='|' read -r d_file d_check d_msg <<< "$detail"
        $first || echo ","
        printf '    {"file": "%s", "check": "%s", "message": "%s"}' "$d_file" "$d_check" "$d_msg"
        first=false
    done
    echo ""
    echo "  ]"
    echo "}"
else
    echo "=== Grammar Excellence — Integrity Check ==="
    echo ""
    echo "Target:         ${TARGET}"
    echo "Files checked:  ${FILES_CHECKED}"
    echo "Errors:         ${ERRORS}"
    echo "Warnings:       ${WARNINGS}"
    echo ""

    if (( ERRORS > 0 )); then
        echo "--- ERRORS ---"
        for detail in "${ERROR_DETAILS[@]}"; do
            IFS='|' read -r d_file d_check d_msg <<< "$detail"
            echo "  [${d_check}] ${d_file}: ${d_msg}"
        done
        echo ""
    fi

    if (( WARNINGS > 0 )); then
        echo "--- WARNINGS ---"
        for detail in "${WARNING_DETAILS[@]}"; do
            IFS='|' read -r d_file d_check d_msg <<< "$detail"
            echo "  [${d_check}] ${d_file}: ${d_msg}"
        done
        echo ""
    fi

    if (( ERRORS == 0 )); then
        echo "Result: PASS — All integrity checks passed."
    else
        echo "Result: FAIL — ${ERRORS} error(s) found. Fix before proceeding."
    fi
fi

# Exit with appropriate code
(( ERRORS > 0 )) && exit 1
exit 0
