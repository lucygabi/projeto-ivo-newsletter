#!/bin/bash
# detect-language.sh — Auto-detect language variant of a text file
# Usage: ./detect-language.sh <file> [--json]
#
# Uses heuristics: character patterns, common words, spelling patterns
# Returns: pt-pt, pt-br, en-us, en-uk, fr, es, or unknown
#
# Exit codes:
#   0 — Language detected
#   1 — Language unknown (low confidence)
#   2 — Invalid arguments

set -euo pipefail

# --- Defaults ---
FILE=""
JSON_OUTPUT=false

# --- Help ---
show_help() {
    cat <<'HELP'
Usage: detect-language.sh <file> [--json]

Auto-detect the language variant of a text file using heuristics.

Arguments:
  <file>      Path to the file to analyze
  --json      Output results in JSON format

Supported languages:
  pt-pt   Português (Portugal)
  pt-br   Português (Brasil)
  en-us   English (USA)
  en-uk   English (UK)
  fr      Français
  es      Español

Heuristics used:
  - Character patterns (accents, special characters)
  - Common vocabulary differences between variants
  - Spelling patterns (-ize/-ise, -or/-our, etc.)
  - Grammatical patterns (ênclise, gerúndio, etc.)

Examples:
  ./detect-language.sh README.md
  ./detect-language.sh docs/guide.md --json
HELP
}

# --- Parse args ---
for arg in "$@"; do
    case "$arg" in
        --json) JSON_OUTPUT=true ;;
        --help|-h) show_help; exit 0 ;;
        -*) echo "Error: Unknown option '$arg'" >&2; exit 2 ;;
        *) [[ -z "$FILE" ]] && FILE="$arg" ;;
    esac
done

if [[ -z "$FILE" ]]; then
    echo "Error: No file specified" >&2
    show_help
    exit 2
fi

if [[ ! -f "$FILE" ]]; then
    echo "Error: '$FILE' is not a file or does not exist" >&2
    exit 2
fi

# --- Read file content (first 10KB for performance) ---
CONTENT=$(head -c 10240 "$FILE" 2>/dev/null) || { echo "Error: Cannot read '$FILE'" >&2; exit 2; }

if [[ -z "$CONTENT" ]]; then
    if $JSON_OUTPUT; then
        echo "{\"file\": \"${FILE}\", \"language\": \"unknown\", \"confidence\": 0, \"reason\": \"empty file\"}"
    else
        echo "unknown (empty file)"
    fi
    exit 1
fi

# --- Scoring variables ---
declare -A SCORES
SCORES[pt-pt]=0
SCORES[pt-br]=0
SCORES[en-us]=0
SCORES[en-uk]=0
SCORES[fr]=0
SCORES[es]=0

declare -A EVIDENCE
for lang in pt-pt pt-br en-us en-uk fr es; do
    EVIDENCE[$lang]=""
done

add_score() {
    local lang="$1"
    local points="$2"
    local reason="$3"
    SCORES[$lang]=$(( ${SCORES[$lang]} + points ))
    EVIDENCE[$lang]="${EVIDENCE[$lang]}${reason}; "
}

# --- Helper: count matches ---
count_matches() {
    local pattern="$1"
    echo "$CONTENT" | grep -ciP "$pattern" 2>/dev/null || echo "0"
}

# =========================================
# PT-PT Heuristics
# =========================================

# Vocabulary: PT-PT specific words
for word in ficheiro utilizador telemóvel ecrã autocarro comboio passeio paragem frigorifico peão sandes rebucado; do
    c=$(count_matches "\b${word}\b")
    (( c > 0 )) && add_score "pt-pt" $((c * 5)) "${word}(${c})"
done

# Consonant clusters preserved in PT-PT
for word in contacto facto projecto acto; do
    c=$(count_matches "\b${word}\b")
    (( c > 0 )) && add_score "pt-pt" $((c * 4)) "${word}(${c})"
done

# Grammar: ênclise patterns (pronome após verbo: disse-me, dá-me, envio-te)
c=$(echo "$CONTENT" | grep -cP '\b\w+-([mt]e|se|lhe|nos|vos|lhes)\b' 2>/dev/null || echo "0")
(( c > 0 )) && add_score "pt-pt" $((c * 3)) "ênclise(${c})"

# Grammar: "a + infinitivo" (está a fazer, estou a trabalhar)
c=$(echo "$CONTENT" | grep -ciP '\best(á|ou|amos|ão|ava)\s+a\s+\w+[aei]r\b' 2>/dev/null || echo "0")
(( c > 0 )) && add_score "pt-pt" $((c * 4)) "a+infinitivo(${c})"

