import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import LOGO from '@salesforce/resourceUrl/WSRlogo';

export default class WoonstadCommandCentre extends NavigationMixin(LightningElement) {
    @track showCustomerSearchModal = false;
    @track showCreateCustomerWizardModal = false;
    logoUrl = LOGO;

    handleTileClick(event) {
    const target = event.currentTarget.dataset.target;

    // 🔁 Defensive reset of both modal flags
    this.showCustomerSearchModal = false;
    this.showCreateCustomerWizardModal = false;

    switch (target) {
        case 'zoekKlanten':
            setTimeout(() => {
                this.showCustomerSearchModal = true;
            }, 0);
            break;

        case 'aanvraag':
            this[NavigationMixin.Navigate]({
                type: 'standard__flow',
                attributes: { flowApiName: 'AanvraagFlow' }
            });
            break;

        case 'vraag':
            this[NavigationMixin.Navigate]({
                type: 'standard__component',
                attributes: { componentName: 'c__ikHebEenVraag' }
            });
            break;
    }
}

    closeCustomerSearchModal() {
        this.showCustomerSearchModal = false;
    }

    handleCreateNew() {
    console.log('⚡ createCustomer event received');
    this.showCustomerSearchModal = false;
    this.showCreateCustomerWizardModal = true;
}

    closeCreateCustomerWizardModal() {
        this.showCreateCustomerWizardModal = false;
    }

    handleBackToCustomerSearch() {
  this.showCreateCustomerWizardModal = false;
  this.showCustomerSearchModal = true;
}
}