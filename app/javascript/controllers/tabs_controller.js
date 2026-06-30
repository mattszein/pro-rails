import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = { activeClasses: String, inactiveClasses: String }

  select(event) {
    const index = event.currentTarget.dataset.index
    this.activate(index)
  }

  activate(index) {
    const active = this.activeClassesValue.split(/\s+/).filter(Boolean)
    const inactive = this.inactiveClassesValue.split(/\s+/).filter(Boolean)

    this.tabTargets.forEach((tab) => {
      const isActive = tab.dataset.index === index
      tab.setAttribute("aria-selected", isActive ? "true" : "false")
      tab.classList.add(...(isActive ? active : inactive))
      tab.classList.remove(...(isActive ? inactive : active))
    })

    this.panelTargets.forEach((panel) => {
      panel.classList.toggle("hidden", panel.dataset.index !== index)
    })
  }
}
