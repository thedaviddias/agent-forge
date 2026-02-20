#!/bin/bash
# Content validation script for David's brand voice

FILE="$1"
ERRORS=0

echo "=== Validating: $FILE ==="

# Check for em-dashes
if grep -q "—" "$FILE"; then
    echo "❌ ERROR: Em-dashes (—) found. David NEVER uses these."
    grep -n "—" "$FILE"
    ERRORS=$((ERRORS + 1))
fi

# Check for excessive exclamation marks
EXCLAMATION_COUNT=$(grep -o '!' "$FILE" | wc -l)
if [ "$EXCLAMATION_COUNT" -gt 10 ]; then
    echo "⚠️  WARNING: High exclamation mark count ($EXCLAMATION_COUNT). David uses them sparingly."
fi

# Check for corporate buzzwords
BUZZWORDS="synergy|leverage|holistic|paradigm|disruptive|innovative solution"
if grep -Ei "$BUZZWORDS" "$FILE"; then
    echo "⚠️  WARNING: Possible corporate buzzwords found."
fi

# Check opening - should be specific, not general
FIRST_LINE=$(head -1 "$FILE")
if echo "$FIRST_LINE" | grep -Ei "^(in today's|if you are like me|coming from|i've worked on many)"; then
    echo "⚠️  WARNING: Generic opening detected. David starts with specific moments."
fi

if [ $ERRORS -eq 0 ]; then
    echo "✅ Validation passed (no critical errors)"
    exit 0
else
    echo "❌ Validation failed ($ERRORS critical errors)"
    exit 1
fi
