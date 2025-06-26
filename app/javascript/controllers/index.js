// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)
eagerLoadControllersFrom("components", application)

if (sessionStorage.getItem('lookbook') != 'true') {
  if (localStorage.theme === 'dark' || (!('theme' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches) && localStorage.lookbook != 'true') {
    document.documentElement.classList.add('dark')
  } else {
    document.documentElement.classList.remove('dark')
  }
}

Turbo.StreamActions.redirect = function () {
  Turbo.visit(this.target);
};
