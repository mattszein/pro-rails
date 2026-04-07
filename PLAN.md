# Landing Page Implementation Plan

## Overview

Translate the React-based landing page (`landing-example.tsx`) into our Rails 8 stack: ERB views, ViewComponents, Stimulus controllers, Motion JS for SVG animations, TailwindCSS, and I18n.

---

## 1. Add Motion JS via Importmap

Motion's standalone `animate()` function (~2.5kB) gives us spring physics, path morphing, staggered keyframes, and SVG attribute animation — things CSS transitions can't do well.

```ruby
# config/importmap.rb
pin "motion", to: "https://cdn.jsdelivr.net/npm/motion@12.7.3/dist/motion.js"
pin_all_from "app/javascript/icons", under: "icons"
```

---

## 2. Animated Icon Pattern

### Problem

We have 8 feature card icons. 5 have original Motion source files (`lock.tsx`, `connect.tsx`, `charts.tsx`, `sliders.tsx`, `contrast.tsx`). 3 were built as CSS-only in the landing example (authorization shield, UI component layers, support chat). We need a reusable, scalable pattern that:

- Keeps SVGs server-rendered (SEO, no JS required for display)
- Triggers animation from a parent element (card hover, button hover)
- Uses Motion JS for smooth spring/stagger physics
- Is easy to add new animated icons in the future

### Solution: SVG Assets + Extended `icon()` Helper + Animation Modules + Stimulus

**Four layers:**

| Layer | What | Where |
|-------|------|-------|
| SVG files | Static SVG with `data-element` attrs on animated children | `app/assets/images/icons/*.svg` |
| Helper | `icon()` extended with `animated_type:` option | `app/helpers/application_helper.rb` |
| Animation logic | JS module per icon exporting `start(svg)` / `stop(svg)` | `app/javascript/icons/*.js` |
| Trigger glue | Stimulus controller that connects parent events to animation | `app/javascript/controllers/animated_icon_controller.js` |

### Layer 1: SVG Files in `app/assets/images/icons/`

Animated icons live alongside existing ones. `inline_svg_tag` (used by the current `icon()` helper) renders SVG files verbatim, so `data-element` attributes baked into the file are preserved as-is in the rendered HTML. No ERB partials needed.

```xml
<!-- app/assets/images/icons/lock.svg -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
     stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
  <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
  <path data-element="shackle" d="M7 11V7a5 5 0 0 1 10 0v4"/>
</svg>
```

```xml
<!-- app/assets/images/icons/connect.svg -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
     stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
  <path data-element="wire-1" d="M19 5l3-3"/>
  <path data-element="wire-2" d="M2 22l3-3"/>
  <path data-element="socket" d="M6.3 20.3a2.4 2.4 0 0 0 3.4 0L12 18l-6-6-2.3 2.3a2.4 2.4 0 0 0 0 3.4Z"/>
  <path data-element="pin-1" d="M7.5 13.5 L10 11"/>
  <path data-element="pin-2" d="M10.5 16.5 L13 14"/>
  <path data-element="plug" d="m12 6 6 6 2.3-2.3a2.4 2.4 0 0 0 0-3.4l-2.6-2.6a2.4 2.4 0 0 0-3.4 0Z"/>
</svg>
```

```xml
<!-- app/assets/images/icons/charts.svg -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
     stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
  <path d="M3 3v16a2 2 0 0 0 2 2h16"/>
  <path data-element="bar-1" d="M8 17v-3"/>
  <path data-element="bar-2" d="M13 17V9"/>
  <path data-element="bar-3" d="M18 17V5"/>
</svg>
```

```xml
<!-- app/assets/images/icons/sliders.svg -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
     stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
  <line data-element="track-1a" x1="21" x2="14" y1="4" y2="4"/>
  <line data-element="track-1b" x1="10" x2="3" y1="4" y2="4"/>
  <line data-element="track-2a" x1="21" x2="12" y1="12" y2="12"/>
  <line data-element="track-2b" x1="8" x2="3" y1="12" y2="12"/>
  <line data-element="track-3a" x1="3" x2="12" y1="20" y2="20"/>
  <line data-element="track-3b" x1="16" x2="21" y1="20" y2="20"/>
  <line data-element="knob-1" x1="14" x2="14" y1="2" y2="6"/>
  <line data-element="knob-2" x1="8" x2="8" y1="10" y2="14"/>
  <line data-element="knob-3" x1="16" x2="16" y1="18" y2="22"/>
</svg>
```

