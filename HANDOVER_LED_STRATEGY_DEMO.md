# ESP-Claw LED Strategy Demo Handover

**Prepared by:** Manus AI
**Handover date:** 2026-09-22
**Package identity:** See `HANDOVER_MANIFEST.txt` in the delivered archive for the exact Git revision, archive checksum, and included build assets.

## Purpose and current state

This package contains the full **ESP-Claw documentation source tree** with the interactive Chinese **system state and LED strategy demo**. The demo is a static Astro page. It has no backend, database, authentication requirement, or runtime API dependency. The current experience is intentionally hosted only by the temporary Manus preview; no persistent GitHub Pages branch, workflow, or external deployment is included.

The main demo page models the power-off, powered-on, and sleep states. It also covers onboarding, debug mode, user-program execution, low-battery overlays, upgrade and error protection, USB charging, key input, and buzzer behavior. A click in the lower selector updates the effect panel and highlights the relevant SVG flow nodes. Selected nodes retain their dark surface and use only a **4 px centered neutral gradient stroke**, which produces the requested 2 px highlight inside and outside the edge.

> The project is ready to open as a Cursor workspace at the package root. The working code is under `docs/`; do not open `docs/dist/` as the source of truth because it is generated output.

## Project map

| Path | Role | Change guidance |
|---|---|---|
| `docs/src/pages/zh-cn/led-strategy.astro` | Single-file interactive strategy page containing the rule catalog, SVG diagram, selection behavior, effect panel, and page-local styles. | Use this file for all policy, flow, copy, layout, and selection-style changes. |
| `docs/src/styles/hardware-tokens.css` | Canonical cyber-hardware visual tokens copied from the approved UI system. | Preserve token names and semantics. Prefer changing component rules over redefining tokens. |
| `docs/public/led-strategy-flow.mmd` | Downloadable Mermaid version of the policy. | Update when the high-level rule model changes. It is a complementary static artifact, not the clickable page diagram. |
| `docs/public/led-strategy-flow.png` | Rendered downloadable PNG of the Mermaid flowchart. | Regenerate after editing the `.mmd` source. |
| `docs/astro.config.mjs` | Astro and Starlight configuration. It supports both root hosting and an internal-server subpath through `PUBLIC_BASE_PATH`. | Keep the default base as `/` unless the internal server serves the site below a path such as `/led-strategy`. |
| `docs/tools/build-static-site.sh` | Reproducible production build helper. | Use this for release builds. It creates a temporary valid `package.json` from `package.json5` and removes it after the build. |
| `docs/pnpm-lock.yaml` | Locked dependency graph for the documentation application. | Commit any lockfile change that accompanies a dependency update. |
| `docs/src/pages/zh-cn/` | Chinese Astro pages, including the LED strategy demo. | Keep `led-strategy.astro` in this location so its route remains `/zh-cn/led-strategy/`. |

## Rule model and interaction contract

The `interactions` array at the beginning of `led-strategy.astro` is the canonical model for the selector and effect panel. Each entry has an `id`, a group, user-facing text, an LED effect class, key and buzzer behavior, and a `targets` array. The `targets` array must match the `data-flow-id` attributes inside the SVG diagram. If a new rule is added, add both the interaction entry and every associated SVG target before testing the selector.

The page script resolves the URL hash to an interaction ID, marks the matching selector button, and applies `is-highlighted` to each associated SVG node. The highlight is deliberately visual only. It must not overwrite the LED semantic colors or the node fill. The selected-node rule uses `stroke-width: 4`, which is centered by SVG and therefore creates a 2 px inside and 2 px outside edge treatment. The `selection-edge` gradient in the SVG definitions and the CSS `.flow-node.is-highlighted` rule must remain in sync.

The SVG is manually spaced into four lanes to avoid overlap at normal desktop widths. When adding a node or return path, reserve whitespace for the node, arrow route, and label independently. Do not route shared-rule lines through a node. Solid lines represent state transitions. Dashed lines represent overlays or shared rules. Before accepting a visual change, check both node-to-node and label-to-node collisions at a desktop viewport.

## Opening and editing in Cursor

Open the extracted package root in Cursor. The repository contains the firmware project as well as the documentation site. The LED demo itself is in `docs/`. Use Node.js 22 and pnpm 10 or a compatible later pnpm release.

The project stores its package manifest as `docs/package.json5` because some development dependency lines have explanatory comments. Standard package managers expect `package.json`, so generate a temporary manifest before dependency installation or development. The following command sequence starts a local development server.

