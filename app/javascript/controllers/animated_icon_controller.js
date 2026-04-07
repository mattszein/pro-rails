import { Controller } from "@hotwired/stimulus"

import * as lock from "icons/lock"
import * as connect from "icons/connect"
import * as charts from "icons/charts"
import * as sliders from "icons/sliders"
import * as contrast from "icons/contrast"
import * as shield from "icons/shield"
import * as layers from "icons/layers"
import * as chat from "icons/chat"

const REGISTRY = { lock, connect, charts, sliders, contrast, shield, layers, chat }

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
