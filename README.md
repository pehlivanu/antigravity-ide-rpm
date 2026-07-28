# Antigravity IDE — Fedora RPM (COPR)

[![Copr build status](https://copr.fedorainfracloud.org/coprs/pehlivanu/antigravity-ide/package/antigravity-ide/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/pehlivanu/antigravity-ide/)
[![Daily Update Check](https://github.com/pehlivanu/antigravity-ide-rpm/actions/workflows/check-update.yml/badge.svg)](https://github.com/pehlivanu/antigravity-ide-rpm/actions/workflows/check-update.yml)

Unofficial community RPM packaging of [Google Antigravity IDE](https://antigravity.google) for Fedora. Enables native installation and automatic updates via `dnf`.

> **⚠️ Disclaimer**: This is an **unofficial**, community-maintained package. Google Antigravity IDE is proprietary software developed by Google. This repository contains only the packaging scripts (spec file, desktop entries, automation) — the Antigravity IDE binary is **never stored here** and is downloaded directly from Google's servers during the RPM build process. This project is not affiliated with, endorsed by, or sponsored by Google.

---

## 🚀 Quick Install

```bash
# Enable the COPR repository
sudo dnf copr enable pehlivanu/antigravity-ide

# Install Antigravity IDE
sudo dnf install antigravity-ide
```

## 🔄 Keeping Antigravity IDE Updated

Once the COPR repo is enabled (see Quick Install above), staying current is
just:

```bash
sudo dnf upgrade
```

Run whenever you like — weekly, or as part of your normal `sudo dnf upgrade`
habit alongside the rest of your system. There's no separate channel or
extra repo to remember: `antigravity-ide` upgrades exactly like any other
`dnf`-managed package, because a daily pipeline behind the scenes keeps the
COPR repo itself current (see **How It Works** below), so the new build is
usually already sitting in the repo by the time you run the command.

If you want that last mile automated too — no need to even remember to run
`dnf upgrade` — see [`local-autoupdate/`](local-autoupdate/): a one-time
`./install.sh` sets up a `systemd --user` timer that checks daily and
installs new builds automatically, with a desktop notification when it does.

### Why doesn't the app itself tell me when an update is available?

It deliberately doesn't, on purpose. Antigravity IDE bundles VS Code's own
in-app updater, which independently pings a Google-owned endpoint and shows
its own "update available" banner — a mechanism this packaging has no
control over and that isn't aware of what's actually published in this COPR
repo. Left alone, it produces confusing false positives (a notification
telling you to update even when you're already on the latest COPR build).
This package clears `product.json`'s `updateUrl` at build time, which is the
sanctioned way VS Code-based apps disable their built-in updater — so `dnf`
is the one and only source of truth for whether a new version is available.
If you ever see an in-app "update available" notification, it's stale
cache from before this fix (`2.1.1-2`+); `sudo dnf upgrade` is always the
authoritative answer.

## 🏗️ How It Works

```
┌────────────────────┐     ┌─────────────────────┐     ┌────────────────────┐
│  GitHub Actions    │────▶│  Detects new        │────▶│  Updates spec      │
│  (daily cron)      │     │  version upstream   │     │  + commits + tags  │
└────────────────────┘     └─────────────────────┘     └──────────┬─────────┘
                                                                   │
                                                                   ▼
┌────────────────────┐     ┌─────────────────────┐     ┌────────────────────┐
│  dnf upgrade       │◀────│  RPM available      │◀────│  COPR builds       │
│  installs it       │     │  in the COPR repo   │     │  RPM from spec     │
└────────────────────┘     └─────────────────────┘     └────────────────────┘
```

Everything from "new version exists" to "the RPM is sitting in the COPR
repo" runs unattended, with no human in the loop:

1. **Daily Check** (`check-update.yml`, 06:00 UTC): GitHub Actions downloads
   the latest tarball from `antigravity.google/download` and extracts the
   version from `product.json`.
2. **Auto-Update**: If it's newer than the version currently in
   `antigravity-ide.spec`, the workflow updates the spec, commits, and tags
   `vX.Y.Z` on `main`.
3. **COPR Webhook**: The workflow pings COPR's build webhook.
4. **COPR Build**: COPR clones this repo, runs `.copr/Makefile` (which
   downloads the real tarballs for x86_64 and aarch64 from Google), and
   builds the RPM via `antigravity-ide.spec`. As part of `%install`, the
   spec also clears `product.json`'s `updateUrl`, disabling the bundled
   in-app updater so it can't produce update notifications that disagree
   with what's actually in the COPR repo (see **Keeping Antigravity IDE
   Updated** above for why).
5. **Published**: The RPM appears in the COPR repo, ready for `sudo dnf
   upgrade` — or fully unattended local installs via
   [`local-autoupdate/`](local-autoupdate/).

**Packaging-only fixes** (no upstream version change, e.g. tweaking
`%install`) don't auto-trigger a COPR rebuild through this pipeline, since
step 2's trigger is gated on an actual version bump. For those, bump
`Release` by hand, commit, and dispatch the workflow manually with
`force_rebuild`:

```bash
gh workflow run check-update.yml -f force_rebuild=true
```

This only pings the COPR webhook to rebuild whatever's currently committed —
it does not touch `Version`/`Release`/the changelog.

## 📁 Repository Structure

```
.
├── .copr/
│   └── Makefile                  # COPR SRPM build integration
├── .github/
│   └── workflows/
│       └── check-update.yml      # Daily version check + auto-update
├── antigravity-ide.spec          # RPM spec file
├── antigravity-ide.desktop       # Desktop launcher entry
├── antigravity-ide-url-handler.desktop  # URL scheme handler
├── antigravity-ide.appdata.xml   # AppStream metadata
├── antigravity-ide-wrapper.sh    # CLI wrapper for /usr/bin/
├── check-version.sh              # Version detection utility
├── local-autoupdate/             # Optional: auto-install updates on your machine
├── LICENSE                       # MIT (packaging scripts only)
├── README.md                     # This file
└── CONTRIBUTING.md               # Contribution guide
```

## 📦 What Gets Installed

| Path | Description |
|---|---|
| `/opt/antigravity-ide/` | Main application (upstream binary) |
| `/usr/bin/antigravity-ide` | CLI wrapper script |
| `/usr/share/applications/antigravity-ide.desktop` | Desktop launcher |
| `/usr/share/applications/antigravity-ide-url-handler.desktop` | URL scheme handler |
| `/usr/share/pixmaps/antigravity-ide.png` | Application icon |
| `/usr/share/metainfo/antigravity-ide.appdata.xml` | AppStream metadata |

## 🛠️ Building Locally

If you want to build the RPM yourself:

```bash
# Install build dependencies
sudo dnf install rpm-build rpmdevtools curl

# Set up rpmbuild tree
rpmdev-setuptree

# Download the tarball
curl -sL -o ~/rpmbuild/SOURCES/Antigravity.tar.gz "https://antigravity.google/download"

# Copy sources
cp antigravity-ide.desktop antigravity-ide-url-handler.desktop \
   antigravity-ide.appdata.xml antigravity-ide-wrapper.sh \
   ~/rpmbuild/SOURCES/

# Build the RPM
rpmbuild -ba antigravity-ide.spec

# Install
sudo dnf install ~/rpmbuild/RPMS/x86_64/antigravity-ide-*.rpm
```

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for details on:

- Reporting issues
- Testing locally
- Submitting pull requests
- Adding support for new Fedora releases

## 📝 Supported Fedora Versions

| Fedora Version | Architecture | Status |
|---|---|---|
| Fedora 40 | x86_64 | ✅ Supported |
| Fedora 41 | x86_64 | ✅ Supported |
| Fedora 42 | x86_64 | ✅ Supported |
| Fedora Rawhide | x86_64 | ✅ Supported |
| Fedora 40+ | aarch64 | 🔜 Planned |

## ⚖️ License

- **Packaging scripts** (this repository): [MIT License](LICENSE)
- **Antigravity IDE** (the application): Proprietary — see [Google's Terms](https://antigravity.google/terms)

The RPM binary is downloaded directly from Google's servers during the build process. This repository does not contain, redistribute, or modify any proprietary Google software.

## 🙏 Acknowledgments

- [Google DeepMind](https://deepmind.google/) for creating Antigravity IDE
- [Fedora COPR](https://copr.fedorainfracloud.org/) for the community build infrastructure
- The Fedora community for making Linux packaging accessible
