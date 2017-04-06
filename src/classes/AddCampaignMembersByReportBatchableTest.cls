/**
 * Developed by Doug Ayers (douglascayers.com)
 * https://github.com/DouglasCAyers/sfdc-add-campaign-members-by-report
 */
@isTest
private class AddCampaignMembersByReportBatchableTest {

    /**
     * The Report object is read-only in Apex. It must be created via Metadata API.
     * Therefore our test relies on existing data being available to us, unfortunately.
     * Also, when testing Reports API the test will run with SeeAllData = true, regardless the annotation here.
     * I include the annotation for clarity.
     * https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_analytics_test_reports.htm
     */
    @isTest( seeAllData = true )
    static void test_batchable() {

        // grab an existing report, otherwise we'd have to dynamically create one in this test and
        // I'm not entirely certain how that would be done. Metadata or Tooling API perhaps?
        List<Report> reportList = new List<Report>([ select id from report where developerName = 'Add_Contacts_To_Campaign_Test' ]);

        System.assert( reportList.size() > 0, 'Please create a Contact report that includes the Contact ID field and save the report with unique name Add_Contacts_To_Campaign_Test' );

        Account acct = new Account(
            name = 'Salesforce'
        );

        insert acct;

        Contact cont = new Contact(
            firstName = 'Marc',
            lastName = 'Benioff',
            accountId = acct.id
        );

        insert cont;

        Lead ld = new Lead(
            firstName = 'Parker',
            lastName = 'Harris',
            company = 'Salesforce'
        );

        insert ld;

        Campaign camp = new Campaign(
            name = 'Test Campaign',
            isActive = true
        );

        insert camp;

        CampaignMember member = new CampaignMember(
            campaignId = camp.id,
            leadId = ld.id
        );

        insert member;

        String reportId = String.valueOf( reportList[0].id ).left( 15 );
        String campaignId = String.valueOf( camp.id ).left( 15 );

        Map<String, AddCampaignMembersByReportSetting__c> settingsMap = AddCampaignMembersByReportSetting__c.getAll();

        // delete existing settings
        delete settingsMap.values();

        // create one new setting for testing
        AddCampaignMembersByReportSetting__c setting = new AddCampaignMembersByReportSetting__c(
            setupOwnerId = UserInfo.getOrganizationId(),
            name = reportId,
            campaign_id__c = campaignId,
            report_contact_or_lead_id_column_label__c = 'Contact ID',
            report_contact_or_lead_id_column_name__c = 'Contact_ID'
        );

        insert setting;

        List<ID> leadOrContactIds = new List<ID>{ cont.id, ld.id };

        System.assertEquals( 1, [ SELECT count() FROM CampaignMember WHERE campaignId = :camp.id AND leadOrContactId IN :leadOrContactIds ] );

        Test.startTest();

        Database.executeBatch( new AddCampaignMembersByReportBatchable( reportId ) );

        Test.stopTest();

        List<Add_Campaign_Members_by_Report_Log__c> logs = [ SELECT id, summary__c, detail__c FROM Add_Campaign_Members_by_Report_Log__c ];
        System.debug( LoggingLevel.ERROR, logs );

        System.assertEquals( 0, logs.size() );
        System.assertEquals( 2, [ SELECT count() FROM CampaignMember WHERE campaignId = :camp.id ] );

    }

    /**
     * The Report object is read-only in Apex. It must be created via Metadata API.
     * Therefore our test relies on existing data being available to us, unfortunately.
     * Also, when testing Reports API the test will run with SeeAllData = true, regardless the annotation here.
     * I include the annotation for clarity.
     * https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_analytics_test_reports.htm
     */
    @isTest( seeAllData = true )
    static void test_errors_during_execute() {

        // grab an existing report, otherwise we'd have to dynamically create one in this test and
        // I'm not entirely certain how that would be done. Metadata or Tooling API perhaps?
        List<Report> reportList = new List<Report>([ select id from report where developerName = 'Add_Contacts_To_Campaign_Test' ]);

        System.assert( reportList.size() > 0, 'Please create a Contact report that includes the Contact ID field and save the report with unique name Add_Contacts_To_Campaign_Test' );

        Account acct = new Account(
            name = 'Salesforce'
        );

        insert acct;

        Contact cont = new Contact(
            firstName = 'Marc',
            lastName = 'Benioff',
            accountId = acct.id
        );

        insert cont;

        Lead ld = new Lead(
            firstName = 'Parker',
            lastName = 'Harris',
            company = 'Salesforce'
        );

        insert ld;

        Campaign camp = new Campaign(
            name = 'Test Campaign',
            isActive = true
        );

        insert camp;

        CampaignMember member = new CampaignMember(
            campaignId = camp.id,
            leadId = ld.id
        );

        insert member;

        String reportId = String.valueOf( reportList[0].id ).left( 15 );
        String campaignId = String.valueOf( camp.id ).left( 15 );

        Map<String, AddCampaignMembersByReportSetting__c> settingsMap = AddCampaignMembersByReportSetting__c.getAll();

        // delete existing settings
        delete settingsMap.values();

        // create one new setting for testing
        AddCampaignMembersByReportSetting__c setting = new AddCampaignMembersByReportSetting__c(
            setupOwnerId = UserInfo.getOrganizationId(),
            name = reportId,
            campaign_id__c = campaignId,
            report_contact_or_lead_id_column_label__c = 'Contact ID',
            report_contact_or_lead_id_column_name__c = 'Contact_ID'
        );

        insert setting;

        List<ID> leadOrContactIds = new List<ID>{ cont.id, ld.id };

        System.assertEquals( 1, [ SELECT count() FROM CampaignMember WHERE campaignId = :camp.id AND leadOrContactId IN :leadOrContactIds ] );

        Test.startTest();

        AddCampaignMembersByReportBatchable job = new AddCampaignMembersByReportBatchable( reportId );
        job.campaignId = null; // cause runtime exception

        Database.executeBatch( job );

        Test.stopTest();

        List<Add_Campaign_Members_by_Report_Log__c> logs = [ SELECT id, summary__c, detail__c FROM Add_Campaign_Members_by_Report_Log__c ];
        System.debug( LoggingLevel.ERROR, logs );

        System.assertNotEquals( 0, logs.size(), 'should have errors' );
        System.assertEquals( 1, [ SELECT count() FROM CampaignMember WHERE campaignId = :camp.id ], 'should have rolled back and not added new member' );

    }

