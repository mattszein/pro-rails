import { animate } from "motion/dom"

const q = (svg, name) => svg.querySelector(`[data-element="${name}"]`)

export function start(svg) {
  ;["bar-1", "bar-2", "bar-3"].forEach((n, i) => {
    const bar = q(svg, n)
    if (bar) animate(bar, { strokeDashoffset: 0 }, { duration: 0.4, delay: i * 0.12, easing: [0.4, 0, 0.2, 1] })
  })
}

export function stop(svg) {
  ;["bar-1", "bar-2", "bar-3"].forEach((n) => {
    const bar = q(svg, n)
    if (bar) animate(bar, { strokeDashoffset: 1 }, { duration: 0.3, easing: [0.4, 0, 0.2, 1] })
  })
}
