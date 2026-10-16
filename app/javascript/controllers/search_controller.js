import { Controller } from "@hotwired/stimulus"

// Team search in the header: results load into a Turbo Frame as the reader types.
export default class extends Controller {
  static targets = [ "input", "results" ]

  submit() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.element.requestSubmit(), 200)
  }

  clear() {
    this.inputTarget.value = ""
    this.close()
  }

  closeOutside({ target }) {
    if (!this.element.contains(target)) this.close()
  }

  close() {
    this.resultsTarget.innerHTML = ""
  }
}
