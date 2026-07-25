#!/bin/bash
# ============================================================================
# install.sh — Set up fully automatic local updates for antigravity-ide.
#
# Installs:
#   - ~/.local/bin/antigravity-ide-autoupdate.sh   (check + upgrade + notify)
#   - ~/.config/systemd/user/antigravity-ide-autoupdate.{service,timer}
#   - /etc/sudoers.d/antigravity-ide-autoupdate     (NOPASSWD for exactly
#     `dnf upgrade -y antigravity-ide`, nothing broader)
#
# Run this once, interactively, as the user who should receive updates.
# It will prompt for your sudo password to install the sudoers rule.
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_USER="$(id -un)"

echo "==> Installing antigravity-ide-autoupdate.sh to ~/.local/bin/"
mkdir -p "$HOME/.local/bin"
install -m 755 "$SCRIPT_DIR/antigravity-ide-autoupdate.sh" "$HOME/.local/bin/antigravity-ide-autoupdate.sh"

echo "==> Installing systemd --user unit files"
mkdir -p "$HOME/.config/systemd/user"
install -m 644 "$SCRIPT_DIR/antigravity-ide-autoupdate.service" "$HOME/.config/systemd/user/antigravity-ide-autoupdate.service"
install -m 644 "$SCRIPT_DIR/antigravity-ide-autoupdate.timer" "$HOME/.config/systemd/user/antigravity-ide-autoupdate.timer"

echo "==> Preparing scoped sudoers rule for ${TARGET_USER} (requires sudo password)"
SUDOERS_TMP="$(mktemp)"
trap 'rm -f "$SUDOERS_TMP"' EXIT
cat > "$SUDOERS_TMP" <<EOF
# Installed by antigravity-ide-rpm/local-autoupdate/install.sh
# Allows ${TARGET_USER} to run exactly this one dnf upgrade command without a
# password, for the antigravity-ide-autoupdate systemd --user timer.
# No other command or package is covered by this rule.
${TARGET_USER} ALL=(root) NOPASSWD: /usr/bin/dnf upgrade -y antigravity-ide
EOF

sudo visudo -c -f "$SUDOERS_TMP"
sudo install -m 0440 -o root -g root "$SUDOERS_TMP" /etc/sudoers.d/antigravity-ide-autoupdate
echo "    Installed /etc/sudoers.d/antigravity-ide-autoupdate"

echo "==> Enabling the systemd --user timer"
systemctl --user daemon-reload
systemctl --user enable --now antigravity-ide-autoupdate.timer

echo
echo "Done. Status:"
systemctl --user list-timers antigravity-ide-autoupdate.timer --no-pager

cat <<'MSG'

From now on, antigravity-ide-autoupdate.timer checks daily and silently runs
`dnf upgrade -y antigravity-ide` whenever the COPR repo has a newer build,
then sends a desktop notification. No manual steps required.

Useful commands:
  systemctl --user status antigravity-ide-autoupdate.timer   # check the timer
  journalctl --user -t antigravity-ide-autoupdate -e         # see recent runs
  systemctl --user start antigravity-ide-autoupdate.service  # run a check now
  systemctl --user disable --now antigravity-ide-autoupdate.timer  # turn it off
MSG
