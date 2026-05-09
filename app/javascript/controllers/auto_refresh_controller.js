import { Controller } from "@hotwired/stimulus"

// Refreshes the page via Turbo at a given interval.
// Used as a fallback when Turbo Stream subscriptions may miss a broadcast
// (e.g. avatar generation completing before the subscription is established).
// Automatically stops when the controller disconnects (element removed from DOM).
export default class extends Controller {
  static values = { interval: { type: Number, default: 8000 } }

  connect() {
    if (this.intervalValue > 0) {
      this.timer = setInterval(() => this.refresh(), this.intervalValue)
    }
  }

  disconnect() {
    clearInterval(this.timer)
  }

  refresh() {
    Turbo.visit(location.href, { action: "replace" })
  }
}
