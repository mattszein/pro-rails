import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

// Mounted directly on the <select> (same as role-account-search), so TomSelect
// initializes reliably. Selecting an account points the "account_summary"
// turbo frame at the server-rendered summary endpoint; clearing empties it.
export default class extends Controller {
  static values = { searchUrl: String, summaryUrl: String };

  connect() {
    this._beforeCache = () => {
      this.select?.destroy();
      this.select = null;
    };
    document.addEventListener("turbo:before-cache", this._beforeCache);

    this.select = new TomSelect(this.element, {
      valueField:   "value",
      labelField:   "text",
      searchField:  "text",
      create:       false,
      loadThrottle: 300,
      placeholder:  this.element.dataset.placeholder,
      load: (query, callback) => {
        if (query.length < 2) return callback()
        fetch(`${this.searchUrlValue}?q=${encodeURIComponent(query)}`)
          .then(r => r.json())
          .then(data => callback(data))
          .catch(() => callback())
      },
      onChange: (value) => {
        value ? this.loadSummary(value) : this.clearSummary()
      },
      onClear: () => this.clearSummary()
    });
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this._beforeCache);
    this.select?.destroy();
    this.select = null;
  }

  loadSummary(value) {
    const frame = document.getElementById("account_summary");
    if (!frame) return;
    // Setting src makes the frame fetch the server-rendered summary.
    frame.src = this.summaryUrlValue.replace("__id__", value);
  }

  clearSummary() {
    const frame = document.getElementById("account_summary");
    if (!frame) return;
    frame.removeAttribute("src");
    frame.replaceChildren();
  }
}
