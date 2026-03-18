import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.select = new TomSelect(this.element, {
      valueField: "value",
      labelField: "text",
      searchField: "text",
      create: false,
      load: (query, callback) => {
        if (query.length < 2) return callback()
        fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`)
          .then(r => r.json())
          .then(callback)
          .catch(() => callback())
      },
      loadThrottle: 400,
      placeholder: this.element.dataset.placeholder,
    })
    setTimeout(() => this.select.focus(), 150)
  }

  disconnect() {
    if (this.select) this.select.destroy()
  }
}
