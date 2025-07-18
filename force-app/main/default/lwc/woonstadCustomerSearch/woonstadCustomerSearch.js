// woonstadCustomerSearch.js
import { LightningElement, track } from 'lwc';
import searchAccountsByName from '@salesforce/apex/WoonstadCustomerSearchController.searchAccountsByName';
import LOGO from '@salesforce/resourceUrl/WSRLogo'; // 🔹 Add logo resource import

export default class WoonstadCustomerSearch extends LightningElement {
    @track searchTerm = '';
    @track accounts = [];
    @track noResults = false;

    logoUrl = LOGO; // 🔹 Assign logo URL to use in template

    /**
     * Handle input change
     */
    handleSearchTermChange(event) {
        this.searchTerm = event.target.value;
    }

    /**
     * Trigger search on Enter
     */
    handleKeyDown(event) {
        if (event.key === 'Enter') {
            this.searchAccounts();
        }
    }

    /**
     * Apex search call
     */
    searchAccounts() {
        const trimmed = this.searchTerm?.trim();
        if (!trimmed) {
            this.accounts = [];
            this.noResults = false;
            return;
        }

        searchAccountsByName({ name: trimmed })
            .then(result => {
                // Enrich records with fallback values
                this.accounts = result.map(acc => ({
                    Id: acc.Id,
                    Name: acc.Name,
                    PersonBirthdate: acc.PersonBirthdate || '',
                    Phone: acc.Phone || '',
                    MaskedIban: acc.MaskedIban || '', // from Apex
                    AddressName: acc.AddressName || '',
                    PostalCode: acc.PostalCode || ''
                }));
                this.noResults = this.accounts.length === 0;
            })
            .catch(error => {
                console.error('Error fetching accounts:', error);
                this.accounts = [];
                this.noResults = true;
            });
    }

    /**
     * Open account and close modal
     */
    handleAccountClick(event) {
        const accountId = event.currentTarget.dataset.id;
        if (accountId) {
            window.open(`/lightning/r/Account/${accountId}/view`, '_blank');
        }
        this.closeModal();
    }

    /**
     * Return to home screen
     */
    goBack() {
        this.closeModal();
    }

    /**
     * Create customer — notify parent to switch modals
     */
    createCustomer() {
        console.log('📣 Dispatching createnew event');
        this.closeModal(); // Close current modal
        this.dispatchEvent(new CustomEvent('createnew'));
    }

    /**
     * Utility to close modal and remove any leftover backdrop
     */
    closeModal() {
        this.dispatchEvent(new CustomEvent('close'));

        // Prevent duplicate backdrop issue
        const backdrops = document.querySelectorAll('.slds-backdrop.slds-backdrop_open');
        if (backdrops.length > 1) {
            backdrops[backdrops.length - 1].remove(); // Remove the last added one
        }
    }
}