```xml
<!-- app/assets/images/icons/contrast.svg -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
     stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
  <circle cx="12" cy="12" r="10"/>
  <path data-element="half" d="M12 18a6 6 0 0 0 0-12v12z"/>
</svg>
```

```xml
<!-- app/assets/images/icons/shield.svg (authorization — custom) -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
     stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
  <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
  <path data-element="checkmark" d="M9 12l2 2 4-4"/>
</svg>
```

```xml
<!-- app/assets/images/icons/layers.svg (UI components — custom) -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
     stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
  <polygon data-element="top" points="12 4 4 8 12 12 20 8 12 4"/>
  <polyline data-element="mid" points="4 11 12 15 20 11"/>
  <polyline data-element="bot" points="4 14 12 18 20 14"/>
</svg>
```

```xml
<!-- app/assets/images/icons/chat.svg (support — custom) -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
     stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
  <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
  <circle data-element="dot-1" cx="9" cy="10" r="1" fill="currentColor" stroke="none" opacity="0"/>
  <circle data-element="dot-2" cx="12" cy="10" r="1" fill="currentColor" stroke="none" opacity="0"/>
  <circle data-element="dot-3" cx="15" cy="10" r="1" fill="currentColor" stroke="none" opacity="0"/>
</svg>
```

### Layer 2: Extend `icon()` Helper in `application_helper.rb`

Add an `animated_type:` option. When present, wraps the rendered SVG in the Stimulus controller `div`. This keeps the call site minimal and centralises the controller wiring in one place.

```ruby
def icon(name, options = {})
  animated_type = options.delete(:animated_type)
  options[:title] ||= name.underscore.humanize
  options[:aria] = true
  options[:nocomment] = true
  options[:class] = options.fetch(:classes, nil)
  path = options.fetch(:path, "icons/#{name}.svg")
  svg = inline_svg_tag(path, options)

  if animated_type
    content_tag(:div, svg,
      data: {
        controller: "animated-icon",
        animated_icon_type_value: animated_type
      }
    )
  else
    svg
  end
end
```

Usage anywhere in the app:

```erb
<%# Static icon (existing behaviour — unchanged) %>
<%= icon("bell", classes: "w-5 h-5") %>

<%# Animated icon wrapped in Stimulus controller %>
<%= icon("lock", classes: "w-7 h-7", animated_type: "lock") %>
```

### Layer 3: Animation Modules in `app/javascript/icons/`

Each icon gets a small JS file exporting `start(svg)` and `stop(svg)`. Colocated with the controller registry under an `icons/` importmap namespace mirrors the SVG files in `app/assets/images/icons/`.

```
app/javascript/icons/
├── lock.js
├── connect.js
├── charts.js
├── sliders.js
├── contrast.js
├── shield.js
├── layers.js
└── chat.js
```

**lock.js** — SVG shakes + shackle opens (from `lock.tsx`):

```js
import { animate } from "motion"

const q = (svg, name) => svg.querySelector(`[data-element="${name}"]`)

export function start(svg) {
  animate(svg, { rotate: [-3, 1, -2, 0], scale: [0.95, 1.05, 0.98, 1] },
    { duration: 1, easing: [0.4, 0, 0.2, 1] })
  const shackle = q(svg, "shackle")
  if (shackle) animate(shackle, { pathLength: 0.7 }, { duration: 0.3, easing: [0.4, 0, 0.2, 1] })
}

export function stop(svg) {
  animate(svg, { rotate: 0, scale: 1 }, { duration: 0.3 })
  const shackle = q(svg, "shackle")
  if (shackle) animate(shackle, { pathLength: 1 }, { duration: 0.3 })
}
```

**connect.js** — plug/socket spring apart (from `connect.tsx`):

