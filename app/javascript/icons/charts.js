import { animate } from "motion"

const q = (svg, name) => svg.querySelector(`[data-element="${name}"]`)

export async function start(svg) {
  const bars = ["bar-1", "bar-2", "bar-3"].map((n) => q(svg, n)).filter(Boolean)

  bars.forEach((bar, i) =>
    animate(bar, { pathLength: 0, opacity: 0 }, { duration: 0.3, delay: i * 0.1 })
  )

  await new Promise((r) => setTimeout(r, bars.length * 100 + 300))

  bars.forEach((bar, i) =>
    animate(bar, { pathLength: 1, opacity: 1 }, { duration: 0.3, delay: i * 0.1 })
  )
}

export function stop(svg) {
  ;["bar-1", "bar-2", "bar-3"].forEach((n) => {
    const bar = q(svg, n)
    if (bar) animate(bar, { pathLength: 1, opacity: 1 }, { duration: 0.2 })
  })
}
