import { Controller } from "@hotwired/stimulus"

/**
 * Admin Form Controller
 * Handles form validation, dynamic fields, autosave, and submission
 * 
 * @extends Controller
 */
export default class extends Controller {
  static targets = ["submit", "cancel", "dynamicField", "preview"]
  static values = {
    autosave: { type: Boolean, default: false },
    autosaveUrl: String,
    autosaveDelay: { type: Number, default: 2000 }
  }

  connect() {
    if (this.autosaveValue) {
      this.setupAutosave()
    }
    
    this.setupUnsavedChanges()
  }

  disconnect() {
    if (this.autosaveTimeout) {
      clearTimeout(this.autosaveTimeout)
    }
  }

  /**
   * Setup autosave functionality
   */
  setupAutosave() {
    this.element.addEventListener('input', (event) => {
      this.markUnsaved()
      this.scheduleAutosave()
    })
  }

  /**
   * Schedule autosave after delay
   */
  scheduleAutosave() {
    clearTimeout(this.autosaveTimeout)
    
    this.autosaveTimeout = setTimeout(() => {
      this.autosave()
    }, this.autosaveDelayValue)
  }

  /**
   * Perform autosave
   */
  async autosave() {
    if (!this.autosaveUrlValue) return
    
    const formData = new FormData(this.element)
    
    try {
      const response = await fetch(this.autosaveUrlValue, {
        method: 'PATCH',
        headers: {
          'X-CSRF-Token': this.csrfToken
        },
        body: formData
      })
      
      if (response.ok) {
        this.showAutosaveSuccess()
        this.markSaved()
      }
    } catch (error) {
      console.error('Autosave failed:', error)
    }
  }

  /**
   * Setup unsaved changes warning
   */
  setupUnsavedChanges() {
    this.hasUnsavedChanges = false
    
    this.element.addEventListener('input', () => {
      this.markUnsaved()
    })
    
    this.element.addEventListener('submit', () => {
      this.markSaved()
    })
    
    window.addEventListener('beforeunload', (event) => {
      if (this.hasUnsavedChanges) {
        event.preventDefault()
        event.returnValue = ''
      }
    })
  }

  /**
   * Mark form as having unsaved changes
   */
  markUnsaved() {
    this.hasUnsavedChanges = true
  }

  /**
   * Mark form as saved
   */
  markSaved() {
    this.hasUnsavedChanges = false
  }

  /**
   * Add dynamic field (for repeatable sections)
   * @param {Event} event
   */
  addField(event) {
    event.preventDefault()
    
    const template = event.target.dataset.template
    const container = event.target.dataset.container
    const containerEl = document.getElementById(container)
    
    if (!containerEl || !template) return
    
    const timestamp = new Date().getTime()
    const newField = template.replace(/NEW_RECORD/g, timestamp)
    
    containerEl.insertAdjacentHTML('beforeend', newField)
  }

  /**
   * Remove dynamic field
   * @param {Event} event
   */
  removeField(event) {
    event.preventDefault()
    
    const field = event.target.closest('[data-dynamic-field]')
    if (!field) return
    
    // If field has an ID, mark for deletion
    const idInput = field.querySelector('input[name*="[id]"]')
    if (idInput && idInput.value) {
      const destroyInput = document.createElement('input')
      destroyInput.type = 'hidden'
      destroyInput.name = idInput.name.replace('[id]', '[_destroy]')
      destroyInput.value = '1'
      field.appendChild(destroyInput)
      field.style.display = 'none'
    } else {
      field.remove()
    }
  }

  /**
   * Preview file upload
   * @param {Event} event
   */
  previewFile(event) {
    const file = event.target.files[0]
    if (!file) return
    
    const previewTarget = event.target.dataset.preview
    const previewEl = document.getElementById(previewTarget)
    if (!previewEl) return
    
    if (file.type.startsWith('image/')) {
      const reader = new FileReader()
      reader.onload = (e) => {
        previewEl.innerHTML = `<img src="${e.target.result}" class="max-w-full h-auto rounded-lg" />`
      }
      reader.readAsDataURL(file)
    }
  }

  /**
   * Show autosave success indicator
   */
  showAutosaveSuccess() {
    const indicator = document.createElement('div')
    indicator.className = 'fixed top-4 right-4 bg-green-500 text-white px-4 py-2 rounded-lg shadow-lg'
    indicator.textContent = 'Saved'
    document.body.appendChild(indicator)
    
    setTimeout(() => {
      indicator.remove()
    }, 2000)
  }

  /**
   * Confirm form cancellation
   * @param {Event} event
   */
  confirmCancel(event) {
    if (this.hasUnsavedChanges) {
      if (!confirm('You have unsaved changes. Are you sure you want to leave?')) {
        event.preventDefault()
      }
    }
  }

  /**
   * Get CSRF token
   * @returns {string}
   */
  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ''
  }
}
