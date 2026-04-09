import { animate } from "motion/dom"

const q = (svg, name) => svg.querySelector(`[data-element="${name}"]`)
const SPRING = { easing: "spring(200, 13)" }

export function start(svg) {
  const head = q(svg, "second-head")
  const body = q(svg, "second-body")
  if (head) animate(head, { x: [-6, 0] }, { ...SPRING, delay: 0.1 })
  if (body) animate(body, { x: [-6, 0] }, { ...SPRING, delay: 0.1 })
}

export function stop(svg) {
  const head = q(svg, "second-head")
  const body = q(svg, "second-body")
  if (head) animate(head, { x: 0 }, SPRING)
  if (body) animate(body, { x: 0 }, SPRING)
}
