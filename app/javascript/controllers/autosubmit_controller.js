import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  submit() {
    if (typeof this.element.requestSubmit === "function") {
      this.element.requestSubmit()
    } else {
      this.element.submit()
    }
  }
}