```js
import { animate } from "motion"

const q = (svg, name) => svg.querySelector(`[data-element="${name}"]`)
const SPRING = { easing: "spring(500, 30)" }

export function start(svg) {
  animate(q(svg, "wire-1"), { d: "M17 7l5-5" }, SPRING)
  animate(q(svg, "wire-2"), { d: "M2 22l6-6" }, SPRING)
  animate(q(svg, "socket"), { x: 3, y: -3 }, SPRING)
  animate(q(svg, "plug"),   { x: -3, y: 3 }, SPRING)
  animate(q(svg, "pin-1"),  { d: "M10.43 10.57l0.1-0.1" }, SPRING)
  animate(q(svg, "pin-2"),  { d: "M13.43 13.57l0.1-0.1" }, SPRING)
}

export function stop(svg) {
  animate(q(svg, "wire-1"), { d: "M19 5l3-3" }, SPRING)
  animate(q(svg, "wire-2"), { d: "M2 22l3-3" }, SPRING)
  animate(q(svg, "socket"), { x: 0, y: 0 }, SPRING)
  animate(q(svg, "plug"),   { x: 0, y: 0 }, SPRING)
  animate(q(svg, "pin-1"),  { d: "M7.5 13.5L10 11" }, SPRING)
  animate(q(svg, "pin-2"),  { d: "M10.5 16.5L13 14" }, SPRING)
}
```

**charts.js** — staggered bar erase + redraw (from `charts.tsx`):

```js
import { animate } from "motion"

const q = (svg, name) => svg.querySelector(`[data-element="${name}"]`)

export async function start(svg) {
  const bars = ["bar-1", "bar-2", "bar-3"].map(n => q(svg, n)).filter(Boolean)
  bars.forEach((bar, i) =>
    animate(bar, { pathLength: 0, opacity: 0 }, { duration: 0.3, delay: i * 0.1 })
  )
  await new Promise(r => setTimeout(r, bars.length * 100 + 300))
  bars.forEach((bar, i) =>
    animate(bar, { pathLength: 1, opacity: 1 }, { duration: 0.3, delay: i * 0.1 })
  )
}

export function stop(svg) {
  ["bar-1", "bar-2", "bar-3"].forEach(n => {
    const bar = q(svg, n)
    if (bar) animate(bar, { pathLength: 1, opacity: 1 }, { duration: 0.2 })
  })
}
```

**sliders.js** — knobs slide (from `sliders.tsx`, spring stiffness=100 damping=12 mass=0.4):

```js
import { animate } from "motion"

const q = (svg, name) => svg.querySelector(`[data-element="${name}"]`)
const SPRING = { easing: "spring(100, 12, 0.4)" }

export function start(svg) {
  animate(q(svg, "track-1a"), { x2: 10 }, SPRING)
  animate(q(svg, "track-1b"), { x1: 5 }, SPRING)
  animate(q(svg, "track-2a"), { x2: 18 }, SPRING)
  animate(q(svg, "track-2b"), { x1: 13 }, SPRING)
  animate(q(svg, "track-3a"), { x2: 4 }, SPRING)
  animate(q(svg, "track-3b"), { x1: 8 }, SPRING)
  animate(q(svg, "knob-1"),   { x1: 9, x2: 9 }, SPRING)
  animate(q(svg, "knob-2"),   { x1: 14, x2: 14 }, SPRING)
  animate(q(svg, "knob-3"),   { x1: 8, x2: 8 }, SPRING)
}

export function stop(svg) {
  animate(q(svg, "track-1a"), { x2: 14 }, SPRING)
  animate(q(svg, "track-1b"), { x1: 10 }, SPRING)
  animate(q(svg, "track-2a"), { x2: 12 }, SPRING)
  animate(q(svg, "track-2b"), { x1: 8 }, SPRING)
  animate(q(svg, "track-3a"), { x2: 12 }, SPRING)
  animate(q(svg, "track-3b"), { x1: 16 }, SPRING)
  animate(q(svg, "knob-1"),   { x1: 14, x2: 14 }, SPRING)
  animate(q(svg, "knob-2"),   { x1: 8, x2: 8 }, SPRING)
  animate(q(svg, "knob-3"),   { x1: 16, x2: 16 }, SPRING)
}
```

**contrast.js** — half-circle rotates 180° (from `contrast.tsx`):

