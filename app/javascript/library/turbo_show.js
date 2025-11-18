class TurboShow extends HTMLElement {
  static #operators = {
    is: (content, value) => content === value,
    is_not: (content, value) => content !== value,
    in: (content, value) => {
      const values = value.split(',').map(v => v.trim())
      return values.includes(content)
    },
    not_in: (content, value) => {
      const values = value.split(',').map(v => v.trim())
      return !values.includes(content)
    },
    includes: (content, value) => content.includes(value),
    excludes: (content, value) => !content.includes(value),
    greater_than: (content, value) => parseInt(content) > parseInt(value),
    less_than: (content, value) => parseInt(content) < parseInt(value)
  }

  connectedCallback() {
    if (this.#removable()) this.remove()
  }

  #removable() {
    if (this.#whenAttributeMissing()) return true
    if (this.#contentMissing()) return true
    if (this.#unmetConditions()) return true

    return false
  }

  #whenAttributeMissing() {
    return !this.hasAttribute("when")
  }

  #contentMissing() {
    return !this.#content
  }

  #unmetConditions() {
    const operators = Object.keys(TurboShow.#operators)
      .filter(operator => this.hasAttribute(operator))

    if (operators.length === 0) return false

    return operators.some(operator => {
      const value = this.getAttribute(operator)
      const check = TurboShow.#operators[operator]

      return !check(this.#content, value)
    })
  }

  // Check body data attributes first, then fall back to meta tags
  get #content() {
    const whenAttr = this.getAttribute("when")

    // Convert "current-user-id" to "currentUserId" for dataset
    const datasetKey = whenAttr.replace(/-([a-z])/g, (g) => g[1].toUpperCase())

    // First try body data attributes
    if (document.body.dataset[datasetKey] !== undefined) {
      return document.body.dataset[datasetKey]
    }

    // Fall back to meta tags
    const metaTag = document.querySelector(`meta[name="${whenAttr}"]`)
    return metaTag?.getAttribute("content") || ""
  }
}

customElements.define("turbo-show", TurboShow)
