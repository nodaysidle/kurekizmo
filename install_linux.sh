#!/usr/bin/env bash
# Install Kurek on Arch Linux / Omarchy Quattro

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "=== Installing Kurek on Linux ==="

# 1. Ensure Python virtualenv exists
if [ ! -d "$DIR/.venv" ]; then
    echo "Creating virtual environment with uv..."
    if command -v uv >/dev/null 2>&1; then
        uv venv .venv --python 3.12
        uv pip install --python .venv/bin/python numpy sounddevice requests faster-whisper pyautogui pyperclip duckduckgo_search psutil playwright
    else
        python3 -m venv .venv
        .venv/bin/pip install numpy sounddevice requests faster-whisper pyautogui pyperclip duckduckgo_search psutil playwright
    fi
fi

# 2. Install desktop icon
mkdir -p "$HOME/.local/share/icons/hicolor/512x512/apps"
cp "$DIR/desktop/kurek.png" "$HOME/.local/share/icons/kurek.png"
cp "$DIR/desktop/kurek.png" "$HOME/.local/share/icons/hicolor/512x512/apps/kurek.png"

# 3. Install CLI binary
mkdir -p "$HOME/.local/bin"
cp "$DIR/bin/kurek" "$HOME/.local/bin/kurek"
chmod +x "$HOME/.local/bin/kurek"

# 4. Install Desktop Entry
mkdir -p "$HOME/.local/share/applications"
cp "$DIR/desktop/kurek.desktop" "$HOME/.local/share/applications/kurek.desktop"
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

echo "✅ Kurek installed successfully!"
echo "👉 Launch via app launcher (Super+Space) -> 'Kurek'"
echo "👉 Or run from terminal: kurek toggle"
