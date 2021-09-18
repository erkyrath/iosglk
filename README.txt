IosGlk -- an iOS implementation of the Glk API.

IosGlk library: version 0.3.0.
Glk API which this implements: version 0.7.3.
Designed by Andrew Plotkin <erkyrath@eblong.com>
Home site: <http://eblong.com/zarf/glk/>

This is source code for an implementation of the Glk library for iOS.
It is intended to be a basis for iOS IF applications.

For working examples, see my IosFizmo and IosGlulxe projects:
<https://github.com/erkyrath/iosfizmo/>
<https://github.com/erkyrath/iosglulxe/>

* Deprecation Alert

This library is out of date and I no longer support it.

I was able to deal with deprecation warnings and OS changes through
iOS 12 (in 2018). However, the code is *extremely* old -- I originally
wrote it for iOS 3! The accumulated patches and hacks have reached
critical mass and it is no longer worth updating the library.

For more details, see [my blog post][post] (Jan 2020) announcing
the end of support.

[post]: https://blog.zarfhome.com/2020/01/iosglk-iosglulxe-and-iosfizmo-are-out.html

Old IosGlk apps (compiled for iOS 12) still work as of this writing
(running under iOS 14). However, I have received reports that VoiceOver
is janky. Jank is likely to increase over time.

* Permissions

The IosGlk library is copyright 2011-16 by Andrew Plotkin. The
GiDispa and GiBlorb libraries, as well as the glk.h header file, are
copyright 1998-2016 by Andrew Plotkin. They are distributed under the
MIT license; see the "LICENSE" file.

