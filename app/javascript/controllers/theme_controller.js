import { Controller } from "@hotwired/stimulus"

// Toggles a `data-theme` attribute on <html> and persists preference to localStorage
export default class extends Controller {
  connect() {
    this.theme = this.currentTheme()
    this.applyTheme(this.theme)
  }

  toggle() {
    const next = this.currentTheme() === 'dark' ? 'light' : 'dark'
    this.applyTheme(next)
    localStorage.setItem('fitbuddy_theme', next)
  }

  currentTheme() {
    return localStorage.getItem('fitbuddy_theme') || (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light')
  }

  applyTheme(theme) {
    const root = document.documentElement
    root.setAttribute('data-theme', theme)
    this.theme = theme
  }
}
