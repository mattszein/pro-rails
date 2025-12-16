import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]

  connect() {
    // Load and apply font from localStorage on page load
    const savedFont = localStorage.getItem('font')
    if (savedFont) {
      document.documentElement.classList.add(`font-${savedFont}`)
      this.updateSelectedStates(savedFont)
    }
  }

  selectFont(event) {
    event.preventDefault()

    const fontId = event.currentTarget.dataset.fontId
    if (!fontId) {
      console.warn('No font_id found in data-font-id attribute')
      return
    }

    // Remove the old font class if it exists
    const currentFont = localStorage.getItem('font')
    if (currentFont) {
      document.documentElement.classList.remove(`font-${currentFont}`)
    }

    document.documentElement.classList.add(`font-${fontId}`)
    localStorage.setItem('font', fontId)
    this.updateSelectedStates(fontId)
  }

  updateSelectedStates(selectedFontId) {
    this.buttonTargets.forEach(button => {
      const buttonFontId = button.dataset.fontId
      if (buttonFontId === selectedFontId) {
        button.classList.add('selected')
      } else {
        button.classList.remove('selected')
      }
    })
  }
}