# "pequeno-almoço"
c=$(count_matches "pequeno-almoço")
(( c > 0 )) && add_score "pt-pt" $((c * 5)) "pequeno-almoço(${c})"

# =========================================
# PT-BR Heuristics
# =========================================

# Vocabulary: PT-BR specific words
for word in arquivo usuário celular tela ônibus café\ da\ manhã pedestre deletar aplicativo; do
    c=$(count_matches "\b${word}\b")
    (( c > 0 )) && add_score "pt-br" $((c * 5)) "${word}(${c})"
done

# Simplified consonant clusters (PT-BR drops them)
for word in contato fato projeto ato; do
    c=$(count_matches "\b${word}\b")
    (( c > 0 )) && add_score "pt-br" $((c * 3)) "${word}(${c})"
done

# Grammar: gerúndio (está fazendo, estou trabalhando)
c=$(echo "$CONTENT" | grep -ciP '\best(á|ou|amos|ão|ava)\s+\w+(ando|endo|indo)\b' 2>/dev/null || echo "0")
(( c > 0 )) && add_score "pt-br" $((c * 4)) "gerúndio(${c})"

# Próclise (pronome antes do verbo: me diga, te envio)
c=$(echo "$CONTENT" | grep -cP '(?<!\w)\b(me|te|se|nos|vos|lhe|lhes)\s+\w+[aeiou]\b' 2>/dev/null || echo "0")
(( c > 0 )) && add_score "pt-br" $((c * 2)) "próclise(${c})"

# "você" frequent usage
c=$(count_matches '\bvocê\b')
(( c > 2 )) && add_score "pt-br" $((c * 2)) "você(${c})"

# =========================================
# EN-US Heuristics
# =========================================

# Spelling: -ize endings
c=$(echo "$CONTENT" | grep -cP '\b\w+ize[ds]?\b' 2>/dev/null || echo "0")
(( c > 0 )) && add_score "en-us" $((c * 3)) "-ize(${c})"

# Spelling: -or endings (color, favor, honor)
for word in color favor honor labor neighbor humor; do
    c=$(count_matches "\b${word}s?\b")
    (( c > 0 )) && add_score "en-us" $((c * 4)) "${word}(${c})"
done

# Spelling: -er endings (center, meter, fiber)
for word in center meter fiber liter theater; do
    c=$(count_matches "\b${word}s?\b")
    (( c > 0 )) && add_score "en-us" $((c * 3)) "${word}(${c})"
done

# Spelling: -ense (defense, offense, license)
for word in defense offense license; do
    c=$(count_matches "\b${word}\b")
    (( c > 0 )) && add_score "en-us" $((c * 3)) "${word}(${c})"
done

# =========================================
# EN-UK Heuristics
# =========================================

# Spelling: -ise endings
c=$(echo "$CONTENT" | grep -cP '\b\w+ise[ds]?\b' 2>/dev/null || echo "0")
(( c > 0 )) && add_score "en-uk" $((c * 3)) "-ise(${c})"

# Spelling: -our endings (colour, favour, honour)
for word in colour favour honour labour neighbour humour; do
    c=$(count_matches "\b${word}s?\b")
    (( c > 0 )) && add_score "en-uk" $((c * 4)) "${word}(${c})"
done

# Spelling: -re endings (centre, metre, fibre)
for word in centre metre fibre litre theatre; do
    c=$(count_matches "\b${word}s?\b")
    (( c > 0 )) && add_score "en-uk" $((c * 3)) "${word}(${c})"
done

# Spelling: -ence (defence, offence, licence)
for word in defence offence licence; do
    c=$(count_matches "\b${word}\b")
    (( c > 0 )) && add_score "en-uk" $((c * 3)) "${word}(${c})"
done

# =========================================
# FR Heuristics
# =========================================

# French quotes
c=$(echo "$CONTENT" | grep -cP '[«»]' 2>/dev/null || echo "0")
(( c > 0 )) && add_score "fr" $((c * 5)) "guillemets(${c})"

# Common French words
for word in "c'est" "l'on" "qu'il" "d'un" "n'est" "aujourd'hui" "être" "même" "très" "après" "où"; do
    c=$(count_matches "\b${word}\b")
    (( c > 0 )) && add_score "fr" $((c * 3)) "${word}(${c})"
done

# French accent patterns (é, è, ê, ë, à, â, ç, ù, û, ô, î, ï)
c=$(echo "$CONTENT" | grep -cP '[éèêëàâçùûôîï]' 2>/dev/null || echo "0")
(( c > 3 )) && add_score "fr" $((c)) "accents_fr(${c})"

# Articles + determiners
for word in "le" "la" "les" "des" "du" "une" "un"; do
    c=$(count_matches "\b${word}\b")
    (( c > 3 )) && add_score "fr" $((c / 2)) "det_${word}(${c})"
