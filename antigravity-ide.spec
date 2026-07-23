# ============================================================================
# antigravity-ide.spec — Fedora RPM spec for Google Antigravity IDE
# ============================================================================
# This is an unofficial community package. Antigravity IDE is proprietary
# software developed by Google. This spec file simply repackages the upstream
# pre-built Linux tarball for convenient installation via DNF.
# ============================================================================

%global debug_package   %{nil}
%global __strip         /bin/true
%global _build_id_links none

# Upstream tarball extracts to "Antigravity-x64/" (or "Antigravity-arm64/")
%global upstream_name   Antigravity
%global install_dir     /opt/%{name}

Name:           antigravity-ide
Version:        2.1.1
Release:        1%{?dist}
Summary:        Google Antigravity IDE — An agentic AI development platform
License:        LicenseRef-Google-Antigravity
URL:            https://antigravity.google/

# The tarballs are downloaded at build time via the .copr/Makefile
# URL_X64:        https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/2.1.1-6123990880747520/linux-x64/Antigravity%20IDE.tar.gz
# URL_ARM64:      https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/2.1.1-6123990880747520/linux-arm/Antigravity%20IDE.tar.gz
Source0:        Antigravity-x64.tar.gz
Source1:        Antigravity-arm64.tar.gz

# Desktop and system integration files (shipped in this repo)
Source2:        antigravity-ide.desktop
Source3:        antigravity-ide-url-handler.desktop
Source4:        antigravity-ide.appdata.xml
Source5:        antigravity-ide-wrapper.sh

ExclusiveArch:  x86_64 aarch64

# ---- Disable automatic dependency scanning ----
# The upstream binary bundles its own Electron/Chromium/Node.js runtime.
# Scanning it would generate hundreds of false requires/provides and
# potentially conflict with system libraries.
AutoReqProv:    no

# ---- Runtime dependencies ----
# These are the system libraries the bundled Chromium expects to dlopen().
Requires:       alsa-lib
Requires:       at-spi2-core
Requires:       bash
Requires:       cairo
Requires:       cups-libs
Requires:       curl
Requires:       dbus-libs
Requires:       expat
Requires:       glib2
Requires:       glibc
Requires:       gtk3
Requires:       libgcc
Requires:       libX11
Requires:       libXcomposite
Requires:       libXdamage
Requires:       libXext
Requires:       libXfixes
Requires:       libXrandr
Requires:       libxcb
Requires:       libxkbcommon
Requires:       libxkbfile
Requires:       libsecret
Requires:       libsoup3
Requires:       libstdc++
Requires:       mesa-libgbm
Requires:       nspr
Requires:       nss
Requires:       openssl
Requires:       pango
Requires:       systemd-libs
Requires:       webkit2gtk4.1

%description
Google Antigravity IDE is an agentic AI development platform from Google,
evolving the IDE into the agent-first era.

This is an UNOFFICIAL community package for Fedora. It repackages the
upstream prebuilt Linux release under /opt/antigravity-ide and provides
a command-line wrapper and desktop entries.

# ============================================================================
%prep
# Extract into a clean directory regardless of the tarball's internal structure
%setup -q -c -T -n %{name}-%{version}

%ifarch x86_64
tar xzf %{SOURCE0} --strip-components=1
%endif

%ifarch aarch64
tar xzf %{SOURCE1} --strip-components=1
%endif

# ============================================================================
%install
# Install the IDE to /opt/antigravity-ide/
mkdir -p %{buildroot}%{install_dir}
cp -a . %{buildroot}%{install_dir}/

# Rename the upstream binary "antigravity" → "antigravity-ide" inside /opt
# to match the package name and avoid PATH conflicts.
if [ -f %{buildroot}%{install_dir}/antigravity ] && \
   [ ! -f %{buildroot}%{install_dir}/antigravity-ide ]; then
    mv %{buildroot}%{install_dir}/antigravity \
       %{buildroot}%{install_dir}/antigravity-ide
fi

# Install the CLI wrapper script to /usr/bin/
mkdir -p %{buildroot}%{_bindir}
install -m 755 %{SOURCE5} %{buildroot}%{_bindir}/antigravity-ide

# Desktop entries
mkdir -p %{buildroot}%{_datadir}/applications
install -m 644 %{SOURCE2} %{buildroot}%{_datadir}/applications/
install -m 644 %{SOURCE3} %{buildroot}%{_datadir}/applications/

# AppStream metadata
mkdir -p %{buildroot}%{_datadir}/metainfo
install -m 644 %{SOURCE4} %{buildroot}%{_datadir}/metainfo/

# Icon (extract from upstream resources if available)
mkdir -p %{buildroot}%{_datadir}/pixmaps
if [ -f %{buildroot}%{install_dir}/resources/app/resources/linux/code.png ]; then
    cp %{buildroot}%{install_dir}/resources/app/resources/linux/code.png \
       %{buildroot}%{_datadir}/pixmaps/antigravity-ide.png
fi

# Shell completions (if upstream provides them)
if [ -d %{buildroot}%{install_dir}/resources/completions ]; then
    mkdir -p %{buildroot}%{_datadir}/bash-completion/completions
    cp %{buildroot}%{install_dir}/resources/completions/bash/antigravity-ide \
       %{buildroot}%{_datadir}/bash-completion/completions/ 2>/dev/null || true
    mkdir -p %{buildroot}%{_datadir}/zsh/site-functions
    cp %{buildroot}%{install_dir}/resources/completions/zsh/_antigravity-ide \
       %{buildroot}%{_datadir}/zsh/site-functions/ 2>/dev/null || true
fi

# Ensure the chrome-sandbox has the correct permissions (SUID)
chmod 4755 %{buildroot}%{install_dir}/chrome-sandbox 2>/dev/null || true

# ============================================================================
%files
%{install_dir}/
%{_bindir}/antigravity-ide
%{_datadir}/applications/antigravity-ide.desktop
%{_datadir}/applications/antigravity-ide-url-handler.desktop
%{_datadir}/metainfo/antigravity-ide.appdata.xml
%{_datadir}/pixmaps/antigravity-ide.png

# ============================================================================
%changelog
* Wed Jul 23 2026 Community Maintainer <antigravity-ide-rpm@users.noreply.github.com> - 2.1.1-1
- Initial community RPM package for Fedora
- Repackages upstream tar.gz from antigravity.google
