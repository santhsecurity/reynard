# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# Note: MOZ_APP_VENDOR and MOZ_APP_PROFILE must be set via imply_option() in browser/moz.configure
# See patches/librewolf/disable-data-reporting-at-compile-time.patch

# Coherence (G-branding): the runtime-OBSERVABLE identity must read as stock
# Firefox. MOZ_APP_REMOTINGNAME is the load-bearing one — on Linux it becomes the
# X11 WM_CLASS, which a real Firefox exposes as "firefox"/"Firefox"; a window
# class of "camoufox" is a direct, IP-independent tell to any local observer or
# screen-/window-introspecting probe. DISPLAYNAME/BASENAME drive the window title
# and about: surfaces, so they match too.
#
# MOZ_APP_NAME stays `camoufox` ON PURPOSE: it sets the on-disk BINARY name. The
# whole stealth-stack harness pins it — guise's REYNARD_BIN points at
# dist/bin/camoufox, firefox_engine_major() parses the binary's --version, and the
# publish/install scripts key off it. Renaming the binary is a coordinated
# cross-repo refactor with zero web-observable benefit (the binary name never
# reaches the wire), so it is deliberately NOT changed here.
MOZ_APP_NAME=camoufox
MOZ_APP_BASENAME=Firefox
MOZ_APP_DISPLAYNAME=Firefox
MOZ_APP_REMOTINGNAME=firefox
