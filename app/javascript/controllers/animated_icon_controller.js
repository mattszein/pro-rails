import { Controller } from "@hotwired/stimulus"

import * as lock from "icons/lock"
import * as connect from "icons/connect"
import * as charts from "icons/charts"
import * as sliders from "icons/sliders"
import * as grip from "icons/grip"
import * as shield from "icons/shield"
import * as layers from "icons/layers"
import * as chat from "icons/chat"
import * as home from "icons/home"
import * as logout from "icons/logout"
import * as sunmoon from "icons/sunmoon"
import * as support from "icons/support"
import * as accounts from "icons/accounts"
import * as bookText from "icons/book-text"
import * as gavel from "icons/gavel"
import * as idCard from "icons/id-card"
import * as back from "icons/back"

const REGISTRY = {
  lock,
  connect,
  charts,
  sliders,
  grip,
  shield,
  layers,
  chat,
  home,
  logout,
  sunmoon,
  support,
  accounts,
  "book-text": bookText,
  gavel,
  "id-card": idCard,
  back
}

export default class extends Controller {
  static values = { type: String }

  connect() {
    this.animation = REGISTRY[this.typeValue]
    this.svg = this.element.querySelector("svg")
  }

  start() {
    if (this.animation && this.svg) this.animation.start(this.svg)
  }

  stop() {
    if (this.animation && this.svg) this.animation.stop(this.svg)
  }
}
