import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "panel", "list", "badge", "badgeWrapper"]

  connect() {

    console.log("MainNotificationsController connected")
    this.boundClickOutside = this.handleClickOutside.bind(this)
    this.boundStreamEvent = this.handleStream.bind(this)

    document.addEventListener("click", this.boundClickOutside)
    document.addEventListener("turbo:before-stream-render", this.boundStreamEvent)
    this.element.addEventListener('notifications--item-component:read', this.handleRead.bind(this))
  }

  disconnect() {
    document.removeEventListener("click", this.boundClickOutside)
    document.removeEventListener("turbo:before-stream-render", this.boundStreamEvent)
  }

  handleStream(event) {
    const stream = event.target
    if (stream.getAttribute("target") !== "notifications_list") return
    if (stream.getAttribute("action") !== "prepend") return

    console.log("Notification stream received!")

    // Increment badge
    const count = parseInt(this.badgeTarget.textContent || "0") + 1
    this.badgeTarget.textContent = count
    this.badgeWrapperTarget.classList.remove("hidden")

    // Extract toast data
    const template = stream.querySelector("template")
    if (!template) return
    const item = template.content.querySelector("a")
    if (!item) return
    const title = template.content.querySelector("[data-role='title']").textContent
    const subtitle = template.content.querySelector("[data-role='subtitle']").textContent
    this.dispatch("toast", {
      detail: {
        title: title,
        subtitle: subtitle
      },
      prefix: false,
      bubbles: true
    })
  }

  toggle(event) {
    event.stopPropagation()
    this.panelTarget.classList.toggle("hidden")
  }

  close() {
    this.panelTarget.classList.add("hidden")
    this.buttonTarget.setAttribute("aria-expanded", "false")
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  handleRead(event) {
    console.log("handleRead is executed, going to update badge")
    const count = Math.max(0, parseInt(this.badgeTarget.textContent || "0") - 1)
    this.badgeTarget.textContent = count
    if (count === 0) this.badgeWrapperTarget.classList.add("hidden")
  }

  // markAsRead(event) {
  //   const item = event.currentTarget
  //   const notificationId = item.dataset.notificationId
  //   if (!notificationId) return
  //
  //   // Remove unread styling
  //   item.classList.remove("unread")
  //
  //   // Decrement badge
  //   const count = Math.max(0, parseInt(this.badgeTarget.textContent || "0") - 1)
  //   this.badgeTarget.textContent = count
  //   if (count === 0) this.badgeWrapperTarget.classList.add("hidden")
  //
  //   new FetchRequest("post", `/notifications/${notificationId}/mark_as_read`).perform()
  // }
}
