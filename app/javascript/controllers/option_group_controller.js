import { Controller } from "@hotwired/stimulus"

// Wraps a grid of option cards (radio buttons).
// Validates that at least one option is selected before the form submits.
export default class extends Controller {
  static targets = ["card", "error"]

  validate(event) {
    const hasSelection = this.cardTargets.some(card =>
      card.querySelector("input[type='radio']")?.checked
    )

    if (!hasSelection) {
      event.preventDefault()
      if (this.hasErrorTarget) {
        this.errorTarget.classList.remove("hidden")
      }
    } else {
      if (this.hasErrorTarget) {
        this.errorTarget.classList.add("hidden")
      }
    }
  }

  refresh() {
    if (this.hasErrorTarget) {
      this.errorTarget.classList.add("hidden")
    }
  }
}