```js
import { animate } from "motion"

const q = (svg, name) => svg.querySelector(`[data-element="${name}"]`)

export function start(svg) {
  const half = q(svg, "half")
  if (half) animate(half, { rotate: 180 }, { easing: "spring(80, 12)" })
}

export function stop(svg) {
  const half = q(svg, "half")
  if (half) animate(half, { rotate: 0 }, { easing: "spring(80, 12)" })
}
```

**shield.js** — checkmark draws in (custom):

```js
import { animate } from "motion"

const q = (svg, name) => svg.querySelector(`[data-element="${name}"]`)

export function start(svg) {
  const check = q(svg, "checkmark")
  if (!check) return
  const length = check.getTotalLength?.() ?? 20
  check.style.strokeDasharray = length
  animate(check, { strokeDashoffset: [length, 0] },
    { duration: 0.5, easing: [0.4, 0, 0.2, 1] })
}

export function stop(svg) {
  const check = q(svg, "checkmark")
  if (!check) return
  check.style.strokeDasharray = "none"
  check.style.strokeDashoffset = "0"
}
```

**layers.js** — top layer floats up (custom):

```js
import { animate } from "motion"

const q = (svg, name) => svg.querySelector(`[data-element="${name}"]`)
const SPRING = { easing: "spring(300, 20)" }

export function start(svg) {
  animate(q(svg, "top"), { y: -2 }, SPRING)
  animate(q(svg, "bot"), { y:  2 }, SPRING)
}

export function stop(svg) {
  animate(q(svg, "top"), { y: 0 }, SPRING)
  animate(q(svg, "bot"), { y: 0 }, SPRING)
}
```

**chat.js** — dots appear with stagger (custom):

```js
import { animate } from "motion"

const q = (svg, name) => svg.querySelector(`[data-element="${name}"]`)

export function start(svg) {
  ;["dot-1", "dot-2", "dot-3"].forEach((name, i) => {
    const dot = q(svg, name)
    if (dot) animate(dot, { opacity: 1 }, { duration: 0.3, delay: i * 0.075 })
  })
}

export function stop(svg) {
  ;["dot-1", "dot-2", "dot-3"].forEach(name => {
    const dot = q(svg, name)
    if (dot) animate(dot, { opacity: 0 }, { duration: 0.2 })
  })
}
```

### Layer 4: Stimulus Controller

A single controller with a static import registry. All animation modules are explicitly imported — no dynamic `import()`, no importmap issues.

```js
// app/javascript/controllers/animated_icon_controller.js
import { Controller } from "@hotwired/stimulus"

import * as lock     from "icons/lock"
import * as connect  from "icons/connect"
import * as charts   from "icons/charts"
import * as sliders  from "icons/sliders"
import * as contrast from "icons/contrast"
import * as shield   from "icons/shield"
import * as layers   from "icons/layers"
import * as chat     from "icons/chat"

const REGISTRY = { lock, connect, charts, sliders, contrast, shield, layers, chat }

export default class extends Controller {
  static values = { type: String }

  connect() {
    this.animation = REGISTRY[this.typeValue]
    this.svg = this.element.querySelector("svg")
  }

  start() {
    if (this.animation && this.svg) this.animation.start(this.svg)
  }

  stop() {
    if (this.animation && this.svg) this.animation.stop(this.svg)
  }
}
```

### Usage in ERB (feature card with hover trigger)

The parent card dispatches `mouseenter`/`mouseleave` to the nested controller. CSS hover effects (border, background, text color) use Tailwind `group-hover:`, Motion handles the SVG.