```bash
cd docs
sed -E 's@[[:space:]]*//.*$@@' package.json5 > package.json
pnpm install --frozen-lockfile
pnpm dev --host 0.0.0.0
```

When the development session ends, remove the temporary file if it is no longer needed.

```bash
rm -f package.json
```

The project ignores `docs/node_modules/`, `docs/dist/`, and `docs/.astro/`. Do not add these generated directories to source control or to a handover archive.

## Build and local verification

The supported production build command is:

```bash
cd docs
bash tools/build-static-site.sh
```

The output directory is `docs/dist/`. The build must complete before release. The page to verify is `docs/dist/zh-cn/led-strategy/index.html`.

For a local production-like test, retain the temporary `package.json` for the preview command, or regenerate it before starting the preview.

```bash
cd docs
sed -E 's@[[:space:]]*//.*$@@' package.json5 > package.json
pnpm exec astro preview --host 0.0.0.0 --port 4321
```

Open `http://127.0.0.1:4321/zh-cn/led-strategy/`. Test at least the power-off start rule, the low-battery alert, a debug-connection branch, and USB charging with and without a battery. Confirm that the hash changes, the effect panel updates, and selected nodes display a gradient edge glow without changing their fill color.

## Internal-server deployment

The production site is static. A reverse proxy or application process is not required after the Astro build. Nginx is the recommended internal-server host because it can map a URL prefix to the generated `dist/` directory. The Astro `base` configuration controls page and static-asset prefixes, and `import.meta.env.BASE_URL` is used for the downloadable flowchart assets. Build the site with the same public prefix that Nginx exposes. Astro documents this base-path behavior explicitly.[1]

### Option A: Serve at the intranet root

Use this option when the site is available directly at an internal hostname such as `https://led-demo.intra.example/`.

```bash
cd docs
bash tools/build-static-site.sh
sudo install -d -m 0755 /srv/esp-claw-led-strategy
sudo rsync -a --delete dist/ /srv/esp-claw-led-strategy/
```

Use the following Nginx server block, then replace the hostname and TLS configuration to match the internal environment.

```nginx
server {
    listen 80;
    server_name led-demo.intra.example;

    root /srv/esp-claw-led-strategy;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

### Option B: Serve below an intranet subpath

Use this option when the site must be mounted below a shared internal domain, for example `https://tools.intra.example/led-strategy/`.

```bash
cd docs
PUBLIC_BASE_PATH=/led-strategy bash tools/build-static-site.sh
sudo install -d -m 0755 /srv/esp-claw-led-strategy
sudo rsync -a --delete dist/ /srv/esp-claw-led-strategy/
```

Use a matching Nginx prefix. The trailing slash in the request location and the `alias` destination is intentional.

```nginx
server {
    listen 80;
    server_name tools.intra.example;

    location = /led-strategy {
        return 301 /led-strategy/;
    }

    location ^~ /led-strategy/ {
        alias /srv/esp-claw-led-strategy/;
        index index.html;
        try_files $uri $uri/ =404;
    }
}
```

Nginx serves static files by mapping request paths through `root` or `alias` directives, and the active configuration should be syntax-checked before reload.[2]

```bash
sudo nginx -t
sudo systemctl reload nginx
```

After deployment, load the page from its final internal URL. Verify the browser network panel contains no requests to the former Manus preview host and that both `/led-strategy-flow.mmd` and `/led-strategy-flow.png` resolve beneath the configured base path.

## Release checklist and rollback

Before replacing an internal-server release, keep a timestamped copy of the existing static directory. Build the new `dist/` directory, copy it into a new versioned directory, validate its main page and downloadable assets, then update the active Nginx alias or deployment symlink. This reduces the chance of exposing a partial upload.

A rollback consists of restoring the previous static directory or symlink, checking the Nginx configuration, and reloading Nginx. No database migration, service state, or schema rollback is needed because this demo is static.

## Included and excluded content

The source package contains all Git-tracked project files, including the root firmware project, documentation code, lockfile, visual assets, the interactive page source, and downloadable flowchart files. It excludes `.git/`, `docs/node_modules/`, `docs/dist/`, `docs/.astro/`, editor caches, and other generated files. Install dependencies and rebuild on the target machine rather than transferring those directories.

The package deliberately does not include permanent-hosting configuration, GitHub Pages deployment branches, deployment secrets, or any Manus runtime credentials. The Manus preview link is temporary and should not be embedded in internal-server documentation or configuration.

## References

[1]: https://docs.astro.build/en/reference/configuration-reference/ "Astro Configuration Reference"
[2]: https://nginx.org/en/docs/beginners_guide.html "Nginx Beginner’s Guide"
