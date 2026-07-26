import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox"]

  connect() {
    this.updateSelectionCount()
  }

  toggle() {
    this.updateSelectionCount()
  }

  updateSelectionCount() {
    const selected = this.checkboxTargets.filter(cb => cb.checked).length
    const countEl = this.element.querySelector("[data-mood-board-count]")
    if (countEl) {
      countEl.textContent = selected
    }
  }
}
