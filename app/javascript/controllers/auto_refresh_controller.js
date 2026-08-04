import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { interval: { type: Number, default: 8000 } }

  connect() {
    if (!this.intervalValue || this.intervalValue <= 0) return
    this.timer = setInterval(() => this.element.reload(), this.intervalValue * 1000)
  }

  disconnect() {
    if (this.timer) clearInterval(this.timer)
  }
}
