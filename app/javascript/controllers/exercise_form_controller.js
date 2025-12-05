import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["typeSelector", "strengthFields", "cardioFields", "flexibilityFields"]

  connect() {
    // Initialize field visibility when form loads
    this.updateFields()
  }

  updateFields() {
    const selectedType = this.typeSelectorTarget.value

    // Hide all field groups
    this.strengthFieldsTarget.style.display = "none"
    this.cardioFieldsTarget.style.display = "none"
    this.flexibilityFieldsTarget.style.display = "none"

    // Show selected field group
    switch(selectedType) {
      case "strength":
        this.strengthFieldsTarget.style.display = "block"
        break
      case "cardio":
        this.cardioFieldsTarget.style.display = "block"
        break
      case "flexibility":
        this.flexibilityFieldsTarget.style.display = "block"
        break
    }
  }
}
