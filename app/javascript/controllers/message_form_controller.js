import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea", "submit"]

  connect() {
    console.log("Message form connected")
    this.textareaTarget.focus()
  }

  disconnect() {
    console.log("Message form disconnected")
  }

  handleKeydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      if (this.textareaTarget.value.trim() !== "") {
        this.submitTarget.form.requestSubmit()
      }
    }
  }

  beforeSubmit() {
    console.log("Form submitting...")
    this.textareaTarget.disabled = true
    this.submitTarget.disabled = true
    this.submitTarget.textContent = "Sending..."
  }

  afterSubmit(event) {
    console.log("Form submitted, success:", event.detail.success)

    if (!event.detail.success) {
      // Only re-enable on error (success will replace the form)
      this.textareaTarget.disabled = false
      this.submitTarget.disabled = false
      this.submitTarget.textContent = "Send"
      this.textareaTarget.focus()
    }
  }
}
