import { animate } from "motion/dom"

const q = (svg, name) => svg.querySelector(`[data-element="${name}"]`)

export function start(svg) {
  const door = q(svg, "door")
  if (door) animate(door, { strokeDashoffset: [1, 0], opacity: [0, 1] }, { duration: 0.6, easing: [0.4, 0, 0.2, 1] })
}

export function stop(svg) {
  const door = q(svg, "door")
  if (door) animate(door, { strokeDashoffset: 0, opacity: 1 }, { duration: 0 })
}
