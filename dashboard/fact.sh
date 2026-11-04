#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FACTS_FILE="$DIR/facts.txt"
LAST_REFILL="$DIR/.last_refill"
WRAP_WIDTH=42
TECH_KEYWORDS="computer|software|hardware|internet|code|algorithm|data|CPU|Linux|program|digital|network|server|database|memory|processor|byte|bit|AI|robot|machine|engineer|science|tech|logic|system|binary|compiler|kernel|chip|transistor|encrypt|quantum|cyber"

# Output today's fact
POOL_SIZE=$(wc -l < "$FACTS_FILE" 2>/dev/null | tr -d ' ')
if [ -z "$POOL_SIZE" ] || [ "$POOL_SIZE" -eq 0 ]; then
  echo "No facts loaded yet."
  exit 0
fi

DOY=$(date +%j | sed 's/^0*//')
[ -z "$DOY" ] && DOY=1
INDEX=$(( (DOY - 1) % POOL_SIZE + 1 ))
FACT=$(sed -n "${INDEX}p" "$FACTS_FILE")
echo "$FACT" | fold -s -w $WRAP_WIDTH

# Refill logic — runs once per day only
TODAY=$(date +%Y-%m-%d)
LAST=$(cat "$LAST_REFILL" 2>/dev/null || echo "")
REMAINING=$(( POOL_SIZE - ((DOY - 1) % POOL_SIZE) ))

if [ "$REMAINING" -le 10 ] && [ "$LAST" != "$TODAY" ]; then
  # Check internet
  if ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1; then
    echo "$TODAY" > "$LAST_REFILL"
    ADDED=0
    ATTEMPTS=0

    while [ "$ADDED" -lt 15 ] && [ "$ATTEMPTS" -lt 60 ]; do
      ATTEMPTS=$((ATTEMPTS + 1))
      RAW=$(curl -s --max-time 5 "https://uselessfacts.jsph.pl/api/v2/facts/random?language=en" 2>/dev/null)
      NEW_FACT=$(echo "$RAW" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('text',''))" 2>/dev/null | tr -d '\r')

      if [ -z "$NEW_FACT" ]; then continue; fi

      # Filter for tech-related facts
      if echo "$NEW_FACT" | grep -qiE "$TECH_KEYWORDS"; then
        # Deduplicate
        if ! grep -qF "$NEW_FACT" "$FACTS_FILE"; then
          echo "$NEW_FACT" >> "$FACTS_FILE"
          ADDED=$((ADDED + 1))
        fi
      fi
    done
  fi
fi
