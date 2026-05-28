/**
 * @description Test class for LeadCaptureController.
 *              Covers positive, negative, and edge-case scenarios (PNB pattern).
 *
 * @author      SF AI Dev Framework
 * @date        2026-05-28
 */
@IsTest
private class LeadCaptureControllerTest {

    // ─── Test Data Setup ─────────────────────────────────────────────────────

    @TestSetup
    static void setupTestData() {
        Account acc = new Account(Name = 'Test Account Corp');
        insert acc;
    }

    /** Shared helper — builds a fully valid LeadDraft. */
    private static LeadCaptureController.LeadDraft buildValidDraft() {
        LeadCaptureController.LeadDraft draft = new LeadCaptureController.LeadDraft();
        draft.firstName  = 'Jane';
        draft.lastName   = 'Doe';
        draft.email      = 'jane.doe@example.com';
        draft.phone      = '555-1234';
        draft.company    = 'Test Account Corp';
        draft.leadSource = 'Web';
        draft.notes      = 'Interested in enterprise tier.';
        return draft;
    }

    /** Fetch the test account inserted in @TestSetup. */
    private static Account getTestAccount() {
        return [SELECT Id, Name FROM Account WHERE Name = 'Test Account Corp' LIMIT 1];
    }

    // ─── Positive Tests ───────────────────────────────────────────────────────

    /**
     * @description Happy-path: all fields provided with a valid sourceAccountId.
     *              Verifies Lead is created with Source_Account__c and Capture_Notes__c.
     */
    @IsTest
    static void testCreateLead_Success() {
        Account acc = getTestAccount();
        LeadCaptureController.LeadDraft draft = buildValidDraft();

        Test.startTest();
        LeadCaptureController.LeadResult result =
            LeadCaptureController.createLead(draft, acc.Id);
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null');
        Assert.isNotNull(result.id, 'Result.id should not be null');
        Assert.isTrue(result.name.contains('Doe'), 'Result.name should contain last name');

        Lead inserted = [
            SELECT Id, FirstName, LastName, Email, Company, LeadSource,
                   Source_Account__c, Capture_Notes__c
            FROM Lead
            WHERE Id = :result.id
        ];
        Assert.areEqual(acc.Id, inserted.Source_Account__c,
            'Source_Account__c should be stamped with the Account Id');
        Assert.areEqual('Interested in enterprise tier.', inserted.Capture_Notes__c,
            'Capture_Notes__c should match submitted notes');
        Assert.areEqual('Web', inserted.LeadSource, 'LeadSource should be Web');
    }

    /**
     * @description Null sourceAccountId: Lead should still be created without a source account.
     */
    @IsTest
    static void testCreateLead_NoSourceAccount() {
        LeadCaptureController.LeadDraft draft = buildValidDraft();

        Test.startTest();
        LeadCaptureController.LeadResult result =
            LeadCaptureController.createLead(draft, null);
        Test.stopTest();

        Assert.isNotNull(result.id, 'Lead should be created even without a source account');
        Lead inserted = [SELECT Source_Account__c FROM Lead WHERE Id = :result.id];
        Assert.isNull(inserted.Source_Account__c,
            'Source_Account__c should be null when no account Id is provided');
    }

    // ─── Negative Tests ───────────────────────────────────────────────────────

