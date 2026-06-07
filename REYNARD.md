# reynard

A stealth-hardened fork of [Camoufox](https://github.com/daijro/camoufox)
(itself a patched Firefox/Gecko). reynard spoofs at the **Gecko C++ layer**, so
every surface holds natively in *all* realms — main thread, Web Workers, and
cross-origin iframes — with nothing for a page to `toString`-probe.

It exists for **authorized** security testing: letting a research agent create
test accounts and navigate in-scope targets without being misclassified as a
headless bot. See `NOTICE` and `LICENSE` (MPL-2.0).

## What reynard is, honestly

reynard inherits the **full Camoufox patch set** (`patches/`) — driven over
**WebDriver BiDi** (rustenium/foxdriver) rather than Juggler. The deep stealth —
`navigator.webdriver = false`, persona `userAgent`/`platform`/`hardwareConcurrency`
in every realm (main, worker, iframe), WebGL/canvas/audio/screen/timezone/WebRTC
noise — is the inherited Camoufox C++ layer, applied in canonical order via the
standard build flow (below). On this Firefox build it compiles and runs clean.

reynard's own deltas today:

### `REYNARD_CONFIG` engine config (renamed from `CAMOU_CONFIG`)
`additions/camoucfg/MaskConfig.hpp` reads the persona JSON from
`REYNARD_CONFIG[_<n>]` first, falling back to the upstream `CAMOU_CONFIG[_<n>]`.
The rename is **additive** — older binaries and launchers keep working — so the
fork decouples from the Camoufox brand without a flag day.

### Per-identity device noise + WebRTC masking (in the consumer, not the engine)
The consuming driver (Santh's `guise` / `guise-bridge`) derives a stable seed per
account and sends `canvas:seed`/`audio:seed`/`fonts:spacing_seed` so different
accounts render as different devices, and masks the WebRTC IP via the
content-callable `window.setWebRTCIPv4` so `RTCPeerConnection` never leaks the
real public IP. These ride on top of the engine; the engine just honors the keys.

Bespoke *beyond-Camoufox* engine patches (closing Camoufox's own residual tells)
are in progress, not yet shipped here.

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
