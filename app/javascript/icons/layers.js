import { animate } from "motion/dom"

const q = (svg, name) => svg.querySelector(`[data-element="${name}"]`)
const SPRING = { easing: "spring(100, 14)" }

export async function start(svg) {
  const bottom = q(svg, "bottom")
  const middle = q(svg, "middle")
  if (!bottom || !middle) return

  await Promise.all([
    animate(bottom, { y: -9 }, SPRING).finished,
    animate(middle, { y: -5 }, SPRING).finished,
  ])

  animate(bottom, { y: 0 }, SPRING)
  animate(middle, { y: 0 }, SPRING)
}

export function stop(svg) {
  const bottom = q(svg, "bottom")
  const middle = q(svg, "middle")
  if (bottom) animate(bottom, { y: 0 }, SPRING)
  if (middle) animate(middle, { y: 0 }, SPRING)
}
