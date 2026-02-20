import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "panel", "list", "badge", "badgeWrapper"]

  connect() {
    this.boundClickOutside = this.handleClickOutside.bind(this)
    this.boundStreamEvent = this.handleStream.bind(this)
    this.boundHandleRead = this.handleRead.bind(this)
    document.addEventListener("click", this.boundClickOutside)
    document.addEventListener("turbo:before-stream-render", this.boundStreamEvent)
    this.element.addEventListener('notifications--item-component:read', this.boundHandleRead)
  }

  disconnect() {
    document.removeEventListener("click", this.boundClickOutside)
    document.removeEventListener("turbo:before-stream-render", this.boundStreamEvent)
    this.element.removeEventListener('notifications--item-component:read', this.boundHandleRead)
  }

  handleStream(event) {
    const stream = event.target
    if (stream.getAttribute("target") !== "notifications_list") return
    if (stream.getAttribute("action") !== "prepend") return

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
    const count = parseInt(this.badgeTarget.textContent || "0") - 1
    this.badgeTarget.textContent = count
    if (count === 0) this.badgeWrapperTarget.classList.add("hidden")
  }

}
