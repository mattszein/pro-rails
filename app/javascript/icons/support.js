import { animate } from "motion/dom"

export function start(svg) {
  svg.style.transformOrigin = "12px 12px"
  animate(svg, { rotate: [0, -7, 7, 0] }, { duration: 0.5, easing: "ease-in-out" })
  animate(svg, { scale: 1.05 }, { easing: "spring(400, 10)" })
}

export function stop(svg) {
  svg.style.transformOrigin = "12px 12px"
  animate(svg, { rotate: 0, scale: 1 }, { duration: 0.3 })
}
