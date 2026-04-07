import { animate } from "motion"

const q = (svg, name) => svg.querySelector(`[data-element="${name}"]`)
const SPRING = { easing: "spring(300, 20)" }

export function start(svg) {
  animate(q(svg, "top"), { y: -2 }, SPRING)
  animate(q(svg, "bot"), { y: 2 }, SPRING)
}

export function stop(svg) {
  animate(q(svg, "top"), { y: 0 }, SPRING)
  animate(q(svg, "bot"), { y: 0 }, SPRING)
}
