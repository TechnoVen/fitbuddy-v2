import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "toggle" ]

  connect() {
    // Find any original/proposed pairs and highlight differences
    const originals = this.element.querySelectorAll('[data-diff-original]')
    const proposeds = this.element.querySelectorAll('[data-diff-proposed]')

    originals.forEach((origEl, idx) => {
      const propEl = proposeds[idx]
      if (!propEl) return

      const origText = origEl.innerText.trim()
      const propText = propEl.innerText.trim()

      if (origText !== propText) {
        origEl.classList.add('border-danger')
        propEl.classList.add('border-success')
      }
    })
  }
}
