import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

// Mounted directly on the <select> (same as role-account-search), so TomSelect
// initializes reliably. The selected account's summary is rendered by cloning a
// server-rendered <template> sibling (see Adminit::Accounts::SummaryComponent)
// and filling its [data-account-field] / [data-account-status] slots.
export default class extends Controller {
  static values = { searchUrl: String };

  connect() {
    console.log('is connected the search');

    this._accounts = {};
    // Capture sibling elements before TomSelect rewraps the select's DOM.
    const root = this.element.parentElement;
    this.infoEl = root.querySelector("[data-account-lookup-info]");
    this.templateEl = root.querySelector("[data-account-lookup-template]");

    this._beforeCache = () => this.select?.destroy();
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
          .then(data => {
            data.forEach(a => { this._accounts[a.value] = a })
            callback(data)
          })
          .catch(() => callback())
      },
      onChange: (value) => {
        const account = value && this._accounts[value]
        account ? this.renderInfo(account) : this.clearInfo()
      },
      onClear: () => this.clearInfo()
    });
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this._beforeCache);
    this.select?.destroy();
  }

  renderInfo(account) {
    if (!this.infoEl || !this.templateEl) return;
    const fragment = this.templateEl.content.cloneNode(true);
    fragment.querySelectorAll("[data-account-field]").forEach((el) => {
      el.textContent = account[el.dataset.accountField] ?? "-";
    })
    fragment.querySelectorAll("[data-account-status]").forEach((el) => {
      el.hidden = el.dataset.accountStatus !== account.status_key;
    })
    const link = fragment.querySelector("[data-account-lookup-link]");
    if (link) link.href = account.account_path;
    this.infoEl.replaceChildren(fragment);
    this.infoEl.hidden = false;
  }

  clearInfo() {
    if (!this.infoEl) return;
    this.infoEl.replaceChildren();
    this.infoEl.hidden = true;
  }
}
