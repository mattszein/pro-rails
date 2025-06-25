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

    const handleChange = () => {
      let el = this.element;
      !(this.allowEmptyValue) && el.setCustomValidity('');
      if (this.submitValue && el.form.reportValidity()) {
        el.form.submit();
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
    }
  }
}
