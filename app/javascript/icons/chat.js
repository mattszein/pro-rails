import { animate } from "motion/dom"

const q = (svg, name) => svg.querySelector(`[data-element="${name}"]`)

export function start(svg) {
  ;["dot-1", "dot-2", "dot-3"].forEach((name, i) => {
    const dot = q(svg, name)
    if (dot) animate(dot, { opacity: 1 }, { duration: 0.3, delay: i * 0.075 })
  })
}

export function stop(svg) {
  ;["dot-1", "dot-2", "dot-3"].forEach((name) => {
    const dot = q(svg, name)
    if (dot) animate(dot, { opacity: 0 }, { duration: 0.2 })
  })
}
