import { Controller } from "@hotwired/stimulus"
import cable from "cable"

export default class extends Controller {
  static targets = ["container", "template"]

  show(event) {
    const data = event.detail
    const clone = this.templateTarget.content.cloneNode(true)
    const toast = clone.querySelector("[data-role='toast']")

    toast.querySelector("[data-role='title']").textContent = data.title || "Notification"
    toast.querySelector("[data-role='subtitle']").textContent = data.subtitle || ""

    this.containerTarget.appendChild(toast)
  }

  close(event) {
    const toast = event.target.closest("[data-role='toast']")
    this.remove(toast)
  }

  remove(element) {
    if (!element.isConnected) return // Already removed

    element.classList.remove("translate-y-0", "opacity-100", "scale-100")
    element.classList.add("opacity-0", "translate-x-full")

    setTimeout(() => {
      element.remove()
    }, 300)
  }
}
