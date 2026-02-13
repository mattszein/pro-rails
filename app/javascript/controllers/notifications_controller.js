import { Controller } from "@hotwired/stimulus"
import cable from "cable"

export default class extends Controller {
  connect() {
    if (this.channel) return // already subscribed

    this.channel = cable.subscribeTo("Noticed::NotificationChannel")
    this.channel.on("message", (data) => this.dispatch("received", { detail: data }))
    this.channel.on("connect", () => console.log("Subscribed to Notifications"))
  }
}
