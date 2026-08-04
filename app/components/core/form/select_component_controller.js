import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select";

export default class extends Controller { 
  static values = {submit: {type: Boolean, default: false}, allowEmpty: {type: Boolean, default: true}}

  // Triggered when the Stimulus controller is connected to the DOM.
  connect() {
    this.initializeTomSelect();
    this.dispatchLoaded();
  }

  dispatchLoaded() {
    setTimeout(() =>{
      this.dispatch("loaded", {});
    },0.2);
  }

  // Triggered when the Stimulus controller is removed from the DOM.
  disconnect() {
    this.destroyTomSelect();
  }

  // Initialize the TomSelect dropdown with the desired configurations.
  initializeTomSelect() {
    // Return early if no element is associated with the controller.
    if (!this.element) return;

    this.removeExistingTomSelect();

    const handleChange = () => {
      let el = this.element;
      !(this.allowEmptyValue) && el.setCustomValidity('');
      if (this.submitValue && el.form.reportValidity()) {
        // requestSubmit (not submit) so the submit event fires and Turbo intercepts it.
        el.form.requestSubmit();
      }
    }

    const onDelete = (values, event) => {
      if (!this.allowEmptyValue) {
      let el = this.element;
      let selected = Array.from(el.options).filter(function (option) {
        return option.selected;
      });
      let length = selected.length;
      if (length === 1) {
          el.setCustomValidity('This field must have at least one option. You cannot delete it.')
        el.reportValidity();
      }
      return selected.length > 1
      } else {
        return true
      }
    }

    // Create a new TomSelect instance with the specified configuration.
    // see: https://tom-select.js.org/docs/
    // value, label, search, placeholder, etc can all be passed as static values instead of hard-coded.
    this.select = new TomSelect(this.element, {
      plugins: ['remove_button'],
      selectOnTab: true,
      create: false,
      highlight: true,
      allowEmptyOption: false,
      onChange: handleChange,
      onDelete: onDelete,
      loadingClass: 'blur-2xl'
    });
  }

  // Cleanup: Destroy the TomSelect instance when the controller is disconnected.
  destroyTomSelect() {
    if (this.select) {
      this.select.destroy();
      this.select = null;
    }
  }

  // TomSelect is not idempotent: constructing it over already-transformed
  // markup appends a second .ts-wrapper instead of reusing the first. connect()
  // can land on already-transformed markup two different ways, and both have to
  // be handled or the widget stacks one copy per visit:
  //
  //   1. A live instance is still attached — Stimulus reconnected without
  //      disconnect() having run, e.g. because Turbo moved this
  //      data-turbo-permanent wrapper (Core::LoaderComponent, see
  //      _permission_row.html.erb) into a freshly rendered body. Here
  //      element.tomselect is set, so hand it to TomSelect's own destroy().
  //
  //   2. The markup came from a Turbo page-cache snapshot. Turbo builds those
  //      with cloneNode(true) (PageSnapshot#clone), and JS properties do not
  //      survive cloning — so .ts-wrapper is present as inert markup while
  //      element.tomselect is undefined. Nothing owns it; strip it by hand and
  //      undo the classes/attributes TomSelect set on the <select>. Turbo
  //      renders a cached preview on every revisit to an already-visited page,
  //      so this is the common path, not an edge case.
  removeExistingTomSelect() {
    if (this.element.tomselect) {
      this.element.tomselect.destroy();
      return;
    }

    if (!this.element.classList.contains("tomselected")) return;

    this.element.parentElement
      ?.querySelectorAll(":scope > .ts-wrapper")
      .forEach((wrapper) => wrapper.remove());
    this.element.classList.remove("tomselected", "ts-hidden-accessible");
    this.element.removeAttribute("tabindex");
  }
}
