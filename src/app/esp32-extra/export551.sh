#!/bin/bash
# export551.sh - Configure ESP-IDF environment for cForth

# Get version from parameter or use default
ESP_IDF_VERSION="${1:-v5.5.1}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFORTH_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
ESP_IDF_PATH="$CFORTH_ROOT/esp-idf-$ESP_IDF_VERSION"
EXPORT_SH="$ESP_IDF_PATH/export.sh"

# The simple line to add to shell configs
SHELL_LINE='# ESP-IDF cForth
if [ -f "'"$EXPORT_SH"'" ]; then
    . '"$EXPORT_SH"' > /dev/null 2>&1
    export IDF_COMPONENT_MANAGER=0
    echo "ESP-IDF exported"
else
    echo "ESP-IDF: NOT FOUND - Run '\''make sdk'\''"
fi'

# Fish shell line
FISH_LINE='# ESP-IDF cForth
if test -f "'"$EXPORT_SH"'"
    source '"$EXPORT_SH"' > /dev/null 2>&1
    set -x IDF_COMPONENT_MANAGER 0
    echo "ESP-IDF exported"
else
    echo "ESP-IDF: NOT FOUND - Run '\''make sdk'\''"
end'

# Configure shell startup files
declare -a FILES=(
    "$HOME/.bashrc"
    "$HOME/.zshrc"
    "$HOME/.config/fish/config.fish"
)

for FILE in "${FILES[@]}"; do
    mkdir -p "$(dirname "$FILE")"
    
    if [[ "$FILE" == *"fish"* ]]; then
        if ! grep -Fq "$EXPORT_SH" "$FILE" 2>/dev/null; then
            echo "" >> "$FILE"
            echo "$FISH_LINE" >> "$FILE"
            echo "Added to: $FILE"
        fi
    else
        if ! grep -Fq "$EXPORT_SH" "$FILE" 2>/dev/null; then
            echo "" >> "$FILE"
            echo "$SHELL_LINE" >> "$FILE"
            echo "Added to: $FILE"
        fi
    fi
done

# For current session
if [ -f "$EXPORT_SH" ]; then
    . "$EXPORT_SH"
    export IDF_COMPONENT_MANAGER=0
    echo "ESP-IDF exported"
else
    echo "ERROR: ESP-IDF not found at $ESP_IDF_PATH"
    echo "Run 'make sdk' to install ESP-IDF"
    exit 1
fi
