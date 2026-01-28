import { Controller } from "@hotwired/stimulus"

/**
 * Admin Modal Controller
 * Handles modal open/close, animations, and remote content loading
 * 
 * @extends Controller
 */
export default class extends Controller {
  static targets = ["dialog", "content", "backdrop"]
  static values = {
    open: { type: Boolean, default: false },
    url: String
  }

  connect() {
    // Close on Escape key
    this.escapeHandler = this.close.bind(this)
    document.addEventListener('keydown', this.handleEscape.bind(this))
  }

  disconnect() {
    document.removeEventListener('keydown', this.handleEscape.bind(this))
  }

  /**
   * Open modal
   * @param {Event} event
   */
  async open(event) {
    event?.preventDefault()
    
    // Load remote content if URL provided
    if (this.hasUrlValue && this.urlValue) {
      await this.loadRemoteContent()
    }
    
    this.openValue = true
  }

  /**
   * Close modal
   * @param {Event} event
   */
  close(event) {
    event?.preventDefault()
    this.openValue = false
  }

  /**
   * Close modal when clicking backdrop
   * @param {Event} event
   */
  closeOnBackdrop(event) {
    if (event.target === this.backdropTarget || event.target === this.dialogTarget) {
      this.close()
    }
  }

  /**
   * Handle Escape key
   * @param {KeyboardEvent} event
   */
  handleEscape(event) {
    if (event.key === 'Escape' && this.openValue) {
      this.close()
    }
  }

  /**
   * Load content from remote URL
   */
  async loadRemoteContent() {
    try {
      const response = await fetch(this.urlValue, {
        headers: {
          'Accept': 'text/html'
        }
      })
      
      if (response.ok) {
        const html = await response.text()
        this.contentTarget.innerHTML = html
      }
    } catch (error) {
      console.error('Failed to load modal content:', error)
      this.contentTarget.innerHTML = '<p class="text-red-500">Failed to load content</p>'
    }
  }

  /**
   * Update UI when open state changes
   */
  openValueChanged() {
    if (this.openValue) {
      // Show modal
      this.element.classList.remove('hidden')
      // Trigger animation
      requestAnimationFrame(() => {
        this.element.classList.add('active')
        document.body.style.overflow = 'hidden'
      })
    } else {
      // Hide modal
      this.element.classList.remove('active')
      document.body.style.overflow = ''
      
      // Wait for animation to complete
      setTimeout(() => {
        this.element.classList.add('hidden')
      }, 300)
    }
  }
}
