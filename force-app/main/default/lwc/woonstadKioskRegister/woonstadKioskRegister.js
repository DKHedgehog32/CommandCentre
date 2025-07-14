import { LightningElement } from 'lwc';
import LOGO from '@salesforce/resourceUrl/WSRLogo';

export default class WoonstadKioskRegister extends LightningElement {
    currentStep = 'start';
    visitorData = {};
    logoUrl = LOGO; // ✅ Logo reference for the success screen

    get showStart() {
        return this.currentStep === 'start';
    }

    get showForm() {
        return this.currentStep === 'form';
    }

    get showNameChoice() {
        return this.currentStep === 'nameChoice';
    }

    get showSuccess() {
        return this.currentStep === 'success';
    }

    handleExisting() {
        // Placeholder: future existing dossier logic
        console.log('Bestaand dossier geselecteerd');
    }

    handleNewVisit() {
        this.currentStep = 'form';
    }

    handleFormSubmit(event) {
        this.visitorData = { ...event.detail };
        this.currentStep = 'nameChoice';
    }

    handleNameChoice(event) {
        const altName = event.detail.name;
        const finalName = altName || `${this.visitorData.firstName} ${this.visitorData.lastName}`;
        console.log('Bezoeker geregistreerd als:', finalName);

        // TODO: Save logic could be added here

        this.currentStep = 'success';

        // Reset to start after 6 seconds
        setTimeout(() => {
            this.currentStep = 'start';
        }, 6000);
    }
}