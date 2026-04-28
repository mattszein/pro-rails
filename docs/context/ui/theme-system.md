---
kind: context
id: theme_system
version: 2
source_id: pro_rails_docs
source_ref: context/ui/theme-system.md
domain: presentation
audience: [frontend_engineer]
topics: [themes, css, tailwind, oklch, theme-studio]
references: []
stability: stable
---

# Theme System (Pro-Rails)

40 named themes in 5 categories. Tailwind 4 with `@theme` and `@layer utilities`. OKLCH-based palette generation.

## Two-layer CSS architecture

| Layer | File | Scope | User-authorable? |
|---|---|---|---|
| Base | `app/assets/tailwind/themes/default.css` | Root `@theme` (Tailwind 4) | NO — V2+ only |
| Named themes (×40) | `app/assets/tailwind/themes/<name>.css` | `.theme-<name>` under `@layer utilities` | YES (MVP) |
| Assembly | `app/assets/tailwind/application.css` | Ordered `@import` list, 5 category sections | Patched by `Themes::ThemeFileWriter` |

## Base layer (default.css)

Defines every token the app consumes:
- 11 × 11-stop semantic palettes (`primary`, `secondary`, `success`, `danger`, `warning`, `info`, `create`, `show`, `edit`, `update`, `delete`)
- Surfaces (`--color-default`, `--color-highlight`)
- 4 text tokens
- Animation keyframes

Resolves Tailwind built-in palettes via `theme(colors.xxx.N)`. Structurally unique. Out of scope for user-authored themes.

## Named themes

Each file overrides ONLY:
- `--color-primary-*` (11 OKLCH stops)
- `--color-secondary-*` (11 stops)
- 4 text tokens

Generated from 2 scalar parameters per palette: `(hue, chroma)`. The 11 OKLCH stops follow a deterministic L-ramp + chroma-shape algorithm — see `Themes::PaletteGenerator`.

Does NOT touch semantic / action / surface tokens — those come from `default.css`.

## Five categories

| Category | Examples |
|---|---|
| Tech Edge | hyper, aurora, cyber, eclipse |
| Serene | botanic, reef, forest, lavender |
| Cosmic | nebula, starlight, void, prism |
| Vivid | sunset, berry, neon, phoenix |
| Night Owl | amber, ember, vintage, twilight |

8 themes per category × 5 categories = 40.

## Theme Studio (dev-only)

Browser-based authoring tool at `/dev/themes/studio`. **Dev-only** — wrapped in `if Rails.env.development?` in `config/routes.rb`. Same pattern as Lookbook.

Produces CSS files byte-for-byte compatible with the existing 40-theme gallery — uses the same `(hue, chroma)` → OKLCH algorithm as `lib/tasks/generate_themes.rake`.

## Themes:: services

| Service | Purpose |
|---|---|
| `Themes::PaletteGenerator` | Computes 11-stop OKLCH ramp from `(hue, chroma)`; parses theme files for round-trip |
| `Themes::ApplicationCssPatcher` | Idempotent `@import` insertion into the correct category block |
| `Themes::ThemeFileWriter` | Two-file write: theme CSS + `application.css` patch |
| `Themes::ThemeRegistry` | Lists all themes in `application.css` order with category |

## Namespace discipline (future engine extraction)

Studio code is namespace-isolated. No Studio file imports app-level models, Rodauth/ActionPolicy helpers, or services outside `Themes::*`.

| Surface | Namespace |
|---|---|
| Services | `Themes::*` (`app/services/themes/`) |
| Controller + form | `Dev::Themes::*` |
| Components | `app/components/dev/themes/` |
| Stimulus identifiers | `dev--themes--*` |
| JS utilities | `app/javascript/library/dev_themes/` |
| I18n keys | `dev.themes.*` |
