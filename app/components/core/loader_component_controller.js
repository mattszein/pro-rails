import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["spinner"]

  loaded() {
    this.element.classList.remove('is-loading');
    this.spinnerTarget.classList.add('hidden');
  }
}
