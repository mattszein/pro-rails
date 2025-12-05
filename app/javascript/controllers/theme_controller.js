import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]

  connect() {
    // Load and apply theme from localStorage on page load
    const savedTheme = localStorage.getItem('theme_color')
    if (savedTheme) {
      document.documentElement.classList.add(`theme-${savedTheme}`)
      this.updateSelectedStates(savedTheme)
    }
  }

  selectTheme(event) {
    event.preventDefault()

    const themeId = event.currentTarget.dataset.themeId
    if (!themeId) {
      console.warn('No theme_id found in data-theme-id attribute')
      return
    }

    // Remove the old theme class if it exists
    const currentTheme = localStorage.getItem('theme_color')
    if (currentTheme) {
      document.documentElement.classList.remove(`theme-${currentTheme}`)
    }

    document.documentElement.classList.add(`theme-${themeId}`)
    localStorage.setItem('theme_color', themeId)
    this.updateSelectedStates(themeId)
  }

  updateSelectedStates(selectedThemeId) {
    this.buttonTargets.forEach(button => {
      const buttonThemeId = button.dataset.themeId
      if (buttonThemeId === selectedThemeId) {
        button.classList.add('selected')
      } else {
        button.classList.remove('selected')
      }
    })
  }
}
