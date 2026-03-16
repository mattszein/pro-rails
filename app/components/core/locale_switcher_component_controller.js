import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  change(event) {
    const locale = event.target.value
    const currentPath = window.location.pathname

    // Remove existing locale prefix
    const pathWithoutLocale = currentPath.replace(/^\/(en|es)(\/|$)/, "/") || "/"

    // Add new locale prefix (omit for English/default)
    const newPath = locale === "en" ? pathWithoutLocale : `/${locale}${pathWithoutLocale}`

    // Preserve query string and hash
    window.location.href = newPath + window.location.search + window.location.hash
  }
}
