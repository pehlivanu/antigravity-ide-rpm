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

## 🔄 Updates

Updates are checked **daily** via GitHub Actions. When a new version is detected:

1. The spec file is automatically updated
2. A COPR rebuild is triggered
3. The new RPM becomes available within ~30 minutes

To update:

```bash
# Updates along with all your other packages
sudo dnf upgrade

# Or update just Antigravity IDE
sudo dnf upgrade antigravity-ide
```

### Want zero manual steps, including the install?

The check → build → publish pipeline above already runs unattended. To also
auto-*install* new builds on your machine (with a desktop notification when
it happens), see [`local-autoupdate/`](local-autoupdate/) — a one-time
`./install.sh` sets up a `systemd --user` timer scoped to just this package.

## 🏗️ How It Works

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  GitHub Actions  │────▶│  Detects new      │────▶│  Updates spec   │
│  (daily cron)    │     │  version from     │     │  + commits +    │
│                  │     │  antigravity.google│     │  tags           │
└─────────────────┘     └──────────────────┘     └────────┬────────┘
                                                           │
                                                           ▼
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  User runs      │◀────│  RPM available    │◀────│  COPR builds    │
│  dnf upgrade    │     │  in repo          │     │  RPM from spec  │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

1. **Daily Check**: GitHub Actions downloads the latest tarball from `antigravity.google/download` and extracts the version from `product.json`
2. **Auto-Update**: If a new version is found, the `.spec` file is updated, committed, and tagged
3. **COPR Webhook**: A webhook triggers the COPR build system
4. **COPR Build**: COPR clones this repo, runs `.copr/Makefile`, downloads the tarball from Google, and builds a native RPM
5. **DNF Update**: The RPM appears in the COPR repo and is available via `sudo dnf upgrade`

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
