import { Controller } from "@hotwired/stimulus"
import ApexCharts from "apexcharts"

export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    options: Object,
    height: { type: Number, default: 280 }
  }

  connect() {
    try {
      if (!this.canvasTarget.hasChildNodes()) {
        const merged = this.buildOptions()
        this.chart = new ApexCharts(this.canvasTarget, merged)
        this.chart.render()
      }
    } catch (err) {
      console.error("Chart render failed:", err)
      this.canvasTarget.style.display = "none"
    }

  }

  disconnect() {
    console.log("disconnect is executed")
    this.themeObserver?.disconnect()
    this.chart?.destroy()
    this.canvasTarget.replaceChildren();
    this.chart = null
  }

  rebuildChart() {
    this.chart?.destroy()
    try {
      const merged = this.buildOptions()
      this.chart = new ApexCharts(this.canvasTarget, merged)
      this.chart.render()
    } catch (err) {
      console.error("Chart rebuild failed:", err)
    }
  }

  readCSSVar(name) {
    return getComputedStyle(document.documentElement).getPropertyValue(name).trim()
  }

  buildOptions() {
    const isDark = document.documentElement.classList.contains("dark")
    const userOptions = this.optionsValue

    if (userOptions._semanticColors) {
      userOptions.colors = userOptions._semanticColors.map(
        c => this.readCSSVar(`--color-${c}-500`) || this.fallbackColor(c)
      )
      delete userOptions._semanticColors
    }

    if (userOptions._totalFormatter === "sum") {
      delete userOptions._totalFormatter
      if (userOptions.plotOptions?.pie?.donut?.labels?.total) {
        userOptions.plotOptions.pie.donut.labels.total.formatter = (w) => {
          return w.globals.seriesTotals.reduce((a, b) => a + b, 0)
        }
      }
    }

    this.resolveFormatter(userOptions.plotOptions?.radialBar?.dataLabels?.value, "formatter")
    this.resolveFormatter(userOptions.plotOptions?.radialBar?.dataLabels?.total, "formatter")
    this.resolveFormatter(userOptions.tooltip?.y, "formatter")

    const { chart: userChart, ...restOptions } = userOptions

    return {
      chart: {
        type: "donut",
        background: "transparent",
        fontFamily: "inherit",
        height: this.heightValue,
        toolbar: { show: false },
        animations: { enabled: true, speed: 400 },
        ...userChart
      },
      theme: { mode: isDark ? "dark" : "light" },
      tooltip: { theme: isDark ? "dark" : "light" },
      grid: { borderColor: isDark ? "#374151" : "#e5e7eb" },
      ...restOptions
    }
  }

  resolveFormatter(host, key) {
    if (!host) return
    const token = host[key]
    if (typeof token !== "string") return
    if (token === "_integer") {
      host[key] = (val) => Math.round(Number(val) || 0)
    } else if (token === "_percent") {
      host[key] = (val) => `${Math.round(Number(val) || 0)}%`
    } else if (token === "_sum") {
      host[key] = (_val, opts) => {
        const totals = opts?.globals?.seriesTotals || []
        return totals.reduce((a, b) => a + Number(b || 0), 0)
      }
    } else if (token.startsWith("_static:")) {
      const staticValue = token.slice("_static:".length)
      host[key] = () => staticValue
    }
  }

  fallbackColor(semanticName) {
    const fallbacks = {
      primary: "#6366f1",
      info: "#3b82f6",
      success: "#22c55e",
      warning: "#f59e0b",
      danger: "#ef4444"
    }
    return fallbacks[semanticName] || "#6366f1"
  }
}
