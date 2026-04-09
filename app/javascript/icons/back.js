import { animate } from "motion/dom"

const q = (svg, name) => svg.querySelector(`[data-element="${name}"]`)

export function start(svg) {
  const chevron = q(svg, "chevron")
  const line = q(svg, "line")
  if (chevron) animate(chevron, { x: [0, 3, 0] }, { duration: 0.4 })
  if (line) animate(line, { d: ["M19 12H5", "M19 12H10", "M19 12H5"] }, { duration: 0.4 })
}

export function stop(svg) {
  const chevron = q(svg, "chevron")
  const line = q(svg, "line")
  if (chevron) animate(chevron, { x: 0 }, { duration: 0.2 })
  if (line) animate(line, { d: "M19 12H5" }, { duration: 0.2 })
}
