import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sparkText"]

  fillExample({ params: { example } }) {
    const textarea = this.element.querySelector("textarea")
    if (textarea) {
      textarea.value = example
      textarea.dispatchEvent(new Event("input", { bubbles: true }))
    }
  }
}
