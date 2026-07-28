# Contributing to Antigravity IDE RPM Packaging

First off, thank you for considering contributing to this community project! It's people like you that make the open-source and Fedora communities such a great place.

## Scope of This Project

Please note: **This repository only contains the packaging scripts for Fedora.**

- If you have an issue with the packaging itself (e.g., installation fails, desktop entry is missing, CLI wrapper is broken), you are in the right place! Please [open an issue](https://github.com/pehlivanu/antigravity-ide-rpm/issues).
- If you have an issue with the Antigravity IDE application itself (e.g., a bug in the code editor, an agent feature not working), please report it to Google directly. We cannot fix bugs in the proprietary binary.

## How the Automation Works

This project is highly automated:

1. A GitHub Actions workflow (`.github/workflows/check-update.yml`) runs daily.
2. It scrapes `antigravity.google/download` to find the latest version.
3. If a new version is found, it automatically updates `antigravity-ide.spec`, commits the change, and tags it.
4. It then fires a webhook to Fedora COPR.
5. COPR pulls the repo, runs `.copr/Makefile` to download the tarball, and builds the `.rpm`.

## Testing Changes Locally

If you want to modify the `.spec` file or `.desktop` files, you should build the RPM locally to test it.

### Prerequisites

You need standard RPM build tools:

```bash
sudo dnf install rpm-build rpmdevtools curl spectool
```

### Build Workflow

1. Clone this repository:
   ```bash
   git clone https://github.com/pehlivanu/antigravity-ide-rpm.git
   cd antigravity-ide-rpm
   ```

2. Set up your local RPM build tree:
   ```bash
   rpmdev-setuptree
   ```

3. Download the upstream tarball to your SOURCES directory:
   ```bash
   spectool -g -R antigravity-ide.spec
   # Note: spectool might fail if the download URL isn't hardcoded.
   # Alternatively:
   curl -sL -o ~/rpmbuild/SOURCES/Antigravity.tar.gz "https://antigravity.google/download"
   ```

4. Copy the local integration files to SOURCES:
   ```bash
   cp antigravity-ide.desktop antigravity-ide-url-handler.desktop \
      antigravity-ide.appdata.xml antigravity-ide-wrapper.sh \
      ~/rpmbuild/SOURCES/
   ```

5. Build the RPM:
   ```bash
   rpmbuild -ba antigravity-ide.spec
   ```

6. Install and test your newly built RPM:
   ```bash
   sudo dnf install ~/rpmbuild/RPMS/x86_64/antigravity-ide-*.rpm
   ```

## Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-fix`)
3. Commit your changes (`git commit -m 'feat: add amazing fix'`)
4. Push to the branch (`git push origin feature/amazing-fix`)
5. Open a Pull Request

## Adding Support for New Fedora Versions

When a new Fedora version is released (or enters beta), you don't need to change any code here. The repository maintainer simply needs to go to the [COPR project settings](https://copr.fedorainfracloud.org/coprs/pehlivanu/antigravity-ide/edit/) and check the box for the new target chroots (e.g., `fedora-45-x86_64` and `fedora-45-aarch64`).
