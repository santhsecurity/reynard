# reynard

A stealth-hardened fork of [Camoufox](https://github.com/daijro/camoufox)
(itself a patched Firefox/Gecko). reynard spoofs at the **Gecko C++ layer**, so
every surface holds natively in *all* realms — main thread, Web Workers, and
cross-origin iframes — with nothing for a page to `toString`-probe.

It exists for **authorized** security testing: letting a research agent create
test accounts and navigate in-scope targets without being misclassified as a
headless bot. See `NOTICE` and `LICENSE` (MPL-2.0).

## What reynard adds over Camoufox

reynard inherits the full Camoufox patch set (`patches/`) and layers on:

### `REYNARD_CONFIG` engine config (renamed from `CAMOU_CONFIG`)
`additions/camoucfg/MaskConfig.hpp` reads the persona JSON from
`REYNARD_CONFIG[_<n>]` first, falling back to the upstream `CAMOU_CONFIG[_<n>]`.
The rename is **additive** — older binaries and launchers keep working — so the
fork can decouple from the Camoufox brand without a flag day.

### `navigator.webdriver` honored under WebDriver BiDi
`patches/reynard-navigator-ua-config-fallback.patch` makes
`Navigator::Webdriver()` return the `REYNARD_CONFIG` `navigator.webdriver` bool
**before** the remote-agent check. Plain Firefox driven over BiDi forces
`navigator.webdriver = true` (the #1 bot tell, e.g. sannysoft "WebDriver"); the
`dom.webdriver.enabled` pref cannot override an active remote agent. This patch
pins it `false` per-persona while leaving the BiDi remote agent connected — the
key enabler for driving reynard over [rustenium](https://crates.io)/foxdriver
BiDi instead of Juggler.

### `navigator.userAgent` coherent in every realm
The same patch adds a `REYNARD_CONFIG` `navigator.userAgent` fallback to **both**
the instance `Navigator::GetUserAgent` getter **and** the static
`GetUserAgent(window, doc, …)` overload that `WorkerNavigator` routes through.
Without the latter, `self.navigator.userAgent` inside a Web Worker leaks the
stock build UA while the main thread reports the persona — a trivial worker-UA
drift tell. reynard closes it: main-thread and worker UA match the persona.

## Building

reynard uses Camoufox's build flow. In brief:

```sh
make dir       # fetch + extract the pinned Firefox source, apply patches/
make build     # ./mach build
make package
```

The proprietary OS font bundles under `bundle/fonts/` are **not** shipped here
(see `bundle/fonts/000_README.txt`); supply them from an upstream Camoufox
release before building a font-fingerprint-coherent macOS/Windows persona.

## Verification

The reynard engine is validated against IP-independent bot detectors and a
differential fingerprint oracle in the consuming `guise` / `captchaforge`
crates: `navigator.webdriver = false` over BiDi, persona UA in main + worker
realms, and a clean pass on sannysoft / areyouheadless.
