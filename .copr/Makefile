# ============================================================================
# .copr/Makefile — COPR SRPM build integration
# ============================================================================
# When COPR clones this repo, it runs: make -f .copr/Makefile srpm outdir=<dir>
# This Makefile downloads the upstream tarball and builds an SRPM.
# ============================================================================

SPEC := antigravity-ide.spec
UPSTREAM_NAME := Antigravity
DOWNLOAD_URL := https://antigravity.google/download

# COPR passes the output directory via the 'outdir' variable
outdir ?= $(CURDIR)

.PHONY: srpm

srpm:
	# -----------------------------------------------------------
	# Step 1: Download the upstream tarball from Google
	# -----------------------------------------------------------
	@echo "Downloading upstream tarball..."
	curl -sL -o $(CURDIR)/$(UPSTREAM_NAME).tar.gz \
		"$(DOWNLOAD_URL)" \
		--max-time 300 \
		--retry 3 \
		--retry-delay 5

	# Verify we got a real tarball (not an HTML error page)
	@file $(CURDIR)/$(UPSTREAM_NAME).tar.gz | grep -q "gzip compressed" || \
		(echo "ERROR: Downloaded file is not a valid gzip archive" && exit 1)

	# -----------------------------------------------------------
	# Step 2: Build the SRPM
	# -----------------------------------------------------------
	@echo "Building SRPM..."
	rpmbuild -bs \
		--define "_sourcedir $(CURDIR)" \
		--define "_specdir $(CURDIR)" \
		--define "_srcrpmdir $(outdir)" \
		$(CURDIR)/$(SPEC)

	@echo "SRPM built successfully in $(outdir)"
