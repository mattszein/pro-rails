import { animate } from "motion/dom"

const q = (svg, name) => svg.querySelector(`[data-element="${name}"]`)

export function start(svg) {
  const half = q(svg, "half")
  if (half) {
    half.style.transformOrigin = "12px 12px"
    animate(half, { rotate: 180 }, { easing: "spring(80, 12)" })
  }
}

export function stop(svg) {
  const half = q(svg, "half")
  if (half) {
    half.style.transformOrigin = "12px 12px"
    animate(half, { rotate: 0 }, { easing: "spring(80, 12)" })
  }
}
