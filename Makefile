#NETBIRD_GOPATH := $(shell mktemp -d /tmp/gopathXXXX )
NETBIRD_GOPATH := /tmp/netbird_go
NETBIRD_VERSION := $(shell rpmspec -q --qf "%{VERSION}\n" netbird.spec | head -1)

.ONESHELL:
SHELL=/bin/bash
srpm:
	dnf install -y rpmdevtools rpmautospec go-vendor-tools python3-specfile golang-bin gtk4-devel webkitgtk6.0-devel pnpm git
	rm -rf /tmp/_topdir
	mkdir -p /tmp/_topdir/SOURCES
	rpmdev-spectool --gf $(spec)
        # Go binaries
	export GOPATH=$(NETBIRD_GOPATH)
	go_vendor_archive create --config go-vendor-tools.toml netbird.spec
	# Extract netbird tarball to build NodeJS bits
	tar zxvf netbird-$(NETBIRD_VERSION).tar.gz
	pushd netbird-$(NETBIRD_VERSION)
	WAILS_VERSION=$$(go list -m -f '{{.Version}}' github.com/wailsapp/wails/v3)
	go install github.com/wailsapp/wails/v3/cmd/wails3@$$WAILS_VERSION
	pushd client/ui
	$(NETBIRD_GOPATH)/bin/wails3 generate bindings -clean=true -ts
	pushd frontend
	# Fix broken dependencies
	sed -i 's,"^10.0.1","^9.39.5",' package.json
	# install the npm dependencies
	pnpm install --frozen-lockfile
	pnpm build
	popd # frontend
	popd # client/ui
	popd # netbird root
	# Create Node.js vendored tarball
	tar zcf netbird-ui-assets-$(NETBIRD_VERSION).tgz -C netbird-$(NETBIRD_VERSION)/client/ui/frontend dist
	cp netbird*.tar.gz netbird*.tar.bz2 go-vendor-tools.toml netbird.service netbirdui.service client_config.json netbird.logrotate *.patch netbird-ui-assets*.tgz /tmp/_topdir/SOURCES/
	rpmautospec process-distgit $(spec) $(spec)
	rpmbuild -bs --define "_topdir /tmp/_topdir" $(spec)
	cp -r /tmp/_topdir/SRPMS/*.src.rpm $(outdir)
	rm -rf /tmp/_topdir
	chmod -R +rwx $(NETBIRD_GOPATH)
	rm -rf $(NETBIRD_GOPATH)