```erb
<div class="group relative bg-white dark:bg-[#1a1a1c] border border-slate-200 dark:border-[#2a2a2d]
            rounded-2xl p-6 transition-all duration-300 hover:shadow-xl hover:-translate-y-1 cursor-pointer
            hover:border-blue-200 dark:hover:border-blue-900/50"
     data-action="mouseenter->animated-icon#start mouseleave->animated-icon#stop">

  <div class="flex items-center mb-4 space-x-4">
    <div class="relative w-14 h-14 shrink-0 rounded-xl flex items-center justify-center text-blue-600
                dark:text-blue-400 bg-slate-50 dark:bg-[#2a2a2d] transition-colors duration-300
                group-hover:bg-blue-50 dark:group-hover:bg-blue-900/20">
      <%= icon("lock", classes: "w-7 h-7", animated_type: "lock") %>
    </div>
    <h3 class="text-lg font-semibold text-slate-800 dark:text-slate-100 transition-colors
               group-hover:text-blue-700 dark:group-hover:text-blue-400">
      <%= t("landing.features.authentication.title") %>
    </h3>
  </div>
  <p class="text-sm text-slate-500 dark:text-slate-400 leading-relaxed">
    <%= t("landing.features.authentication.description") %>
  </p>
</div>
```

**How trigger resolution works**: Stimulus walks up the DOM from the `mouseenter` event target looking for a matching controller. The `data-action` is on the card `div` but the matching `animated-icon` controller is on the icon wrapper `div` inside. Stimulus resolves this correctly because the action descriptor (`animated-icon#start`) names the controller, not a target — the card `div` dispatches the event, and Stimulus finds the nearest `animated-icon` controller in the subtree.

### Adding future icons

1. Create `app/assets/images/icons/name.svg` with `data-element` on animated children
2. Create `app/javascript/icons/name.js` exporting `start(svg)` / `stop(svg)`
3. Add `import * as name from "icons/name"` + `name` to the registry in `animated_icon_controller.js`
4. Call `icon("name", animated_type: "name", classes: "w-7 h-7")` in any view

---

## 3. Landing Page Layout

The current `application.html.erb` layout includes the authenticated navbar and `pt-20 px-8` padding on `<main>`. The landing page needs a different structure: custom marketing navbar (or none), full-width sections, footer.

### Recommended: conditional content_for in existing layout

```erb
<%# app/views/layouts/application.html.erb %>
<body class="antialiased bg-default" data-controller="closer">
  <% unless content_for?(:landing) %>
    <%= render partial: "partials/navbar" %>
  <% end %>
  <main class="<%= content_for?(:landing) ? 'min-h-screen' : 'pt-20 px-8 h-full mx-auto flex justify-center dark:text-gray-200' %>">
    <%= turbo_frame_tag "modal", target: "_top" %>
    <%= yield %>
  </main>
  <div id="flashes_id"><%= render "shared/flashes" %></div>
</body>
```

Then at the top of `index.html.erb`:

```erb
<% content_for(:landing) { true } %>
```

If the landing page diverges further (different `<head>` tags, no Turbo, separate nav component), promote it to a dedicated `app/views/layouts/landing.html.erb`.

---

## 4. Landing Page View Structure

### Hero Section

```erb
<section class="relative text-center max-w-3xl mx-auto flex flex-col items-center justify-center py-16 md:py-24">
  <%# Animated rings — pure SVG <animate> elements, no JS needed %>
  <svg class="absolute -z-10 top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[150%] max-w-2xl
              opacity-20 dark:opacity-10 pointer-events-none"
       viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
    <circle cx="100" cy="100" r="40" fill="none" stroke="currentColor" stroke-width="2"
            class="text-[#c25044] dark:text-[#e2a8a0]">
      <animate attributeName="r" values="40;90;40" dur="6s" repeatCount="indefinite"/>
      <animate attributeName="opacity" values="1;0;1" dur="6s" repeatCount="indefinite"/>
    </circle>
    <circle cx="100" cy="100" r="60" fill="none" stroke="currentColor" stroke-width="1"
            class="text-[#5a2323] dark:text-[#ffc4bc]">
      <animate attributeName="r" values="60;120;60" dur="8s" repeatCount="indefinite"/>
      <animate attributeName="opacity" values="0.8;0;0.8" dur="8s" repeatCount="indefinite"/>
    </circle>
  </svg>

  <div class="inline-block relative z-10 p-8 md:p-12 w-full rounded-2xl bg-white/90 dark:bg-[#1a1a1c]/90
              backdrop-blur-md border border-slate-200 dark:border-[#222225] shadow-sm mb-8 transition-colors duration-300">
    <h1 class="text-4xl md:text-5xl lg:text-6xl font-bold tracking-tight mb-6 pb-2
               text-transparent bg-clip-text bg-gradient-to-r
               from-[#8a3333] via-[#e25d4f] to-[#5a2323]
               dark:from-[#ffc4bc] dark:via-[#e2a8a0] dark:to-[#a86860] animate-gradient-x">
      <%= t("landing.hero.title") %>
    </h1>
    <p class="text-lg md:text-xl text-slate-600 dark:text-slate-400 max-w-2xl mx-auto leading-relaxed">
      <%= t("landing.hero.subtitle") %>
    </p>
  </div>
</section>
```

