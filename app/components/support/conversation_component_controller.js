import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages"]

  connect() {
    this.refresh()
    this.setupObserver()
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  setupObserver() {
    if (!this.hasMessagesTarget) return

    this.observer = new MutationObserver(() => {
      this.refresh()
    })

    this.observer.observe(this.messagesTarget, {
      childList: true
    })
  }

  refresh() {
    this.hideStaleResolutionActions()
    this.scrollToBottom()
  }

  // Only the prompt on the latest message stays actionable: broadcasts append new messages
  // without re-rendering older ones, so hide every resolution-actions block whose message is
  // not the last one in the list (the typing indicator is not a message).
  hideStaleResolutionActions() {
    if (!this.hasMessagesTarget) return

    const messages = this.messagesTarget.querySelectorAll("[id^='support_message_']")
    const latest = messages[messages.length - 1]
    this.messagesTarget.querySelectorAll("[data-resolution-actions]").forEach((block) => {
      block.hidden = block.closest("[id^='support_message_']") !== latest
    })
  }

  scrollToBottom() {
    if (this.hasMessagesTarget) {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    }
  }
}
