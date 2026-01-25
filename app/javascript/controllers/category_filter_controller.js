import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="category-filter"
export default class extends Controller {
  static targets = ["parentSelect", "subCategorySelect", "subCategoryContainer"]

  connect() {
    console.log("Category filter controller connected")
    this.updateSubCategoryState()
  }

  loadSubCategories(event) {
    const parentId = this.parentSelectTarget.value
    
    if (!parentId) {
      // No parent selected - clear and disable sub-category
      this.subCategorySelectTarget.innerHTML = '<option value="">All Sub-Categories</option>'
      this.subCategorySelectTarget.disabled = true
      return
    }

    // Fetch sub-categories for the selected parent
    fetch(`/categories/${parentId}/children.json`)
      .then(response => response.json())
      .then(data => {
        // Clear existing options
        this.subCategorySelectTarget.innerHTML = '<option value="">All Sub-Categories</option>'
        
        // Add new options
        data.forEach(category => {
          const option = document.createElement('option')
          option.value = category.id
          option.textContent = category.name
          this.subCategorySelectTarget.appendChild(option)
        })
        
        // Enable sub-category dropdown
        this.subCategorySelectTarget.disabled = false
      })
      .catch(error => {
        console.error('Error loading sub-categories:', error)
        this.subCategorySelectTarget.disabled = true
      })
  }

  updateSubCategoryState() {
    // On page load, ensure sub-category state matches parent selection
    const parentId = this.parentSelectTarget.value
    if (!parentId) {
      this.subCategorySelectTarget.disabled = true
    }
  }
}
