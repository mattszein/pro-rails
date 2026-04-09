import { animate } from "motion/dom"

export function start(svg) {
  svg.style.transformOrigin = "12px 12px"
  animate(
    svg,
    {
      rotate: [0, -8, 8, -8, 0],
      scale: [1, 1.04, 1],
      y: [0, -2, 0]
    },
    { duration: 0.6, easing: "ease-in-out" }
  )
}

export function stop(svg) {
  svg.style.transformOrigin = "12px 12px"
  animate(svg, { rotate: 0, scale: 1, y: 0 }, { duration: 0.3 })
}
