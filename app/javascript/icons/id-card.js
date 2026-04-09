import { animate } from "motion/dom"

const q = (svg, name) => svg.querySelector(`[data-element="${name}"]`)
const ELEMENTS = ["shoulders", "head", "line-1", "line-2"]

export function start(svg) {
  ELEMENTS.forEach((name, i) => {
    const el = q(svg, name)
    if (el) {
      animate(
        el,
        { strokeDashoffset: [1, 0], opacity: [0, 1] },
        { duration: 0.3, delay: i * 0.1, easing: [0.4, 0, 0.2, 1] }
      )
    }
  })
}

export function stop(svg) {
  ELEMENTS.forEach((name) => {
    const el = q(svg, name)
    if (el) animate(el, { strokeDashoffset: 0, opacity: 1 }, { duration: 0 })
  })
}
