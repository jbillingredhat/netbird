srpm:
	dnf install -y rpmdevtools go-vendor-tools python3-specfile
	rm -rf /tmp/_topdir
	mkdir -p /tmp/_topdir/SOURCES
	go_vendor_archive create --config go-vendor-tools.toml netbird.spec
	cp netbird*.tar.gz netbird*.tar.bz2 go-vendor-tools.toml *.patch netbird.service client_config.json /tmp/_topdir/SOURCES/
	rpmdev-spectool --gf -R --define "_topdir /tmp/_topdir" $(spec)
	rpmbuild -bs --define "_topdir /tmp/_topdir" $(spec)
	cp -r /tmp/_topdir/SRPMS/*.src.rpm $(outdir)
	rm -rf /tmp/_topdir
