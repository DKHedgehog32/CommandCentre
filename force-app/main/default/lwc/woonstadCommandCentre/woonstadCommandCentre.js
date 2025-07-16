import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class WoonstadCommandCentre extends NavigationMixin(LightningElement) {
    handleTileClick(event) {
        const target = event.currentTarget.dataset.target;
        switch (target) {
            case 'zoekKlanten':
                this[NavigationMixin.Navigate]({
                    type: 'standard__component',
                    attributes: { componentName: 'c__zoekNaarKlanten' }
                });
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
}