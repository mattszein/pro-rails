import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["counter"]

  increment() {
    let max = this.counterTarget.max
    if (max && this.counterTarget.value >= max) return
    this.counterTarget.value = parseInt(this.counterTarget.value) + 1;
  }

  decrement() {
    let min = this.counterTarget.min
    if (min && this.counterTarget.value <= min) return
    this.counterTarget.value = parseInt(this.counterTarget.value) - 1;
  }
}
