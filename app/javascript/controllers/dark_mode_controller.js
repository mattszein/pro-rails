import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["themeToggle"]

  // Uncomment this function to enable icon change
  // connect() {
  //   if (localStorage.getItem('theme') === 'dark' || (!('theme' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
  //     this.lightIconTarget.classList.remove('hidden');
  //   } else {
  //     this.darkIconTarget.classList.remove('hidden');
  //   }
  // }

  toggleTheme(event) {
    event.preventDefault()
    // this.lightIconTarget.classList.toggle('hidden');
    // this.darkIconTarget.classList.toggle('hidden');
    if (localStorage.getItem('theme_mode')) {
      if (localStorage.getItem('theme_mode') === 'light') {
        document.documentElement.classList.add('dark');
        localStorage.setItem('theme_mode', 'dark');
      } else {
        document.documentElement.classList.remove('dark');
        localStorage.setItem('theme_mode', 'light');
      }

      // if NOT set via local storage previously
    } else {
      if (document.documentElement.classList.contains('dark')) {
        document.documentElement.classList.remove('dark');
        localStorage.setItem('theme_mode', 'light');
      } else {
        document.documentElement.classList.add('dark');
        localStorage.setItem('theme_mode', 'dark');
      }
    }
  }
}
