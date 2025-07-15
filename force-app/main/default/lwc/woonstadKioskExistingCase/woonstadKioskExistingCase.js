import { LightningElement, track } from 'lwc';
import LOGO from '@salesforce/resourceUrl/WSRLogo';
import findCasesByAddressAndPerson from '@salesforce/apex/ExistingDossierService.findCasesByAddressAndPerson';

export default class WoonstadKioskExistingCase extends LightningElement {
    logoUrl = LOGO;

    @track street = '';
    @track houseNumber = '';
    @track postalCode = '';
    @track lastName = '';
    @track birthdate = '';
    @track phone = '';

    @track addressOptions = [];
    @track selectedAddressId = '';
    @track cases = [];
    @track errorMessage = '';
    @track showAccountStep = false;
    @track multipleAddresses = false;
    searchAttempts = 0;

    columns = [
        { label: 'Case Nummer', fieldName: 'caseNumber' },
        { label: 'Onderwerp', fieldName: 'subject' }
    ];

    handleStreetChange(e) {
        this.street = e.target.value;
    }

    handleHouseNumberChange(e) {
        this.houseNumber = e.target.value;
    }

    handlePostalCodeChange(e) {
        this.postalCode = e.target.value.replace(/\s/g, '').toUpperCase();
    }

    handleLastNameChange(e) {
        this.lastName = e.target.value;
    }

    handleBirthdateChange(e) {
        this.birthdate = e.target.value;
    }

    handlePhoneChange(e) {
        this.phone = e.target.value;
    }

    handleAddressSearch() {
        this.errorMessage = '';
        this.showAccountStep = false;
        this.cases = [];

        if (!this.street || !this.houseNumber || !this.postalCode.match(/^\d{4}[A-Z]{2}$/)) {
            this.errorMessage = 'Vul een geldige straat, huisnummer en postcode (1234AB) in.';
            return;
        }

        findCasesByAddressAndPerson({
            street: this.street,
            houseNumber: this.houseNumber,
            postalCode: this.postalCode,
            lastName: null,
            birthdate: null,
            phone: null
        })
        .then(result => {
            if (result.length === 1) {
                this.selectedAddressId = result[0].addressId;
                this.showAccountStep = true;
            } else if (result.length > 1) {
                this.addressOptions = result.map(a => ({
                    Id: a.addressId,
                    Name: a.addressName
                }));
                this.multipleAddresses = true;
            } else {
                this.searchAttempts++;
                if (this.searchAttempts >= 4) {
                    this.dispatchEvent(new CustomEvent('maxaddresssearchretries', {
    bubbles: true,
    composed: true
}));
                } else {
                    this.errorMessage = 'Geen adressen gevonden.';
                }
            }
        })
        .catch(err => {
            this.errorMessage = 'Fout bij zoeken van adressen.';
            console.error(err);
        });
    }

    handleAddressSelect(e) {
        this.selectedAddressId = e.target.value;
        this.showAccountStep = true;
        this.multipleAddresses = false;
    }

    handleFinalVerification() {
        this.errorMessage = '';

        if (!this.lastName || !this.birthdate || !this.phone) {
            this.errorMessage = 'Vul alstublieft alle velden in.';
            return;
        }

        findCasesByAddressAndPerson({
            street: null,
            houseNumber: null,
            postalCode: null,
            addressId: this.selectedAddressId,
            lastName: this.lastName,
            birthdate: this.birthdate,
            phone: this.phone
        })
        .then(result => {
            if (result.length > 0) {
                this.cases = result;
            } else {
                this.errorMessage = 'Geen bijbehorende dossiers gevonden.';
            }
        })
        .catch(err => {
            this.errorMessage = 'Fout bij zoeken van dossiers.';
            console.error(err);
        });
    }
}
