import { Controller } from "@hotwired/stimulus"

/**
 * Admin Table Controller
 * Handles table interactions: sorting, filtering, bulk actions, row selection
 * 
 * @extends Controller
 */
export default class extends Controller {
  static targets = ["row", "checkbox", "selectAll", "bulkActions", "searchInput", "sortLink"]
  static values = {
    selectedCount: { type: Number, default: 0 }
  }

  connect() {
    this.selectedIds = new Set()
  }

  /**
   * Toggle select all checkboxes
   * @param {Event} event
   */
  toggleAll(event) {
    const checked = event.target.checked
    
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = checked
      const id = checkbox.value
      
      if (checked) {
        this.selectedIds.add(id)
      } else {
        this.selectedIds.delete(id)
      }
    })
    
    this.updateBulkActions()
  }

  /**
   * Toggle individual row selection
   * @param {Event} event
   */
  toggleRow(event) {
    const checkbox = event.target
    const id = checkbox.value
    
    if (checkbox.checked) {
      this.selectedIds.add(id)
    } else {
      this.selectedIds.delete(id)
    }
    
    // Update "select all" checkbox
    if (this.hasSelectAllTarget) {
      const allChecked = this.checkboxTargets.every(cb => cb.checked)
      const someChecked = this.checkboxTargets.some(cb => cb.checked)
      
      this.selectAllTarget.checked = allChecked
      this.selectAllTarget.indeterminate = someChecked && !allChecked
    }
    
    this.updateBulkActions()
  }

  /**
   * Update bulk actions bar visibility and count
   */
  updateBulkActions() {
    this.selectedCountValue = this.selectedIds.size
    
    if (this.hasBulkActionsTarget) {
      if (this.selectedCountValue > 0) {
        this.bulkActionsTarget.classList.remove('hidden')
        const countEl = this.bulkActionsTarget.querySelector('[data-count]')
        if (countEl) {
          countEl.textContent = this.selectedCountValue
        }
      } else {
        this.bulkActionsTarget.classList.add('hidden')
      }
    }
  }

  /**
   * Perform bulk action
   * @param {Event} event
   */
  async bulkAction(event) {
    const action = event.params.action
    const url = event.params.url
    
    if (this.selectedIds.size === 0) return
    
    const confirmed = action.includes('delete') 
      ? confirm(`Are you sure you want to ${action} ${this.selectedIds.size} items?`)
      : true
    
    if (!confirmed) return
    
    try {
      const response = await fetch(url, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.csrfToken
        },
        body: JSON.stringify({
          ids: Array.from(this.selectedIds),
          action: action
        })
      })
      
      if (response.ok) {
        window.location.reload()
      } else {
        alert('Action failed. Please try again.')
      }
    } catch (error) {
      console.error('Bulk action error:', error)
      alert('An error occurred. Please try again.')
    }
  }

  /**
   * Clear all selections
   */
  clearSelection() {
    this.selectedIds.clear()
    this.checkboxTargets.forEach(cb => cb.checked = false)
    if (this.hasSelectAllTarget) {
      this.selectAllTarget.checked = false
      this.selectAllTarget.indeterminate = false
    }
    this.updateBulkActions()
  }

  /**
   * Search/filter table
   * @param {Event} event
   */
  search(event) {
    clearTimeout(this.searchTimeout)
    
    this.searchTimeout = setTimeout(() => {
      const query = event.target.value.toLowerCase()
      
      this.rowTargets.forEach(row => {
        const text = row.textContent.toLowerCase()
        row.style.display = text.includes(query) ? '' : 'none'
      })
    }, 300)
  }

  /**
   * Get CSRF token
   * @returns {string}
   */
  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ''
  }
}
