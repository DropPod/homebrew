# The `homebrew` Package Provider #

This module introduces a provider for managing packages with [Homebrew][mxcl].
As a package provider, Homebrew operates entirely in user-space, making it
suitable for per-user installations in addition to system-wide package
management. This `homebrew` provider is specifically set up to manage a
Homebrew installation in `/usr/local` ([as per recommendations][usrlocal]).

## Example ##

``` puppet
package { "git": provider => homebrew }
```

## Caveats ##

The `homebrew` provider will automatically relinquish super-user permissions if
Puppet is run with `sudo`, instead choosing to run as the owner of
`/usr/local/bin/brew`. This behavior introduces a fair bit of complexity and
may be replaced in the future by a refusal to run at all.

The `homebrew` provider currently purports to support installations of
particular versions, but the underlying package provider does not.

[mxcl]: https://github.com/mxcl/homebrew
[usrlocal]: https://github.com/mxcl/homebrew/wiki/FAQ#wiki-usrlocal
