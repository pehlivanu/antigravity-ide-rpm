# Fully Automatic Local Updates

The rest of this repository automates everything up to "the RPM is published
in the COPR repo" (see the [main README](../README.md#-how-it-works)):
daily version check → spec update → commit/tag → COPR rebuild → published
package. That part requires no action from anyone.

The one remaining manual step is on each user's own machine: running
`sudo dnf upgrade` to actually install the new build. This directory closes
that last gap with a `systemd --user` timer that checks daily and installs
updates automatically, with a desktop notification when it does.

## What it does

- `antigravity-ide-autoupdate.sh` — checks `dnf check-update antigravity-ide`;
  if a newer build is available, runs `dnf upgrade -y antigravity-ide` and
  sends a desktop notification.
- `antigravity-ide-autoupdate.timer` — runs the above daily (10:00 local
  time, a few hours after the upstream 06:00 UTC check-and-build, with a
  30-minute random delay and catch-up if the machine was off).
- A scoped `/etc/sudoers.d` rule grants `NOPASSWD` for **exactly**
  `/usr/bin/dnf upgrade -y antigravity-ide` — nothing broader. It does not
  grant any other sudo access, and no other package is auto-updated.

## Install

```bash
./install.sh
```

This is interactive on purpose: it needs your sudo password once, to write
the scoped sudoers rule. After that single run, updates are fully automatic
— nothing else to do when a new Antigravity IDE version ships.

## Uninstall

```bash
systemctl --user disable --now antigravity-ide-autoupdate.timer
rm ~/.config/systemd/user/antigravity-ide-autoupdate.{service,timer}
rm ~/.local/bin/antigravity-ide-autoupdate.sh
sudo rm /etc/sudoers.d/antigravity-ide-autoupdate
```
