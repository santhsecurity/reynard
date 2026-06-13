REYNARD NOTE
============

The font PAYLOADS (bundle/fonts/{linux,macos,windows}) are NOT included in this
public repository — they are proprietary, copyrighted OS fonts (see the upstream
disclaimer below) and are not redistributable. To build a font-fingerprint-
coherent persona, copy the matching bundle/fonts/<os>/ tree from an upstream
Camoufox release (https://github.com/daijro/camoufox) into this directory before
`make build`. `cleanfonts.sh` (kept) documents the expected layout.

----------------------------------------------------------------------
Upstream Camoufox bundle/fonts README (verbatim):

DO NOT MODIFY THE CONTENTS OF THIS DIRECTORY

Any adjustment to bundled fonts will result in an altered fingerprint. Font
fingerprinting is more than just detecting what fonts you have, it also includes
font fallbacks and characters (unicode code points) and any change in those can
be measured.


SOURCES:

- Linux fonts are from TOR Browser bundle
- Windows fonts are from Windows 11 22H2.
- Mac OS fonts are from macOS Sonoma.


Disclaimer:

This project utilizes copyrighted fonts solely for academic and research purposes. The fonts used in this project are the intellectual property of their respective owners. No commercial use or distribution of these fonts is intended or permitted. All rights to the fonts are retained by their respective copyright holders. If you wish to use these fonts for any other purpose, please contact the copyright owners for appropriate permissions. If you wish a font to be removed from this repository, please open an issue.
