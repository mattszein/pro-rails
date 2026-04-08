import { animate } from "motion/dom"

const DOT_COUNT = 9

export async function start(svg) {
  const dots = []
  for (let i = 0; i < DOT_COUNT; i++) {
    const dot = svg.querySelector(`[data-element="dot-${i}"]`)
    if (dot) dots.push({ el: dot, index: i })
  }

  const animations = dots.map(({ el, index }) =>
    animate(
      el,
      { opacity: [1, 0.3, 0.3, 1] },
      {
        delay: index * 0.07,
        duration: 1.1,
        offset: [0, 0.2, 0.8, 1]
      }
    )
  )

  await Promise.all(animations.map((a) => a.finished))
}

export function stop(svg) {
  for (let i = 0; i < DOT_COUNT; i++) {
    const dot = svg.querySelector(`[data-element="dot-${i}"]`)
    if (dot) animate(dot, { opacity: 1 }, { duration: 0.25 })
  }
}
