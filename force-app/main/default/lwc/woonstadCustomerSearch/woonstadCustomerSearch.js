import { LightningElement, track } from 'lwc';
import searchAccountsByName from '@salesforce/apex/WoonstadCustomerSearchController.searchAccountsByName';
import LOGO from '@salesforce/resourceUrl/WSRLogo';

export default class WoonstadCustomerSearch extends LightningElement {
    @track searchTerm = '';
    @track accounts = [];
    @track noResults = false;
    hoveredAccountId = null;

    logoUrl = LOGO;

    // Update search term as user types
    handleSearchTermChange(event) {
        this.searchTerm = event.target.value;
    }

    // Search when user presses Enter
    handleKeyDown(event) {
        if (event.key === 'Enter') {
            this.searchAccounts();
        }
    }

    // Perform search using Apex method
    searchAccounts() {
        const input = this.searchTerm?.trim();
        if (!input || input.length < 3) {
            this.accounts = [];
            this.noResults = false;
            return;
        }

        searchAccountsByName({ name: input })
            .then(result => {
                console.log('✔️ Apex result:', JSON.stringify(result)); // Optional debug

                // ❗ FIXED: Removed broken sort on CreatedDate (was causing result to fail silently)
                const sorted = result; // or use .sort((a, b) => a.Name.localeCompare(b.Name)) if needed

                this.accounts = sorted.map(acc => {
                    let caseTooltip = 'Geen open zaken gevonden.';
                    if (acc.Cases && acc.Cases.length > 0) {
                        caseTooltip = acc.Cases.map(c =>
                            `${c.CaseNumber || ''} - ${c.CaseReason || ''} - ${c.Status || ''} - ${c.WocasNumber || ''} - ${c.Subject || ''} - ${c.Description || ''}`
                        ).join('\n');
                    }

                    return {
                        Id: acc.Id,
                        Name: acc.Name,
                        PersonBirthdate: acc.PersonBirthdate || '',
                        Phone: acc.Phone || '',
                        MaskedIban: acc.MaskedIban || '',
                        AddressName: acc.AddressName || '',
                        PostalCode: acc.PostalCode || '',
                        // CreatedDate was never returned from Apex, removed
                        CaseSummaryTooltip: caseTooltip,
                        Cases: acc.Cases || [],
                        isHovered: false
                    };
                });

                this.noResults = this.accounts.length === 0;
            })
            .catch(error => {
                console.error('Error fetching accounts:', error);
                this.accounts = [];
                this.noResults = true;
            });
    }

    // Show tooltip on hover
    handleMouseEnter(event) {
    const hoveredId = event.currentTarget.dataset.id;
    this.hoveredAccountId = hoveredId;

    // Update hover state
    this.accounts = this.accounts.map(acc => ({
        ...acc,
        isHovered: acc.Id === hoveredId
    }));

    // Delay to wait for the tooltip to render
    setTimeout(() => {
        const wrapper = this.template.querySelector(`div[data-id="${hoveredId}"]`);
        const tooltip = wrapper?.querySelector('.case-tooltip-extended');

        if (tooltip && wrapper) {
            // Reset existing classes
            tooltip.classList.remove('above', 'below');

            const wrapperRect = wrapper.getBoundingClientRect();
            const tooltipHeight = tooltip.offsetHeight;
            const buffer = 20; // Minimum space needed

            const spaceAbove = wrapperRect.top;
            const spaceBelow = window.innerHeight - wrapperRect.bottom;

            // Determine placement
            if (spaceAbove > tooltipHeight + buffer) {
                tooltip.classList.add('above');
            } else {
                tooltip.classList.add('below');
            }
        }
    }, 50); // slight delay to allow rendering
}

    handleMouseLeave() {
        this.hoveredAccountId = null;
        this.accounts = this.accounts.map(acc => ({
            ...acc,
            isHovered: false
        }));
    }

    // Open Account in new tab
    handleAccountClick(event) {
        const accountId = event.currentTarget.dataset.id;
        if (accountId) {
            window.open(`/lightning/r/Account/${accountId}/view`, '_blank');
        }
        this.closeModal();
    }

    // Close modal or go back
    goBack() {
        this.closeModal();
    }

    createCustomer() {
        this.closeModal();
        this.dispatchEvent(new CustomEvent('createnew'));
    }

    // Utility to close modal
    closeModal() {
        this.dispatchEvent(new CustomEvent('close'));
        const backdrops = document.querySelectorAll('.slds-backdrop.slds-backdrop_open');
        if (backdrops.length > 1) {
            backdrops[backdrops.length - 1].remove();
        }
    }
}