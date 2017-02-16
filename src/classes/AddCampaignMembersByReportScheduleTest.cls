/**
 * Developed by Doug Ayers (douglascayers.com)
 * https://github.com/DouglasCAyers/sfdc-add-campaign-members-by-report
 */
@isTest
private class AddCampaignMembersByReportScheduleTest {

    /**
     * The Report object is read-only in Apex. It must be created via Metadata API.
     * Therefore our test relies on existing data being available to us, unfortunately.
     * Also, when testing Reports API the test will run with SeeAllData = true, regardless the annotation here.
     * I include the annotation for clarity.
     * https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_analytics_test_reports.htm
     */
    @isTest( seeAllData = true )
    static void test_schedule() {

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
            report_contact_or_lead_id_column_label__c = 'Contact ID',
            report_contact_or_lead_id_column_name__c = 'Contact_ID'
        );

        insert setting;

        Test.startTest();

        String cron = '0 0 0 * * ?';

        System.schedule( 'AddCampaignMembersJob-' + DateTime.now().getTime(), cron, new AddCampaignMembersByReportSchedulable() );

        Test.stopTest();

        // Note, this only tests that the schedule runs
        // Salesforce won't actually invoke the batchable to assert side effects

    }

}