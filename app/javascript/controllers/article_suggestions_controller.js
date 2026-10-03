import { Controller } from "@hotwired/stimulus"

// New-ticket form: after the user pauses typing, points the "help_suggestions"
// turbo frame at the server-rendered suggestions endpoint (ticket deflection).
export default class extends Controller {
  static targets = ["title", "description", "category", "frame"]
  static values = { url: String, delay: { type: Number, default: 400 }, minLength: { type: Number, default: 3 } }

  disconnect() {
    clearTimeout(this.timer)
  }

  schedule() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.load(), this.delayValue)
  }

  load() {
    if (!this.hasFrameTarget) return
    const query = [this.titleTarget?.value, this.descriptionTarget?.value].join(" ").trim()
    if (query.length < this.minLengthValue) {
      this.frameTarget.removeAttribute("src")
      this.frameTarget.replaceChildren()
      return
    }
    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("q", query)
    if (this.hasCategoryTarget && this.categoryTarget.value) {
      url.searchParams.set("category", this.categoryTarget.value)
    }
    this.frameTarget.src = url.toString()
  }
}