### Feature Cards Grid

Define the cards as a local array and render a partial to avoid repetition. Tailwind class strings must be static (no string interpolation) for the purger, so a lookup hash per color is used inside the partial.

```erb
<%# app/views/application/index.html.erb %>
<%
  features = [
    { icon: "lock",     color: "blue",    i18n_key: "authentication",   animated_type: "lock" },
    { icon: "shield",   color: "emerald", i18n_key: "authorization",    animated_type: "shield" },
    { icon: "connect",  color: "violet",  i18n_key: "real_time",        animated_type: "connect" },
    { icon: "charts",   color: "rose",    i18n_key: "admin_panel",      animated_type: "charts" },
    { icon: "layers",   color: "amber",   i18n_key: "ui_components",    animated_type: "layers" },
    { icon: "chat",     color: "cyan",    i18n_key: "support_tickets",  animated_type: "chat" },
    { icon: "sliders",  color: "orange",  i18n_key: "profile_settings", animated_type: "sliders" },
    { icon: "contrast", color: "fuchsia", i18n_key: "theme_support",    animated_type: "contrast" },
  ]
%>
<section>
  <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-16">
    <% features.each do |feature| %>
      <%= render "shared/landing/feature_card", feature: feature %>
    <% end %>
  </div>
</section>
```

```erb
<%# app/views/shared/landing/_feature_card.html.erb %>
<%
  # Static class lookup required for Tailwind CSS purging
  BORDER_HOVER = {
    "blue"    => "hover:border-blue-200 dark:hover:border-blue-900/50",
    "emerald" => "hover:border-emerald-200 dark:hover:border-emerald-900/50",
    "violet"  => "hover:border-violet-200 dark:hover:border-violet-900/50",
    "rose"    => "hover:border-rose-200 dark:hover:border-rose-900/50",
    "amber"   => "hover:border-amber-200 dark:hover:border-amber-900/50",
    "cyan"    => "hover:border-cyan-200 dark:hover:border-cyan-900/50",
    "orange"  => "hover:border-orange-200 dark:hover:border-orange-900/50",
    "fuchsia" => "hover:border-fuchsia-200 dark:hover:border-fuchsia-900/50",
  }.freeze

  BG_HOVER = {
    "blue"    => "group-hover:bg-blue-50 dark:group-hover:bg-blue-900/20",
    "emerald" => "group-hover:bg-emerald-50 dark:group-hover:bg-emerald-900/20",
    "violet"  => "group-hover:bg-violet-50 dark:group-hover:bg-violet-900/20",
    "rose"    => "group-hover:bg-rose-50 dark:group-hover:bg-rose-900/20",
    "amber"   => "group-hover:bg-amber-50 dark:group-hover:bg-amber-900/20",
    "cyan"    => "group-hover:bg-cyan-50 dark:group-hover:bg-cyan-900/20",
    "orange"  => "group-hover:bg-orange-50 dark:group-hover:bg-orange-900/20",
    "fuchsia" => "group-hover:bg-fuchsia-50 dark:group-hover:bg-fuchsia-900/20",
  }.freeze

  TITLE_HOVER = {
    "blue"    => "group-hover:text-blue-700 dark:group-hover:text-blue-400",
    "emerald" => "group-hover:text-emerald-700 dark:group-hover:text-emerald-400",
    "violet"  => "group-hover:text-violet-700 dark:group-hover:text-violet-400",
    "rose"    => "group-hover:text-rose-700 dark:group-hover:text-rose-400",
    "amber"   => "group-hover:text-amber-700 dark:group-hover:text-amber-400",
    "cyan"    => "group-hover:text-cyan-700 dark:group-hover:text-cyan-400",
    "orange"  => "group-hover:text-orange-700 dark:group-hover:text-orange-400",
    "fuchsia" => "group-hover:text-fuchsia-700 dark:group-hover:text-fuchsia-400",
  }.freeze

  ICON_TEXT = {
    "blue"    => "text-blue-600 dark:text-blue-400",
    "emerald" => "text-emerald-600 dark:text-emerald-400",
    "violet"  => "text-violet-600 dark:text-violet-400",
    "rose"    => "text-rose-600 dark:text-rose-400",
    "amber"   => "text-amber-600 dark:text-amber-400",
    "cyan"    => "text-cyan-600 dark:text-cyan-400",
    "orange"  => "text-orange-600 dark:text-orange-400",
    "fuchsia" => "text-fuchsia-600 dark:text-fuchsia-400",
  }.freeze

  color = feature[:color]
%>

<div class="group relative bg-white dark:bg-[#1a1a1c] border border-slate-200 dark:border-[#2a2a2d]
            rounded-2xl p-6 transition-all duration-300 hover:shadow-xl hover:-translate-y-1 cursor-pointer
            <%= BORDER_HOVER[color] %>"
     data-action="mouseenter->animated-icon#start mouseleave->animated-icon#stop">

  <div class="flex items-center mb-4 space-x-4">
    <div class="relative w-14 h-14 shrink-0 rounded-xl flex items-center justify-center
                bg-slate-50 dark:bg-[#2a2a2d] transition-colors duration-300
                <%= BG_HOVER[color] %> <%= ICON_TEXT[color] %>">
      <%= icon(feature[:icon], classes: "w-7 h-7", animated_type: feature[:animated_type]) %>
    </div>
    <h3 class="text-lg font-semibold text-slate-800 dark:text-slate-100 transition-colors
               <%= TITLE_HOVER[color] %>">
      <%= t("landing.features.#{feature[:i18n_key]}.title") %>
    </h3>
  </div>
  <p class="text-sm text-slate-500 dark:text-slate-400 leading-relaxed">
    <%= t("landing.features.#{feature[:i18n_key]}.description") %>
  </p>
</div>
```

