import { animate } from "motion/dom"

const q = (svg, name) => svg.querySelector(`[data-element="${name}"]`)
const SPRING = { easing: "spring(500, 30)" }

export function start(svg) {
  animate(q(svg, "wire-1"), { d: "M17 7l5-5" }, SPRING)
  animate(q(svg, "wire-2"), { d: "M2 22l6-6" }, SPRING)
  animate(q(svg, "socket"), { x: 3, y: -3 }, SPRING)
  animate(q(svg, "plug"), { x: -3, y: 3 }, SPRING)
  animate(q(svg, "pin-1"), { d: "M10.43 10.57l0.1-0.1" }, SPRING)
  animate(q(svg, "pin-2"), { d: "M13.43 13.57l0.1-0.1" }, SPRING)
}

export function stop(svg) {
  animate(q(svg, "wire-1"), { d: "M19 5l3-3" }, SPRING)
  animate(q(svg, "wire-2"), { d: "M2 22l3-3" }, SPRING)
  animate(q(svg, "socket"), { x: 0, y: 0 }, SPRING)
  animate(q(svg, "plug"), { x: 0, y: 0 }, SPRING)
  animate(q(svg, "pin-1"), { d: "M7.5 13.5L10 11" }, SPRING)
  animate(q(svg, "pin-2"), { d: "M10.5 16.5L13 14" }, SPRING)
}
