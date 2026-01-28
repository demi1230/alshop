import { Controller } from "@hotwired/stimulus"

/**
 * Admin Toggle Controller
 * Handles toggle switches for boolean fields with AJAX updates
 * 
 * @extends Controller
 */
export default class extends Controller {
  static values = {
    url: String,
    field: String,
    enabled: { type: Boolean, default: false }
  }

  connect() {
    this.element.checked = this.enabledValue
  }

  /**
   * Toggle state and send AJAX request
   * @param {Event} event
   */
  async toggle(event) {
    const previousState = this.enabledValue
    this.enabledValue = event.target.checked
    
    if (!this.hasUrlValue) return
    
    try {
      const response = await fetch(this.urlValue, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.csrfToken
        },
        body: JSON.stringify({
          [this.fieldValue]: this.enabledValue
        })
      })
      
      if (!response.ok) {
        // Revert on failure
        this.enabledValue = previousState
        this.element.checked = previousState
        this.showError()
      } else {
        this.showSuccess()
      }
    } catch (error) {
      console.error('Toggle failed:', error)
      this.enabledValue = previousState
      this.element.checked = previousState
      this.showError()
    }
  }

  /**
   * Show success notification
   */
  showSuccess() {
    this.showNotification('Updated successfully', 'success')
  }

  /**
   * Show error notification
   */
  showError() {
    this.showNotification('Update failed', 'error')
  }

  /**
   * Show notification
   * @param {string} message
   * @param {string} type
   */
  showNotification(message, type) {
    const notification = document.createElement('div')
    notification.className = `fixed top-4 right-4 px-4 py-2 rounded-lg shadow-lg ${
      type === 'success' ? 'bg-green-500' : 'bg-red-500'
    } text-white`
    notification.textContent = message
    document.body.appendChild(notification)
    
    setTimeout(() => {
      notification.remove()
    }, 3000)
  }

  /**
   * Get CSRF token
   * @returns {string}
   */
  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ''
  }
}
