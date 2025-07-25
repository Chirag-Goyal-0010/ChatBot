import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="showmore"
export default class extends Controller {
  static targets = ["content"]
  static values = { full: String, truncated: String, expanded: Boolean }

  connect() {
    if (!this.hasFullValue) {
      this.fullValue = this.contentTarget.textContent.trim();
    }
    if (!this.hasTruncatedValue) {
      // Default: 100 chars for URL, 200 for chunk (detected by parent class)
      const isUrl = this.element.classList.contains("url-cell");
      const limit = isUrl ? 100 : 200;
      this.truncatedValue = this.fullValue.length > limit ? this.fullValue.slice(0, limit) + "..." : this.fullValue;
    }
    this.expandedValue = false;
    this.update();
  }

  toggle(event) {
    event.preventDefault();
    this.expandedValue = !this.expandedValue;
    this.update();
  }

  update() {
    if (this.expandedValue) {
      this.contentTarget.textContent = this.fullValue;
      this.toggleButtonText("Show less");
    } else {
      this.contentTarget.textContent = this.truncatedValue;
      this.toggleButtonText("Show more");
    }
  }

  toggleButtonText(text) {
    const btn = this.element.querySelector("button[data-action]");
    if (btn) btn.textContent = text;
  }
} 