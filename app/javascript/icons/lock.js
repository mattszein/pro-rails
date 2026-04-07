import { animate } from "motion/dom"

const q = (svg, name) => svg.querySelector(`[data-element="${name}"]`)

export function start(svg) {
  animate(svg, { rotate: [-3, 1, -2, 0], scale: [0.95, 1.05, 0.98, 1] }, { duration: 1, easing: [0.4, 0, 0.2, 1] })

  const shackle = q(svg, "shackle")
  if (shackle) animate(shackle, { pathLength: 0.7 }, { duration: 0.3, easing: [0.4, 0, 0.2, 1] })
}

export function stop(svg) {
  animate(svg, { rotate: 0, scale: 1 }, { duration: 0.3 })

  const shackle = q(svg, "shackle")
  if (shackle) animate(shackle, { pathLength: 1 }, { duration: 0.3 })
}
