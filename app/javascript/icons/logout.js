import { animate } from "motion/dom"

const q = (svg, name) => svg.querySelector(`[data-element="${name}"]`)

export function start(svg) {
  const head = q(svg, "arrow-head")
  const line = q(svg, "arrow-line")
  if (head) animate(head, { x: [0, -3, 2] }, { duration: 0.4 })
  if (line) animate(line, { x: [0, -3, 2] }, { duration: 0.4 })
}

export function stop(svg) {
  const head = q(svg, "arrow-head")
  const line = q(svg, "arrow-line")
  if (head) animate(head, { x: 0 }, { duration: 0.2 })
  if (line) animate(line, { x: 0 }, { duration: 0.2 })
}
