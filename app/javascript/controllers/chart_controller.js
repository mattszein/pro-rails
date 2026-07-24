import { Controller } from "@hotwired/stimulus"
import ApexCharts from "apexcharts"

export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    options: Object,
    height: { type: Number, default: 280 }
  }

  /**
   * Renders the chart into the canvas target on connect. Skips the render if
   * the canvas already has content (e.g. a restored Turbo cache snapshot) and
   * hides the canvas when the options are unrenderable. Also watches the
   * `<html class="dark">` toggle so the chart re-themes without a reload.
   */
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

    this.themeObserver = new MutationObserver(() => this.rebuildChart())
    this.themeObserver.observe(document.documentElement, {attributes: true, attributeFilter: ["class"]})
  }

  /**
   * Tears down the ApexCharts instance and empties the canvas so a reconnect
   * (Turbo frame reload, theme change) renders from a clean slate.
   */
  disconnect() {
    this.themeObserver?.disconnect()
    this.chart?.destroy()
    this.canvasTarget.replaceChildren();
    this.chart = null
  }

  /**
   * Destroys and re-renders the chart with fresh options (used when the
   * options value changes or the theme flips between dark/light).
   */
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

  /** Reads a CSS custom property (theme palette token) from the root element. */
  readCSSVar(name) {
    return getComputedStyle(document.documentElement).getPropertyValue(name).trim()
  }

  /**
   * Merges the user options hash with the controller defaults: resolves
   * semantic color tokens to theme CSS variables, expands formatter tokens
   * into real functions, and applies dark/light aware chrome (grid, tooltip).
   */
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

  /**
   * Replaces string formatter tokens ("_integer", "_percent", "_sum",
   * "_static:<value>") on an options node with real formatter functions,
   * since JSON data attributes cannot carry functions.
   */
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

  /** Hardcoded hex fallbacks used only when a semantic CSS variable is missing. */
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
