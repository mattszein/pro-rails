import { Controller } from '@hotwired/stimulus';
import { FetchRequest } from "@rails/request.js"

export default class extends Controller {
  markAsRead(event) {
    const item = event.currentTarget
    const notificationId = item.dataset.notificationId
    if (!notificationId) return
    new FetchRequest("post", `/notifications/${notificationId}/mark_as_read`).perform()

    item.classList.remove("unread")
    this.dispatch('read', {
      detail: { notificationId: this.element.dataset.notificationId },
      bubbles: true  // importante para que suba en el DOM
    })
    item.remove()
  }
}
