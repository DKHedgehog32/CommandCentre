import { LightningElement } from 'lwc';
import LOGO from '@salesforce/resourceUrl/WSRLogo';

export default class WoonstadCreateCustomerWizard extends LightningElement {
  logoUrl = LOGO;
  modalSize = 'small';
  currentStep = 1;

  get modalSizeClass() {
    return `custom-modal-container ${this.modalSize}`;
  }

  // Computed steps with styling classes
  get stepsWithClasses() {
    return [
      {
        number: 1,
        label: 'Type Klant',
        stepClass: this.currentStep === 1 ? 'step active' : 'step',
        circleClass: this.currentStep === 1 ? 'circle active' : 'circle'
      },
      {
        number: 2,
        label: 'Algemene gegevens',
        stepClass: this.currentStep === 2 ? 'step active' : 'step',
        circleClass: this.currentStep === 2 ? 'circle active' : 'circle'
      },
      {
        number: 3,
        label: 'Adresgegevens',
        stepClass: this.currentStep === 3 ? 'step active' : 'step',
        circleClass: this.currentStep === 3 ? 'circle active' : 'circle'
      },
      {
        number: 4,
        label: 'Valideren',
        stepClass: this.currentStep === 4 ? 'step active' : 'step',
        circleClass: this.currentStep === 4 ? 'circle active' : 'circle'
      }
    ];
  }

  handleCreateCompany() {
    console.log('Bedrijf aanmaken gekozen');
    this.currentStep = 2;
  }

  handleCreatePerson() {
    console.log('Klant aanmaken gekozen');
    this.currentStep = 2;
  }

  handleCancel() {
    this.dispatchEvent(new CustomEvent('close'));
  }

  handleBackToSearch() {
  this.dispatchEvent(new CustomEvent('back'));
}
}