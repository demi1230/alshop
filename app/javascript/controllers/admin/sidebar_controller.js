import { Controller } from "@hotwired/stimulus"

/**
 * Admin Sidebar Controller
 * Handles sidebar collapse/expand, navigation state, and mobile responsiveness
 * 
 * @extends Controller
 */
export default class extends Controller {
  static targets = ["menu", "overlay", "submenu"]
  static values = {
    collapsed: { type: Boolean, default: false },
    mobile: { type: Boolean, default: false }
  }

  connect() {
    this.checkMobile()
    window.addEventListener('resize', this.checkMobile.bind(this))
    this.restoreState()
  }

  disconnect() {
    window.removeEventListener('resize', this.checkMobile.bind(this))
  }

  /**
   * Toggle sidebar collapsed state
   */
  toggle() {
    this.collapsedValue = !this.collapsedValue
  }

  /**
   * Open mobile sidebar
   */
  open() {
    this.mobileValue = true
  }

  /**
   * Close mobile sidebar
   */
  close() {
    this.mobileValue = false
  }

  /**
   * Close sidebar when clicking overlay
   * @param {Event} event
   */
  closeOnOverlay(event) {
    if (event.target === this.overlayTarget) {
      this.close()
    }
  }

  /**
   * Toggle submenu expansion
   * @param {Event} event
   */
  toggleSubmenu(event) {
    event.preventDefault()
    const submenu = event.currentTarget.nextElementSibling
    const isExpanded = submenu.classList.contains('expanded')
    
    // Close all other submenus
    this.submenuTargets.forEach(menu => {
      if (menu !== submenu) {
        menu.classList.remove('expanded')
        menu.style.maxHeight = null
      }
    })
    
    // Toggle current submenu
    if (isExpanded) {
      submenu.classList.remove('expanded')
      submenu.style.maxHeight = null
    } else {
      submenu.classList.add('expanded')
      submenu.style.maxHeight = submenu.scrollHeight + 'px'
    }
  }

  /**
   * Check if viewport is mobile
   */
  checkMobile() {
    const wasMobile = this.mobileValue
    this.mobileValue = window.innerWidth < 1024
    
    // Auto-close sidebar on mobile
    if (this.mobileValue && !wasMobile) {
      this.collapsedValue = false
    }
  }

  /**
   * Restore sidebar state from localStorage
   */
  restoreState() {
    const saved = localStorage.getItem('admin_sidebar_collapsed')
    if (saved !== null) {
      this.collapsedValue = saved === 'true'
    }
  }

  /**
   * Update UI when collapsed state changes
   */
  collapsedValueChanged() {
    localStorage.setItem('admin_sidebar_collapsed', this.collapsedValue)
    
    if (this.collapsedValue) {
      this.element.classList.add('collapsed')
    } else {
      this.element.classList.remove('collapsed')
    }
  }

  /**
   * Update UI when mobile state changes
   */
  mobileValueChanged() {
    if (this.mobileValue) {
      this.element.classList.add('mobile-open')
      this.overlayTarget?.classList.add('active')
    } else {
      this.element.classList.remove('mobile-open')
      this.overlayTarget?.classList.remove('active')
    }
  }
}
