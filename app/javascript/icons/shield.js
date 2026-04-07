import { animate } from "motion/dom"

const q = (svg, name) => svg.querySelector(`[data-element="${name}"]`)

export function start(svg) {
  const check = q(svg, "checkmark")
  if (check) animate(check, { strokeDashoffset: 0 }, { duration: 0.5, easing: [0.4, 0, 0.2, 1] })
}

export function stop(svg) {
  const check = q(svg, "checkmark")
  if (check) animate(check, { strokeDashoffset: 20 }, { duration: 0.3, easing: [0.4, 0, 0.2, 1] })
}