    /**
     * The Report object is read-only in Apex. It must be created via Metadata API.
     * Therefore our test relies on existing data being available to us, unfortunately.
     * Also, when testing Reports API the test will run with SeeAllData = true, regardless the annotation here.
     * I include the annotation for clarity.
     * https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_analytics_test_reports.htm
     */
    @isTest( seeAllData = true )
    static void test_setting_not_found() {

        // grab an existing report, otherwise we'd have to dynamically create one in this test and
        // I'm not entirely certain how that would be done. Metadata or Tooling API perhaps?
        List<Report> reportList = new List<Report>([ select id from report where developerName = 'Add_Contacts_To_Campaign_Test' ]);

        System.assert( reportList.size() > 0, 'Please create a Contact report that includes the Contact ID field and save the report with unique name Add_Contacts_To_Campaign_Test' );

        String reportId = String.valueOf( reportList[0].id ).left( 15 );

        Map<String, AddCampaignMembersByReportSetting__c> settingsMap = AddCampaignMembersByReportSetting__c.getAll();

        // delete existing settings
        delete settingsMap.values();

        Test.startTest();

        Database.executeBatch( new AddCampaignMembersByReportBatchable( reportId ) );

        Test.stopTest();

        List<Add_Campaign_Members_by_Report_Log__c> logs = [ SELECT id, summary__c, detail__c FROM Add_Campaign_Members_by_Report_Log__c ];
        System.debug( LoggingLevel.ERROR, logs );

        System.assertNotEquals( 0, logs.size(), 'Expected to fail' );

    }

    /**
     * The Report object is read-only in Apex. It must be created via Metadata API.
     * Therefore our test relies on existing data being available to us, unfortunately.
     * Also, when testing Reports API the test will run with SeeAllData = true, regardless the annotation here.
     * I include the annotation for clarity.
     * https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_analytics_test_reports.htm
     */
    @isTest( seeAllData = true )
    static void test_report_column_not_found() {

        // grab an existing report, otherwise we'd have to dynamically create one in this test and
        // I'm not entirely certain how that would be done. Metadata or Tooling API perhaps?
        List<Report> reportList = new List<Report>([ select id from report where developerName = 'Add_Contacts_To_Campaign_Test' ]);

        System.assert( reportList.size() > 0, 'Please create a Contact report that includes the Contact ID field and save the report with unique name Add_Contacts_To_Campaign_Test' );

        Campaign camp = new Campaign(
            name = 'Test Campaign',
            isActive = true
        );

        insert camp;

        String reportId = String.valueOf( reportList[0].id ).left( 15 );
        String campaignId = String.valueOf( camp.id ).left( 15 );

        Map<String, AddCampaignMembersByReportSetting__c> settingsMap = AddCampaignMembersByReportSetting__c.getAll();

        // delete existing settings
        delete settingsMap.values();

        // create one new setting for testing
        AddCampaignMembersByReportSetting__c setting = new AddCampaignMembersByReportSetting__c(
            setupOwnerId = UserInfo.getOrganizationId(),
            name = reportId,
            campaign_id__c = campaignId,
            report_contact_or_lead_id_column_label__c = 'ABC',
            report_contact_or_lead_id_column_name__c = 'abc'
        );

        insert setting;

        Test.startTest();

        Database.executeBatch( new AddCampaignMembersByReportBatchable( reportId ) );

        Test.stopTest();

        List<Add_Campaign_Members_by_Report_Log__c> logs = [ SELECT id, summary__c, detail__c FROM Add_Campaign_Members_by_Report_Log__c ];
        System.debug( LoggingLevel.ERROR, logs );

        System.assertNotEquals( 0, logs.size(), 'Expected to fail' );

    }

    @isTest
    static void test_empty_iterator() {

        Test.startTest();

        Iterator<ID> iterator = new AddCampaignMembersByReportBatchable.EmptyIterator().iterator();

        Test.stopTest();

        System.assertEquals( null, iterator.next() );
        System.assertEquals( false, iterator.hasNext() );

    }

}