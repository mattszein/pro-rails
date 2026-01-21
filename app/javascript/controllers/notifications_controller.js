import { Controller } from "@hotwired/stimulus"
import cable from "cable"

export default class extends Controller {
  static targets = ["container", "template"]

  connect() {
    console.log("Connecting to Noticed Channel...")
    this.channel = cable.subscribeTo("Noticed::NotificationChannel")

    this.channel.on("message", (data) => {
      this.show(data)
    })

    // Optional: Handle connection status
    this.channel.on("connect", () => {
      console.log("Subscribed successfully to Notifications")
    })
  }

  disconnect() {

    if (this.channel) this.channel.disconnect()
  }

  show(data) {
    const clone = this.templateTarget.content.cloneNode(true)
    const toast = clone.querySelector("[data-role='toast']")

    toast.querySelector("[data-role='title']").textContent = data.title || "Notification"
    toast.querySelector("[data-role='message']").textContent = data.message || ""

    this.containerTarget.appendChild(toast)

    // requestAnimationFrame(() => {
    //   toast.classList.remove("translate-y-2", "opacity-0", "scale-95")
    //   toast.classList.add("translate-y-0", "opacity-100", "scale-100")
    // })
    //
    // setTimeout(() => {
    //   this.remove(toast)
    // }, 10000)
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