done

# =========================================
# ES Heuristics
# =========================================

# Inverted punctuation
c=$(echo "$CONTENT" | grep -cP '[¿¡]' 2>/dev/null || echo "0")
(( c > 0 )) && add_score "es" $((c * 6)) "¿¡(${c})"

# ñ character
c=$(echo "$CONTENT" | grep -cP 'ñ' 2>/dev/null || echo "0")
(( c > 0 )) && add_score "es" $((c * 4)) "ñ(${c})"

# Common Spanish words
for word in "también" "después" "además" "según" "todavía" "aquí" "está" "años"; do
    c=$(count_matches "\b${word}\b")
    (( c > 0 )) && add_score "es" $((c * 3)) "${word}(${c})"
done

# Spanish determiners
for word in "el" "los" "las" "una" "unos" "unas" "del"; do
    c=$(count_matches "\b${word}\b")
    (( c > 3 )) && add_score "es" $((c / 2)) "det_${word}(${c})"
done

# =========================================
# General Portuguese detection (for base language boost)
# =========================================
c=$(echo "$CONTENT" | grep -ciP '\b(que|para|como|mais|pode|com|não|são|tem|uma)\b' 2>/dev/null || echo "0")
if (( c > 5 )); then
    # Boost both PT variants
    add_score "pt-pt" $((c / 3)) "pt_base(${c})"
    add_score "pt-br" $((c / 3)) "pt_base(${c})"
fi

# General English detection
c=$(echo "$CONTENT" | grep -ciP '\b(the|and|for|with|that|this|from|have|are|not)\b' 2>/dev/null || echo "0")
if (( c > 5 )); then
    add_score "en-us" $((c / 3)) "en_base(${c})"
    add_score "en-uk" $((c / 3)) "en_base(${c})"
fi

# =========================================
# Determine winner
# =========================================
BEST_LANG="unknown"
BEST_SCORE=0
SECOND_SCORE=0

for lang in pt-pt pt-br en-us en-uk fr es; do
    if (( ${SCORES[$lang]} > BEST_SCORE )); then
        SECOND_SCORE=$BEST_SCORE
        BEST_SCORE=${SCORES[$lang]}
        BEST_LANG="$lang"
    elif (( ${SCORES[$lang]} > SECOND_SCORE )); then
        SECOND_SCORE=${SCORES[$lang]}
    fi
done

# Confidence: ratio of best to second-best
if (( BEST_SCORE == 0 )); then
    CONFIDENCE=0
elif (( SECOND_SCORE == 0 )); then
    CONFIDENCE=100
else
    CONFIDENCE=$(( (BEST_SCORE - SECOND_SCORE) * 100 / BEST_SCORE ))
fi

# Low confidence threshold
if (( BEST_SCORE < 5 )); then
    BEST_LANG="unknown"
    CONFIDENCE=0
fi

# --- Output ---
if $JSON_OUTPUT; then
    echo "{"
    echo "  \"file\": \"${FILE}\","
    echo "  \"language\": \"${BEST_LANG}\","
    echo "  \"confidence\": ${CONFIDENCE},"
    echo "  \"score\": ${BEST_SCORE},"
    echo "  \"scores\": {"
    first=true
    for lang in pt-pt pt-br en-us en-uk fr es; do
        $first || echo ","
        printf '    "%s": %d' "$lang" "${SCORES[$lang]}"
        first=false
    done
    echo ""
    echo "  },"
    echo "  \"evidence\": {"
    first=true
    for lang in pt-pt pt-br en-us en-uk fr es; do
        $first || echo ","
        local_ev="${EVIDENCE[$lang]}"
        # Trim trailing "; "
        local_ev="${local_ev%%; }"
        printf '    "%s": "%s"' "$lang" "$local_ev"
        first=false
    done
    echo ""
    echo "  }"
    echo "}"
else
    echo "=== Grammar Excellence — Language Detection ==="
    echo ""
    echo "File:        ${FILE}"
    echo "Language:    ${BEST_LANG}"
    echo "Confidence:  ${CONFIDENCE}%"
    echo "Score:       ${BEST_SCORE}"
    echo ""
    echo "--- All Scores ---"
    for lang in pt-pt pt-br en-us en-uk fr es; do
        printf "  %-8s %3d" "$lang" "${SCORES[$lang]}"
        if [[ -n "${EVIDENCE[$lang]}" ]]; then
            ev="${EVIDENCE[$lang]%%; }"
            echo "  (${ev})"
        else
            echo ""
        fi
    done
fi

# Exit 1 if unknown
[[ "$BEST_LANG" == "unknown" ]] && exit 1
exit 0
