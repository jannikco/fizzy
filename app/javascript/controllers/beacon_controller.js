import { post } from "@rails/request.js"
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  visibilityChanged() {
    this.#sendBeacon()
  }

  disconnect() {
    this.#sendBeacon()
  }

  #sendBeacon() {
    if (!document.hidden) {
      post(this.urlValue, { responseKind: "turbo-stream" })
    }
  }
}