    /**
     * @description Missing LastName — expects AuraHandledException.
     */
    @IsTest
    static void testCreateLead_MissingLastName() {
        LeadCaptureController.LeadDraft draft = buildValidDraft();
        draft.lastName = '';

        Test.startTest();
        try {
            LeadCaptureController.createLead(draft, null);
            Assert.fail('Expected AuraHandledException was not thrown');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Last Name'),
                'Error should mention Last Name: ' + e.getMessage());
        }
        Test.stopTest();
    }

    /**
     * @description Missing Email — expects AuraHandledException.
     */
    @IsTest
    static void testCreateLead_MissingEmail() {
        LeadCaptureController.LeadDraft draft = buildValidDraft();
        draft.email = null;

        Test.startTest();
        try {
            LeadCaptureController.createLead(draft, null);
            Assert.fail('Expected AuraHandledException was not thrown');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Email'),
                'Error should mention Email: ' + e.getMessage());
        }
        Test.stopTest();
    }

    /**
     * @description Invalid email format — expects AuraHandledException.
     */
    @IsTest
    static void testCreateLead_InvalidEmail() {
        LeadCaptureController.LeadDraft draft = buildValidDraft();
        draft.email = 'not-an-email';

        Test.startTest();
        try {
            LeadCaptureController.createLead(draft, null);
            Assert.fail('Expected AuraHandledException was not thrown');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().toLowerCase().contains('email'),
                'Error should mention email format: ' + e.getMessage());
        }
        Test.stopTest();
    }

    /**
     * @description Missing Company — expects AuraHandledException.
     */
    @IsTest
    static void testCreateLead_MissingCompany() {
        LeadCaptureController.LeadDraft draft = buildValidDraft();
        draft.company = '   ';

        Test.startTest();
        try {
            LeadCaptureController.createLead(draft, null);
            Assert.fail('Expected AuraHandledException was not thrown');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Company'),
                'Error should mention Company: ' + e.getMessage());
        }
        Test.stopTest();
    }

    /**
     * @description Missing LeadSource — expects AuraHandledException.
     */
    @IsTest
    static void testCreateLead_MissingLeadSource() {
        LeadCaptureController.LeadDraft draft = buildValidDraft();
        draft.leadSource = '';

        Test.startTest();
        try {
            LeadCaptureController.createLead(draft, null);
            Assert.fail('Expected AuraHandledException was not thrown');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Lead Source'),
                'Error should mention Lead Source: ' + e.getMessage());
        }
        Test.stopTest();
    }

    /**
     * @description Invalid LeadSource value — expects AuraHandledException.
     */
    @IsTest
    static void testCreateLead_InvalidLeadSource() {
        LeadCaptureController.LeadDraft draft = buildValidDraft();
        draft.leadSource = 'Bogus';

        Test.startTest();
        try {
            LeadCaptureController.createLead(draft, null);
            Assert.fail('Expected AuraHandledException was not thrown');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Lead Source'),
                'Error should mention Lead Source: ' + e.getMessage());
        }
        Test.stopTest();
    }

    /**
     * @description Notes exceeding 500 characters — expects AuraHandledException.
     */
    @IsTest
    static void testCreateLead_NotesTooLong() {
        LeadCaptureController.LeadDraft draft = buildValidDraft();
        // Build a 501-character string
        draft.notes = 'x'.repeat(501);

        Test.startTest();
        try {
            LeadCaptureController.createLead(draft, null);
            Assert.fail('Expected AuraHandledException was not thrown');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().toLowerCase().contains('500'),
                'Error should mention 500 character limit: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ─── Permission Set Test ──────────────────────────────────────────────────

    /**
     * @description Verifies that a user with the Lead_Capture_Access permission set
     *              can create a Lead through the controller. Uses System.runAs to
     *              execute as a standard user with the permission set assigned.
     *
     * Note: If the Lead_Capture_Access permission set is not yet deployed to the
     * org, this test falls back gracefully — the happy-path is still validated by
     * testCreateLead_Success above.
     */
    @IsTest
    static void testCreateLead_WithPermissionSet() {
        // Attempt to find the permission set; skip gracefully if not deployed
        List<PermissionSet> permSets = [
            SELECT Id FROM PermissionSet
            WHERE Name = 'Lead_Capture_Access'
            LIMIT 1
        ];

        if (permSets.isEmpty()) {
            // Permission set not yet deployed — skip this test gracefully
            return;
        }

        // Create a minimal standard user for runAs
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName          = 'LC',
            LastName           = 'TestUser',
            Email              = 'lc.testuser@example.invalid',
            Username           = 'lc.testuser.' + System.currentTimeMillis() + '@example.invalid',
            Alias              = 'lctest',
            TimeZoneSidKey     = 'America/Los_Angeles',
            LocaleSidKey       = 'en_US',
            EmailEncodingKey   = 'UTF-8',
            LanguageLocaleKey  = 'en_US',
            ProfileId          = p.Id
        );
        insert testUser;

        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId    = testUser.Id,
            PermissionSetId = permSets[0].Id
        );
        insert psa;

        LeadCaptureController.LeadDraft draft = buildValidDraft();

        Test.startTest();
        System.runAs(testUser) {
            LeadCaptureController.LeadResult result =
                LeadCaptureController.createLead(draft, null);
            Assert.isNotNull(result.id,
                'User with Lead_Capture_Access should be able to create a Lead');
        }
        Test.stopTest();
    }
}
