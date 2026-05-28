import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import NAME_FIELD from '@salesforce/schema/Account.Name';
import INDUSTRY_FIELD from '@salesforce/schema/Account.Industry';
import REVENUE_FIELD from '@salesforce/schema/Account.AnnualRevenue';
import PHONE_FIELD from '@salesforce/schema/Account.Phone';

const FIELDS = [NAME_FIELD, INDUSTRY_FIELD, REVENUE_FIELD, PHONE_FIELD];

export default class AccountCard extends LightningElement {
    @api recordId;
    isExpanded = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    account;

    get accountName() {
        return getFieldValue(this.account.data, NAME_FIELD);
    }

    get industry() {
        return getFieldValue(this.account.data, INDUSTRY_FIELD);
    }

    get revenue() {
        const value = getFieldValue(this.account.data, REVENUE_FIELD);
        return value
            ? new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(value)
            : 'N/A';
    }

    get phone() {
        return getFieldValue(this.account.data, PHONE_FIELD);
    }

    get hasError() {
        return this.account.error;
    }

    get isLoading() {
        return !this.account.data && !this.account.error;
    }

    get cardClass() {
        return `slds-card ${this.isExpanded ? 'slds-card_expanded' : ''}`;
    }

    handleToggleExpand() {
        this.isExpanded = !this.isExpanded;
    }

    handleCopyPhone() {
        if (this.phone) {
            navigator.clipboard.writeText(this.phone).then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Copied',
                        message: 'Phone number copied to clipboard',
                        variant: 'success'
                    })
                );
            });
        }
    }
}
