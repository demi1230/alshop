import { Controller } from "@hotwired/stimulus"

// ProductFilterController - Handles category dropdown and search debouncing
// Keeps it simple: Just auto-submit on category change and debounce search
export default class extends Controller {
  static targets = ["categorySelect", "searchInput"]
  static values = { debounceDelay: { type: Number, default: 500 } }

  connect() {
    this.timeout = null
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  // Auto-submit when category changes
  submitForm(event) {
    // Clear any pending search timeout
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    
    // Submit immediately for category change
    this.element.requestSubmit()
  }

  // Debounce search input
  debounceSearch(event) {
    // Clear existing timeout
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    // Set new timeout
    this.timeout = setTimeout(() => {
      this.element.requestSubmit()
    }, this.debounceDelayValue)
  }

  // Manual submit (for button click)
  submit(event) {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    // Form will submit naturally
  }
}
