import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ACCOUNT_NAME from '@salesforce/schema/Account.Name';
import createLead from '@salesforce/apex/LeadCaptureController.createLead';

const EMAIL_REGEX = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;
const MAX_NOTES_LENGTH = 500;

export default class LeadCaptureForm extends LightningElement {
    /** The Account Id provided by the record page context. */
    @api recordId;

    /** Wire result for the current Account record. */
    @wire(getRecord, { recordId: '$recordId', fields: [ACCOUNT_NAME] })
    account;

    /** Tracked form field values. */
    @track firstName = '';
    @track lastName = '';
    @track email = '';
    @track phone = '';
    @track leadSource = '';
    @track notes = '';

    /** Flag to prevent double-submit and disable the button during the call. */
    isSubmitting = false;

    // ─── Getters ─────────────────────────────────────────────────────────────

    /**
     * Returns the Account Name from the wired record, used as the read-only
     * Company field value.
     */
    get companyName() {
        return getFieldValue(this.account.data, ACCOUNT_NAME) || '';
    }

    /** Lead Source picklist options matching standard Salesforce values. */
    get leadSourceOptions() {
        return [
            { label: 'Web', value: 'Web' },
            { label: 'Phone Inquiry', value: 'Phone Inquiry' },
            { label: 'Partner Referral', value: 'Partner Referral' },
            { label: 'Other', value: 'Other' }
        ];
    }

    // ─── Event Handlers ───────────────────────────────────────────────────────

    /**
     * Generic change handler for all text/combobox inputs.
     * Each input must have a data-field attribute matching the tracked property name.
     */
    handleChange(event) {
        const field = event.target.dataset.field;
        this[field] = event.target.value;
    }

    /**
     * Validates form state, calls the Apex controller, shows a toast, and
     * resets the form on success.
     */
    async handleSubmit() {
        const errorMessage = this.validate();
        if (errorMessage) {
            this.showToast('Validation Error', errorMessage, 'error');
            return;
        }

        this.isSubmitting = true;

        const draft = {
            firstName:  this.firstName,
            lastName:   this.lastName,
            email:      this.email,
            phone:      this.phone,
            company:    this.companyName,
            leadSource: this.leadSource,
            notes:      this.notes
        };

        try {
            const result = await createLead({
                draft:           draft,
                sourceAccountId: this.recordId
            });
            this.showToast(
                'Success',
                `Lead "${result.name}" created`,
                'success'
            );
            this.resetForm();
        } catch (error) {
            const message =
                (error.body && error.body.message) ||
                error.message ||
                'An unexpected error occurred.';
            this.showToast('Error Creating Lead', message, 'error');
        } finally {
            this.isSubmitting = false;
        }
    }

    /** Resets all tracked form fields to their initial empty values. */
    handleClear() {
        this.resetForm();
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    /**
     * Client-side validation. Returns the first error message found, or null
     * when all fields are valid.
     */
    validate() {
        if (!this.lastName || !this.lastName.trim()) {
            return 'Last Name is required.';
        }
        if (!this.email || !this.email.trim()) {
            return 'Email is required.';
        }
        if (!EMAIL_REGEX.test(this.email)) {
            return 'Please enter a valid email address.';
        }
        if (!this.companyName) {
            return 'Company could not be loaded from the Account. Please refresh the page.';
        }
        if (!this.leadSource) {
            return 'Lead Source is required.';
        }
        if (this.notes && this.notes.length > MAX_NOTES_LENGTH) {
            return `Capture Notes must not exceed ${MAX_NOTES_LENGTH} characters.`;
        }
        return null;
    }

    /** Clears all tracked fields. */
    resetForm() {
        this.firstName  = '';
        this.lastName   = '';
        this.email      = '';
        this.phone      = '';
        this.leadSource = '';
        this.notes      = '';
    }

    /**
     * Dispatches a ShowToastEvent.
     * @param {string} title
     * @param {string} message
     * @param {string} variant  'success' | 'error' | 'warning' | 'info'
     */
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
