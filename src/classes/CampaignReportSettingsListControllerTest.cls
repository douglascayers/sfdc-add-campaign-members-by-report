/**
 * Developed by Doug Ayers (douglascayers.com)
 * https://github.com/DouglasCAyers/sfdc-add-campaign-members-by-report
 */
@isTest
private class CampaignReportSettingsListControllerTest {

    /**
     * The Report object is read-only in Apex. It must be created via Metadata API.
     * Therefore our test relies on existing data being available to us, unfortunately.
     * Also, when testing Reports API the test will run with SeeAllData = true, regardless the annotation here.
     * I include the annotation for clarity.
     * https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_analytics_test_reports.htm
     */
    @isTest( seeAllData = true )
    static void test_controller() {

        // grab an existing report, otherwise we'd have to dynamically create one in this test and
        // I'm not entirely certain how that would be done. Metadata or Tooling API perhaps?
        List<Report> reportList = new List<Report>([ select id from report where developerName = 'Add_Contacts_To_Campaign_Test' ]);
        List<Report> otherReportList = new List<Report>([ select id from report where developerName = 'NPSP_Test_Account_Report' ]);

        System.assert( reportList.size() > 0, 'Please create a Contact report that includes the Contact ID field and save the report with unique name Add_Contacts_To_Campaign_Test' );

        Campaign camp = new Campaign(
            name = 'Test Campaign',
            isActive = true
        );

        insert camp;

        String reportId = String.valueOf( reportList[0].id ).left( 15 );
        String otherReportId = String.valueOf( otherReportList[0].id ).left( 15 );
        String campaignId = String.valueOf( camp.id ).left( 15 );

        Map<String, AddCampaignMembersByReportSetting__c> settingsMap = AddCampaignMembersByReportSetting__c.getAll();

        // delete existing settings
        delete settingsMap.values();

        // create new setting for testing
        AddCampaignMembersByReportSetting__c setting1 = new AddCampaignMembersByReportSetting__c(
            setupOwnerId = UserInfo.getOrganizationId(),
            name = reportId,
            campaign_id__c = campaignId,
            report_contact_or_lead_id_column_label__c = 'Contact ID',
            report_contact_or_lead_id_column_name__c = 'CONTACT_ID'
        );

        AddCampaignMembersByReportSetting__c setting2 = new AddCampaignMembersByReportSetting__c(
            setupOwnerId = UserInfo.getOrganizationId(),
            name = otherReportId,
            campaign_id__c = campaignId,
            report_contact_or_lead_id_column_label__c = 'Account ID',
            report_contact_or_lead_id_column_name__c = 'ACCOUNT_ID'
        );

        insert new AddCampaignMembersByReportSetting__c[] { setting1, setting2 };

        Test.startTest();

        CampaignReportSettingsListController controller = new CampaignReportSettingsListController();

        System.assertEquals( 2, controller.settingWrappers.size() );

        Test.stopTest();

    }

    @isTest
    static void test_yes_save_success_message() {

        Test.startTest();

        ApexPages.currentPage().getParameters().put( 'save_success', 'true' );

        System.assertEquals( false, ApexPages.hasMessages( ApexPages.Severity.CONFIRM ) );

        CampaignReportSettingsListController controller = new CampaignReportSettingsListController();

        System.assertEquals( true, ApexPages.hasMessages( ApexPages.Severity.CONFIRM ) );

        Test.stopTest();

    }

    @isTest
    static void test_no_save_success_message() {

        Test.startTest();

        System.assertEquals( false, ApexPages.hasMessages( ApexPages.Severity.CONFIRM ) );

        CampaignReportSettingsListController controller = new CampaignReportSettingsListController();

        System.assertEquals( false, ApexPages.hasMessages( ApexPages.Severity.CONFIRM ) );

        Test.stopTest();

    }

}