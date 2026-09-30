import { Controller } from "@hotwired/stimulus"

// Opens the drawer on click/tap. Desktop hover still works via CSS (`hover:w-80`);
// `data-open` keeps it open on touch devices, where Tailwind's hover variant never applies.
export default class extends Controller {
  static targets = ["toggle"]

  toggle() {
    this.isOpen ? this.close() : this.open()
  }

  open() {
    this.element.dataset.open = ""
    this.toggleTarget.setAttribute("aria-expanded", "true")
  }

  close() {
    delete this.element.dataset.open
    this.toggleTarget.setAttribute("aria-expanded", "false")
  }

  closeOnOutsideClick(event) {
    if (this.isOpen && !this.element.contains(event.target)) this.close()
  }

  get isOpen() {
    return "open" in this.element.dataset
  }
}
