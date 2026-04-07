import { animate } from "motion/dom"

const q = (svg, name) => svg.querySelector(`[data-element="${name}"]`)
const SPRING = { easing: "spring(100, 12, 0.4)" }

export function start(svg) {
  animate(q(svg, "track-1a"), { x2: 10 }, SPRING)
  animate(q(svg, "track-1b"), { x1: 5 }, SPRING)
  animate(q(svg, "track-2a"), { x2: 18 }, SPRING)
  animate(q(svg, "track-2b"), { x1: 13 }, SPRING)
  animate(q(svg, "track-3a"), { x2: 4 }, SPRING)
  animate(q(svg, "track-3b"), { x1: 8 }, SPRING)
  animate(q(svg, "knob-1"), { x1: 9, x2: 9 }, SPRING)
  animate(q(svg, "knob-2"), { x1: 14, x2: 14 }, SPRING)
  animate(q(svg, "knob-3"), { x1: 8, x2: 8 }, SPRING)
}

export function stop(svg) {
  animate(q(svg, "track-1a"), { x2: 14 }, SPRING)
  animate(q(svg, "track-1b"), { x1: 10 }, SPRING)
  animate(q(svg, "track-2a"), { x2: 12 }, SPRING)
  animate(q(svg, "track-2b"), { x1: 8 }, SPRING)
  animate(q(svg, "track-3a"), { x2: 12 }, SPRING)
  animate(q(svg, "track-3b"), { x1: 16 }, SPRING)
  animate(q(svg, "knob-1"), { x1: 14, x2: 14 }, SPRING)
  animate(q(svg, "knob-2"), { x1: 8, x2: 8 }, SPRING)
  animate(q(svg, "knob-3"), { x1: 16, x2: 16 }, SPRING)
}
