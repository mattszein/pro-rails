import { animate } from "motion"

const q = (svg, name) => svg.querySelector(`[data-element="${name}"]`)

export function start(svg) {
  const check = q(svg, "checkmark")
  if (!check) return
  const length = check.getTotalLength?.() ?? 20
  check.style.strokeDasharray = length
  animate(check, { strokeDashoffset: [length, 0] }, { duration: 0.5, easing: [0.4, 0, 0.2, 1] })
}

export function stop(svg) {
  const check = q(svg, "checkmark")
  if (!check) return
  check.style.strokeDasharray = "none"
  check.style.strokeDashoffset = "0"
}
