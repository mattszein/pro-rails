import { Controller } from "@hotwired/stimulus"

// Reveals a condition's value fields when its toggle is on, hides and
// disables them when off. No validation logic here — the model validates
// on save (TECH-PLAN §3.5).
export default class extends Controller {
  static targets = ["toggle", "field"]

  connect() {
    this.sync()
  }

  sync() {
    const on = this.toggleTarget.checked
    this.fieldTargets.forEach(field => {
      field.hidden = !on
      field.querySelectorAll("input, select, textarea").forEach(control => {
        control.disabled = !on
        // TomSelect builds its own control over the <select> and caches the
        // disabled state it saw at construction — flipping the underlying
        // element's `disabled` property never reaches the widget. Every
        // condition row starts hidden (and so disabled) on the new-audience
        // form, so without this a TomSelect field would render locked forever.
        if (control.tomselect) {
          on ? control.tomselect.enable() : control.tomselect.disable()
        }
      })
    })
  }
}
