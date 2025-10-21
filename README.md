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

## How to use Netbird

Please follow the [Netbird Documentation](https://docs.netbird.io/).  The only difference with this package is that it is built using the Fedora Golang packages, and that you have to manually enable and start the `netbird.service` Systemd service.


## How can I preconfigure Netbird to always use my self-hosted service?

There is a [commented out example configuration](./client_config.json) in /etc/netbird/config.json.  Setting the ManagementURL to your self-hosted endpoint will be used by default when creating a new profile.  

## Why build native packages?

The netbird packages provided by the company [Netbird (GmbH)](https://netbird.io/about) uses [nFPM](https://github.com/goreleaser/nfpm) to package the RPMs, which results in a subpar package.  Some of the things we avoid with the native Fedora package are:

- The netbird-ui package will not [attempt to run commands as the user](https://github.com/netbirdio/netbird/blob/main/release_files/ui-post-install.sh) as part of the post script.
- The netbird-client does not [start the systemd service upon installing the package](https://github.com/netbirdio/netbird/blob/main/release_files/post_install.sh).
- Uses the standard systemd macros for the %post, %prun, and %postun package.
- Separates out a -client and -ui package.
- Actually properly attributes all the licenses used to build the client.
- A promblematic Go module (github.com/TheJumpCloud/jcapi-go) that lacks licensing is patched out.  Fortunately, this module is ONLY used as part of the authentication service for the Netbird server, and is not used in the netbird CLI client or the UI.  But because Fedora builds a vendor tarball of all upstream sources to build, we need to remove it from the build process.

