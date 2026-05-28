/**
 * @description Controller for the leadCaptureForm LWC component.
 *              Handles creation of Lead records from the Account record page,
 *              stamping the Source_Account__c lookup with the originating Account Id.
 *
 * @author      SF AI Dev Framework
 * @date        2026-05-28
 */
public with sharing class LeadCaptureController {

    /**
     * @description DTO carrying the draft lead fields submitted from the LWC form.
     */
    public class LeadDraft {
        @AuraEnabled public String firstName;
        @AuraEnabled public String lastName;
        @AuraEnabled public String email;
        @AuraEnabled public String phone;
        @AuraEnabled public String company;
        @AuraEnabled public String leadSource;
        @AuraEnabled public String notes;
    }

    /**
     * @description Result returned to the LWC after a successful Lead insert.
     */
    public class LeadResult {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;

        /**
         * @description Constructor.
         * @param i  The Id of the newly created Lead.
         * @param n  The full Name of the newly created Lead.
         */
        public LeadResult(Id i, String n) {
            id = i;
            name = n;
        }
    }

    /** Valid picklist values accepted for LeadSource. */
    private static final Set<String> VALID_LEAD_SOURCES = new Set<String>{
        'Web',
        'Phone Inquiry',
        'Partner Referral',
        'Other'
    };

    /** Email regex pattern per the solution spec. */
    private static final String EMAIL_REGEX =
        '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$';

    /**
     * @description Creates a Lead record from the data submitted by the form.
     *
     * @param draft           The draft lead data from the LWC.
     * @param sourceAccountId The Id of the Account record page the form lives on.
     *                        May be null if the component is placed outside a record page.
     * @return                LeadResult containing the new Lead's Id and Name.
     * @throws AuraHandledException on validation failure or DML/query error.
     */
    @AuraEnabled
    public static LeadResult createLead(LeadDraft draft, Id sourceAccountId) {
        // --- Input validation ---
        if (draft == null) {
            throwAura('Lead data is required.');
        }

        if (String.isBlank(draft.lastName)) {
            throwAura('Last Name is required.');
        }

        if (String.isBlank(draft.email)) {
            throwAura('Email is required.');
        }

        if (!Pattern.matches(EMAIL_REGEX, draft.email)) {
            throwAura('Email format is invalid.');
        }

        if (String.isBlank(draft.company)) {
            throwAura('Company is required.');
        }

        if (String.isBlank(draft.leadSource)) {
            throwAura('Lead Source is required.');
        }

        if (!VALID_LEAD_SOURCES.contains(draft.leadSource)) {
            throwAura('Lead Source must be one of: Web, Phone Inquiry, Partner Referral, Other.');
        }

        if (String.isNotBlank(draft.notes) && draft.notes.length() > 500) {
            throwAura('Capture Notes must not exceed 500 characters.');
        }

        // --- Build sObject ---
        Lead lead = new Lead(
            FirstName         = draft.firstName,
            LastName          = draft.lastName,
            Email             = draft.email,
            Phone             = draft.phone,
            Company           = draft.company,
            LeadSource        = draft.leadSource,
            Capture_Notes__c  = draft.notes,
            Source_Account__c = sourceAccountId
        );

        // --- DML ---
        try {
            Database.insert(lead, AccessLevel.USER_MODE);
        } catch (DmlException e) {
            throwAura(e.getMessage());
        }

        // --- Re-query ---
        try {
            Lead inserted = [
                SELECT Id, Name
                FROM Lead
                WHERE Id = :lead.Id
                WITH USER_MODE
            ];
            return new LeadResult(inserted.Id, inserted.Name);
        } catch (QueryException e) {
            throwAura(e.getMessage());
        }

        // Unreachable — compiler requires a return
        return null;
    }

    /**
     * @description Throws a properly configured AuraHandledException so the
     *              message surfaces to the LWC catch block via error.body.message.
     *
     * @param message Human-readable error message.
     */
    private static void throwAura(String message) {
        AuraHandledException ex = new AuraHandledException(message);
        ex.setMessage(message);
        throw ex;
    }
}
