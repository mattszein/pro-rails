import { animate } from "motion/dom"

export function start(svg) {
  svg.style.transformOrigin = "0% 100%"
  svg.style.transformBox = "fill-box"
  animate(svg, { rotate: [0, -20, 25, 0] }, { duration: 0.8, easing: "ease-in-out" })
}

export function stop(svg) {
  svg.style.transformOrigin = "0% 100%"
  svg.style.transformBox = "fill-box"
  animate(svg, { rotate: 0 }, { duration: 0.3 })
}