### Architecture & DX Section

```erb
<section class="border-t border-slate-200 dark:border-[#222225] pt-16">
  <h2 class="text-2xl font-semibold mb-8 text-slate-900 dark:text-slate-100 text-center">
    <%= t("landing.architecture.title") %>
  </h2>
  <%# cards rendered similarly with _sticky_note_card partial %>
</section>
```

---

## 5. Gradient Animation CSS

```erb
<%# In index.html.erb, injected into <head> via content_for %>
<% content_for :head do %>
  <style>
    @keyframes gradient-x {
      0%, 100% { background-position: 0% 50%; }
      50% { background-position: 100% 50%; }
    }
    .animate-gradient-x {
      background-size: 200% auto;
      animation: gradient-x 4s ease infinite;
    }
  </style>
<% end %>
```

---

## 6. I18n

All strings under `landing` namespace. Add to `config/locales/en/landing.yml` and `config/locales/es/landing.yml`.

**Decision rule**: landing content is specific to the landing page → `landing.yml`. Not `shared.yml`.

---

## 7. File Checklist

| # | File | Action | Notes |
|---|------|--------|-------|
| 1 | `config/importmap.rb` | Edit | Pin `motion`; add `pin_all_from "app/javascript/icons", under: "icons"` |
| 2 | `app/helpers/application_helper.rb` | Edit | Add `animated_type:` option to `icon()` |
| 3 | `app/javascript/controllers/animated_icon_controller.js` | Create | Stimulus controller with animation registry |
| 4 | `app/javascript/icons/lock.js` | Create | Lock animation module |
| 5 | `app/javascript/icons/connect.js` | Create | Connect animation module |
| 6 | `app/javascript/icons/charts.js` | Create | Charts animation module |
| 7 | `app/javascript/icons/sliders.js` | Create | Sliders animation module |
| 8 | `app/javascript/icons/contrast.js` | Create | Contrast animation module |
| 9 | `app/javascript/icons/shield.js` | Create | Shield animation module |
| 10 | `app/javascript/icons/layers.js` | Create | Layers animation module |
| 11 | `app/javascript/icons/chat.js` | Create | Chat animation module |
| 12 | `app/assets/images/icons/lock.svg` | Create | Lock SVG with `data-element` attrs |
| 13 | `app/assets/images/icons/connect.svg` | Create | Connect SVG with `data-element` attrs |
| 14 | `app/assets/images/icons/charts.svg` | Create | Charts SVG with `data-element` attrs |
| 15 | `app/assets/images/icons/sliders.svg` | Create | Sliders SVG with `data-element` attrs |
| 16 | `app/assets/images/icons/contrast.svg` | Create | Contrast SVG with `data-element` attrs |
| 17 | `app/assets/images/icons/shield.svg` | Create | Shield SVG with `data-element` attrs |
| 18 | `app/assets/images/icons/layers.svg` | Create | Layers SVG with `data-element` attrs |
| 19 | `app/assets/images/icons/chat.svg` | Create | Chat SVG with `data-element` attrs |
| 20 | `app/views/shared/landing/_feature_card.html.erb` | Create | Feature card partial |
| 21 | `app/views/shared/landing/_sticky_note_card.html.erb` | Create | Architecture section card |
| 22 | `app/views/application/index.html.erb` | Rewrite | Full landing page |
| 23 | `app/views/layouts/application.html.erb` | Edit | Conditional navbar/padding for landing |
| 24 | `config/locales/en/landing.yml` | Create | English strings |
| 25 | `config/locales/es/landing.yml` | Create | Spanish strings |

