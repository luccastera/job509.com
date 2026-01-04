import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]

  open(event) {
    const modalId = event.currentTarget.dataset.modalTarget
    const modal = document.getElementById(modalId)
    if (modal) {
      modal.classList.remove("hidden")
      modal.classList.add("flex")
      document.body.classList.add("overflow-hidden")
    }
  }

  close() {
    const modal = this.element.closest("[data-modal]")
    if (modal) {
      modal.classList.add("hidden")
      modal.classList.remove("flex")
      document.body.classList.remove("overflow-hidden")
    }
  }

  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  closeOnClickOutside(event) {
    if (event.target === this.element) {
      this.close()
    }
  }
}
