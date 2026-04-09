import { animate } from "motion/dom"

const q = (svg, name) => svg.querySelector(`[data-element="${name}"]`)
const RAYS = ["ray-1", "ray-2", "ray-3", "ray-4", "ray-5", "ray-6", "ray-7", "ray-8"]

export function start(svg) {
  const sun = q(svg, "sun")
  if (sun) {
    sun.style.transformOrigin = "12px 12px"
    animate(sun, { rotate: [0, -5, 5, -2, 2, 0] }, { duration: 1.5, easing: "ease-in-out" })
  }

  RAYS.forEach((name, i) => {
    const ray = q(svg, name)
    if (ray) animate(ray, { opacity: [0, 1] }, { duration: 0.3, delay: i * 0.1 })
  })
}

export function stop(svg) {
  const sun = q(svg, "sun")
  if (sun) {
    sun.style.transformOrigin = "12px 12px"
    animate(sun, { rotate: 0 }, { duration: 0.2 })
  }

  RAYS.forEach((name) => {
    const ray = q(svg, name)
    if (ray) animate(ray, { opacity: 1 }, { duration: 0.2 })
  })
}
