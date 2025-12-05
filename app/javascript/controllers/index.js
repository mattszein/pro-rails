// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import "@hotwired/turbo";
eagerLoadControllersFrom("controllers", application)
eagerLoadControllersFrom("components", application)

if (sessionStorage.getItem('lookbook') != 'true') {
  if (localStorage.getItem('theme_mode') === 'dark' || (!('theme_mode' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches) && localStorage.lookbook != 'true') {
    document.documentElement.classList.add('dark')
  } else {
    document.documentElement.classList.remove('dark')
  }

  const savedTheme = localStorage.getItem('theme_color')
  if (savedTheme) {
    document.documentElement.classList.add(`theme-${savedTheme}`)
  }
}

Turbo.StreamActions.redirect = function () {
  Turbo.visit(this.target);
};
