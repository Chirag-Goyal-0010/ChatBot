import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "submit", "loading", "response"]

  connect() {
    console.log("Chat form controller connected")
    console.log("Form element:", this.element)
    console.log("Input target:", this.inputTarget)
    console.log("Submit target:", this.submitTarget)
    
    // Bind listeners once and keep references for proper cleanup
    this._onSubmitEnd = this.responseReceived.bind(this)
    this._onSubmitError = this.handleError.bind(this)
    this._onSubmitStart = this.submitStart.bind(this)

    // Add event listeners for Turbo lifecycle
    this.element.addEventListener('turbo:submit-end', this._onSubmitEnd)
    this.element.addEventListener('turbo:submit-error', this._onSubmitError)
    this.element.addEventListener('turbo:submit-start', this._onSubmitStart)
  }

  disconnect() {
    // Clean up event listeners
    if (this._onSubmitEnd) this.element.removeEventListener('turbo:submit-end', this._onSubmitEnd)
    if (this._onSubmitError) this.element.removeEventListener('turbo:submit-error', this._onSubmitError)
    if (this._onSubmitStart) this.element.removeEventListener('turbo:submit-start', this._onSubmitStart)
  }

  submit(event) {
    console.log("Submit method called")
    
    if (!this.hasInputTarget) {
      console.error("Input target not found")
      return
    }
    
    const question = this.inputTarget.value.trim()
    console.log("Question submitted:", question)
    
    if (!question) {
      event.preventDefault()
      this.showError("Please enter a question.")
      return
    }

    // Prevent multiple submissions
    if (this.hasSubmitTarget && this.submitTarget) {
      this.submitTarget.disabled = true
    }

    // Show loading state if target exists
    this.showLoading()
    
    // Store the question for debugging
    this.lastQuestion = question
    
    console.log("Form submission proceeding...")
  }

  showLoading() {
    if (this.hasLoadingTarget && this.loadingTarget) {
      this.loadingTarget.classList.remove("hidden")
    }
  }

  hideLoading() {
    if (this.hasLoadingTarget && this.loadingTarget) {
      this.loadingTarget.classList.add("hidden")
    }
  }

  showError(message) {
    // Create error message
    const errorDiv = document.createElement("div")
    errorDiv.className = "bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4 text-sm"
    errorDiv.innerHTML = `
      <div class="flex items-center">
        <svg class="w-4 h-4 mr-2 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20" style="width: 16px; height: 16px; max-width: 16px; max-height: 16px;">
          <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd"></path>
        </svg>
        <span class="text-sm">${message}</span>
      </div>
    `
    
    // Insert error before the form
    if (this.element && this.element.parentNode) {
      this.element.parentNode.insertBefore(errorDiv, this.element)
    }
    
    // Remove error after 5 seconds
    setTimeout(() => {
      if (errorDiv.parentNode) {
        errorDiv.parentNode.removeChild(errorDiv)
      }
    }, 5000)
  }

  // Called when Turbo Stream response is received
  responseReceived(event) {
    console.log("Response received:", event)
    console.log("Response detail:", event.detail)
    this.hideLoading()
    
    // Re-enable the submit button
    if (this.hasSubmitTarget && this.submitTarget) {
      this.submitTarget.disabled = false
    }
    
    // Clear the input field and focus it for the next question
    setTimeout(() => {
      const input = document.getElementById('question-input')
      if (input) {
        input.value = ""
        input.focus()
        console.log("Input field cleared and focused")
      }
    }, 100)
    
    console.log("Response processed successfully")
  }

  // Handle form submission errors
  handleError(event) {
    console.error("Form submission error:", event)
    this.hideLoading()
    this.showError("An error occurred while submitting your question. Please try again.")
    
    // Re-enable the submit button
    if (this.hasSubmitTarget && this.submitTarget) {
      this.submitTarget.disabled = false
    }
  }

  // Called when form submission starts
  submitStart(event) {
    console.log("Form submission started:", event)
    this.showLoading()
  }

  // Verify that the form is ready for the next submission
  verifyFormReady() {
    console.log("Verifying form readiness...")
    console.log("Input target exists:", this.hasInputTarget)
    console.log("Submit target exists:", this.hasSubmitTarget)
    console.log("Submit button disabled:", this.hasSubmitTarget ? this.submitTarget.disabled : "N/A")
    console.log("Input value:", this.hasInputTarget ? this.inputTarget.value : "N/A")
    console.log("Form element:", this.element)
    
    if (this.hasInputTarget && this.inputTarget) {
      this.inputTarget.focus()
    }
  }
} 