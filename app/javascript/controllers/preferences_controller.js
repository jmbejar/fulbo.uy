import { Controller } from "@hotwired/stimulus"

// Text size and dark mode, remembered per browser. The layout's inline
// script applies the saved values before the first paint.
export default class extends Controller {
  static targets = [ "size", "dark" ]

  connect() {
    this.render()
  }

  setSize({ currentTarget }) {
    this.save("size", currentTarget.dataset.size)
  }

  toggleDark() {
    this.save("theme", this.root.dataset.theme === "dark" ? "light" : "dark")
  }

  save(key, value) {
    this.root.dataset[key] = value
    try { localStorage.setItem(key, value) } catch (e) {}
    this.render()
  }

  render() {
    this.sizeTargets.forEach((button) => {
      button.setAttribute("aria-pressed", button.dataset.size === this.root.dataset.size)
    })
    this.darkTarget.setAttribute("aria-pressed", this.root.dataset.theme === "dark")
  }

  get root() {
    return document.documentElement
  }
}
