import { Controller } from "@hotwired/stimulus"
import { enter, leave, toggle } from 'el-transition'
import Cookies from 'js-cookie'

export default class extends Controller {
  static targets = ["alert", "sidebar", "modal"]

  close() {
    let element = this.element
    leave(element).then(() => {
      element.remove();
    });
  }

  enter() {
    enter(this.element);
  }

  toggleIt() {
    toggle(this.element);
  }

  toggleSidebar() {
    toggle(this.sidebarTarget);
    let sidebar = Cookies.get(this.sidebarCookieName)
    Cookies.set(this.sidebarCookieName, (sidebar === '0' || sidebar === undefined) ? '1' : '0')
  }

  get sidebarCookieName() {
    return `sidebar`
  }

  getCookieValue(name) {
    return Cookies.get(name)
  }

}
