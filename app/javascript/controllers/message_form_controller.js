import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea", "submit"]

  handleKeydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      if (this.textareaTarget.value.trim() !== "") {
        this.submitTarget.form.requestSubmit()
      }
    }
  }

  beforeSubmit() {
    this.textareaTarget.disabled = true
    this.submitTarget.disabled = true
    this.submitTarget.textContent = "Sending..."
  }

  afterSubmit(event) {
    if (!event.detail.success) {
      // Only re-enable on error (success will replace the form)
      this.textareaTarget.disabled = false
      this.submitTarget.disabled = false
      this.submitTarget.textContent = "Send"
      this.textareaTarget.focus()
    }
  }
}
