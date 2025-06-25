import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["button", "parent", "code"]

  handle_input({ target: input }) {
    if (input.nextElementSibling && input.value) {
      input.nextElementSibling.focus()
    }
    let total = ""
    const listArray = Array.from(this.parentTarget.children);
    listArray.forEach((child) => {
      child.value && (total += child.value)
    })
    if (total.length == 6) {
      this.codeTarget.value = total
      this.buttonTarget.click()
    }
  }

  handle_paste(e) {
    const paste = e.clipboardData.getData('text')
    e.value = paste[0] || ''
    let i = 1
    let next = e.target.nextElementSibling
    while (next && paste.length > i) {
      next.value = paste[i] || ''
      next = next.nextElementSibling
      i++
    }

  }

  handle_delete(e) {
    e.target.value || e.target.previousElementSibling.focus()
  }

}
