[![COPR Build status](https://copr.fedorainfracloud.org/coprs/jsbillings/netbird/package/netbird/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/jsbillings/netbird/)

# Packaging netbird as a native Fedora Package

## Information

- Netbird: [netbird.io](https://netbird.io/)
- Netbird Github: [github.com/netbirdio/netbird](https://github.com/netbirdio/netbird/)
- Netbird Documentation: [docs.netbird.io](https://docs.netbird.io/)

## Why build native packages?

The netbird packages provided by the company Netbird (GmbH) uses [nFPM](https://github.com/goreleaser/nfpm) to package the RPMs, which results in a subpar package.  Some of the things we avoid with the native Fedora package are:

- The netbird packages will not attempt to run commands as the user as part of the post script.
- Uses the standard systemd macros for the %post, %prun, and %postun package.
- Separates out a -client and -ui package.
- Actually properly attributes all the licenses used to build the client.
- A promblematic Go module (github.com/TheJumpCloud/jcapi-go) that lacks licensing is patched out.