---

## 8. Architecture Decisions

### Why SVG files in `app/assets/images/icons/` instead of ERB partials?

The app already uses `inline_svg_tag` via the `icon()` helper to render icons from this directory. `inline_svg_tag` preserves all SVG attributes verbatim, including `data-element` — so the animated icon SVGs are just regular SVG files that happen to have extra attributes on child elements. This keeps everything consistent: one place for all icons, one way to render them.

### Why extend `icon()` rather than a separate helper?

`icon()` is already the single call site for SVG icons across the app. Adding `animated_type:` to it means no new API to learn. Static icons continue to work unchanged. Animated icons add one parameter.

### Why `app/javascript/icons/` for animation modules?

Mirrors the naming of `app/assets/images/icons/`. Same icon name, same folder name, different layer. `lock.svg` ↔ `icons/lock.js`. Intuitive to navigate between the visual asset and its animation logic.

### Why Motion JS over CSS-only?

The `landing-example.tsx` already has CSS-only equivalents (the `<style>` block with `group:hover` + CSS `d` transitions). We could ship those. However:

- **Spring physics**: CSS can't replicate `type: "spring"` (connect, sliders feel noticeably better)
- **Stagger sequences**: charts bar animation needs async sequencing CSS can't express
- **`pathLength` animation**: CSS `stroke-dashoffset` requires knowing the path length upfront; Motion calculates it
- **Reuse**: Motion's `animate()` applies to any future animation — scroll reveals, page transitions, micro-interactions
- **Size**: ~2.5kB gzipped

### Why a single controller with static imports?

- Static imports work reliably with importmap (no dynamic `import()` race conditions)
- All animations load once when the controller is registered — no per-element async overhead
- One controller file = one place to see all registered animation types
- Developers add new icons by editing one registry line, not by creating a new controller

### Why `data-element` instead of CSS classes for JS targeting?

`data-element="shackle"` is a stable contract between the SVG file and its animation module. CSS classes change for styling reasons. IDs must be globally unique (breaks when the same icon appears twice on a page). `data-element` is purpose-specific and collision-free.

---

## 9. Implementation Order

1. Pin Motion JS in importmap → verify `import { animate } from "motion"` works in browser console
2. Build one icon end-to-end: `lock.svg` + `app/javascript/icons/lock.js` + `animated_icon_controller.js` + extend `icon()` → verify hover animation works
3. Create remaining 7 SVG files + animation modules, register in controller
4. Build landing page: layout conditional → hero → feature cards grid → architecture section → footer
5. Add I18n strings (English + Spanish)
6. Test: animations, dark mode, responsive breakpoints, locale switching, page without JS (should still render icons statically)
