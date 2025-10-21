[![Copr build status](https://copr.fedorainfracloud.org/coprs/jsbillings/netbird/package/netbird/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/jsbillings/netbird/package/netbird/)

# Packaging netbird as a native Fedora Package

## Information

- Netbird: [netbird.io](https://netbird.io/)
- Netbird Github: [github.com/netbirdio/netbird](https://github.com/netbirdio/netbird/)
- Netbird Documentation: [docs.netbird.io](https://docs.netbird.io/)

## How to install

- Install through COPR:

```
    dnf copr enable jsbillings/netbird
    dnf install netbird-client netbird-ui
```

- Build yourself
```
    make srpm
```
A .src.rpm package will be created.  You can then build that with rpmbuild or mock.

## Why build native packages?

The netbird packages provided by the company Netbird (GmbH) uses [nFPM](https://github.com/goreleaser/nfpm) to package the RPMs, which results in a subpar package.  Some of the things we avoid with the native Fedora package are:

- The netbird packages will not attempt to run commands as the user as part of the post script.
- Uses the standard systemd macros for the %post, %prun, and %postun package.
- Separates out a -client and -ui package.
- Actually properly attributes all the licenses used to build the client.
- A promblematic Go module (github.com/TheJumpCloud/jcapi-go) that lacks licensing is patched out.  Fortunately, this module is ONLY used as part of the authentication service for the Netbird server, and is not used in the netbird CLI client or the UI.  But because Fedora builds a vendor tarball of all upstream sources to build, we need to remove it from the build process.

