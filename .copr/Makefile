# ============================================================================
# .copr/Makefile — COPR SRPM build integration
# ============================================================================

SPEC := antigravity-ide.spec
outdir ?= $(CURDIR)

URL_X64 = $(shell grep '^# URL_X64:' $(CURDIR)/$(SPEC) | awk '{print $$3}')
URL_ARM64 = $(shell grep '^# URL_ARM64:' $(CURDIR)/$(SPEC) | awk '{print $$3}')

.PHONY: srpm

srpm:
	@echo "Downloading x86_64 tarball..."
	curl -sL -o $(CURDIR)/Antigravity-x64.tar.gz "$(URL_X64)"
	
	@echo "Downloading aarch64 tarball..."
	curl -sL -o $(CURDIR)/Antigravity-arm64.tar.gz "$(URL_ARM64)"

	@echo "Building SRPM..."
	rpmbuild -bs \
		--define "_sourcedir $(CURDIR)" \
		--define "_specdir $(CURDIR)" \
		--define "_srcrpmdir $(outdir)" \
		$(CURDIR)/$(SPEC)

	@echo "SRPM built successfully in $(outdir)"
