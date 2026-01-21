import { Controller } from "@hotwired/stimulus"

const ANIMATE_IN_RIGHT = 'animate-slide-in-right'
const ANIMATE_OUT_RIGHT = 'animate-slide-out-right'

export default class extends Controller {
  static targets = ["toast"]

  connect() {
    // Add entrance animation
    this.toastTarget.classList.remove('hidden')
    this.toastTarget.classList.add(ANIMATE_IN_RIGHT)

    // Setup auto-dismiss
    if (true) {
      this.timeout = setTimeout(() => {
        this.dismiss()
      }, 8000)
    }
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  dismiss() {
    // Add exit animation
    if (!this.toastTarget.isConnected) return // Already removed
    this.toastTarget.classList.remove(ANIMATE_IN_RIGHT)
    this.toastTarget.classList.add(ANIMATE_OUT_RIGHT)

    // Remove element after animation
    setTimeout(() => {
      this.toastTarget.remove()
    }, 300)
  }
}
