import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  closeModal() {
    this.element.parentElement.removeAttribute("src");
    this.dispatch("remove");
  }

  // hide modal on successful form submission
  submitEnd(element) {
    if (element.detail.success) {
      this.closeModal()
    }
  }
}
