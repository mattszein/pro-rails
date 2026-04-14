import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview"]
  static values = { colors: Array }

  connect() {
    this.updatePreview()
  }

  addColor(event) {
    const color = event.target.value
    if (!this.colorsValue.includes(color) && this.colorsValue.length < 3) {
      this.colorsValue = [...this.colorsValue, color]
      this.updateInputs()
      this.updatePreview()
    }
  }

  removeColor(event) {
    const color = event.params.color
    this.colorsValue = this.colorsValue.filter(c => c !== color)
    this.updateInputs()
    this.updatePreview()
  }

  updateInputs() {
    // Remove existing hidden inputs for custom colors
    this.element.querySelectorAll("[data-color-picker-hidden]").forEach(el => el.remove())

    // Add new hidden inputs
    this.colorsValue.forEach(color => {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = "avatar[dna][custom_colors][]"
      input.value = color
      input.dataset.colorPickerHidden = true
      this.element.appendChild(input)
    })
  }

  updatePreview() {
    if (this.hasPreviewTarget) {
      this.previewTarget.innerHTML = this.colorsValue.map(color =>
        `<div class="w-5 h-5 rounded-full border border-white/20 shadow-sm" style="background-color: ${color}"></div>`
      ).join("")
    }
  }
}
