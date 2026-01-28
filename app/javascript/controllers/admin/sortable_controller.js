import { Controller } from "@hotwired/stimulus"

/**
 * Admin Sortable Controller
 * Handles drag-and-drop sorting with AJAX persistence
 * Lightweight implementation without external dependencies
 * 
 * @extends Controller
 */
export default class extends Controller {
  static targets = ["item"]
  static values = {
    url: String,
    handle: String
  }

  connect() {
    this.setupDragAndDrop()
  }

  /**
   * Setup drag and drop functionality
   */
  setupDragAndDrop() {
    this.itemTargets.forEach((item, index) => {
      item.draggable = true
      item.dataset.position = index
      
      item.addEventListener('dragstart', this.handleDragStart.bind(this))
      item.addEventListener('dragover', this.handleDragOver.bind(this))
      item.addEventListener('drop', this.handleDrop.bind(this))
      item.addEventListener('dragend', this.handleDragEnd.bind(this))
    })
  }

  /**
   * Handle drag start
   * @param {DragEvent} event
   */
  handleDragStart(event) {
    // Only allow drag from handle if specified
    if (this.hasHandleValue) {
      const handle = event.target.closest(this.handleValue)
      if (!handle) {
        event.preventDefault()
        return
      }
    }
    
    this.draggedItem = event.currentTarget
    this.draggedItem.classList.add('dragging')
    event.dataTransfer.effectAllowed = 'move'
    event.dataTransfer.setData('text/html', this.draggedItem.innerHTML)
  }

  /**
   * Handle drag over
   * @param {DragEvent} event
   */
  handleDragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = 'move'
    
    const afterElement = this.getDragAfterElement(event.clientY)
    const container = this.element
    
    if (afterElement == null) {
      container.appendChild(this.draggedItem)
    } else {
      container.insertBefore(this.draggedItem, afterElement)
    }
  }

  /**
   * Handle drop
   * @param {DragEvent} event
   */
  handleDrop(event) {
    event.stopPropagation()
    this.saveNewOrder()
  }

  /**
   * Handle drag end
   * @param {DragEvent} event
   */
  handleDragEnd(event) {
    this.draggedItem?.classList.remove('dragging')
    this.draggedItem = null
  }

  /**
   * Get element to insert dragged item after
   * @param {number} y
   * @returns {Element|null}
   */
  getDragAfterElement(y) {
    const draggableElements = [...this.itemTargets].filter(item => 
      item !== this.draggedItem
    )
    
    return draggableElements.reduce((closest, child) => {
      const box = child.getBoundingClientRect()
      const offset = y - box.top - box.height / 2
      
      if (offset < 0 && offset > closest.offset) {
        return { offset: offset, element: child }
      } else {
        return closest
      }
    }, { offset: Number.NEGATIVE_INFINITY }).element
  }

  /**
   * Save new order via AJAX
   */
  async saveNewOrder() {
    if (!this.hasUrlValue) return
    
    const order = this.itemTargets.map((item, index) => ({
      id: item.dataset.id,
      position: index
    }))
    
    try {
      const response = await fetch(this.urlValue, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.csrfToken
        },
        body: JSON.stringify({ order })
      })
      
      if (response.ok) {
        this.showSuccess()
      } else {
        this.showError()
      }
    } catch (error) {
      console.error('Failed to save order:', error)
      this.showError()
    }
  }

  /**
   * Show success notification
   */
  showSuccess() {
    this.showNotification('Order saved', 'success')
  }

  /**
   * Show error notification
   */
  showError() {
    this.showNotification('Failed to save order', 'error')
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
