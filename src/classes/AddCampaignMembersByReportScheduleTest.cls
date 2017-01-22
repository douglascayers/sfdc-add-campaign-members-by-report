/**
 * Developed by Doug Ayers (douglascayers.com)
 * https://github.com/DouglasCAyers/sfdc-add-campaign-members-by-report
 */
@isTest
private class AddCampaignMembersByReportScheduleTest {

    /**
     * The Report object is read-only in Apex. It must be created via Metadata API.
     * Therefore our test relies on existing data being available to us, unfortunately.
     * https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_analytics_test_reports.htm
     */
    @isTest( seeAllData = true )
    static void test_schedule() {

        // grab an existing report, otherwise we'd have to dynamically create one in this test and
        // I'm not entirely certain how that would be done. Metadata or Tooling API perhaps?
        List<Report> reportList = new List<Report>([ select id from report where developerName = 'Add_Contacts_To_Campaign_Test' ]);

        System.assert( reportList.size() > 0, 'Please create a Contact report that includes the Contact ID field and save the report with unique name Add_Contacts_To_Campaign_Test' );

        Campaign c = new Campaign(
            name = 'Test Campaign',
            isActive = true
        );

        insert c;

        String reportId = String.valueOf( reportList[0].id ).left( 15 );
        String campaignId = String.valueOf( c.id ).left( 15 );

        Map<String, AddCampaignMembersByReportSetting__c> settingsMap = AddCampaignMembersByReportSetting__c.getAll();

        AddCampaignMembersByReportSetting__c setting = settingsMap.get( reportId );

        if ( setting == null ) {

            setting = new AddCampaignMembersByReportSetting__c(
                setupOwnerId = UserInfo.getOrganizationId(),
                name = reportId,
                campaign_id__c = campaignId,
                report_contact_or_lead_id_column_label__c = 'Contact ID'
            );

            insert setting;

        }

        Test.startTest();

        String cron = '0 0 0 * * ?';

        System.schedule( 'AddCampaignMembersJob-' + DateTime.now().getTime(), cron, new AddCampaignMembersByReportSchedulable() );

        Test.stopTest();

    }

}