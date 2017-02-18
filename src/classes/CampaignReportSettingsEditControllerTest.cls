/**
 * Developed by Doug Ayers (douglascayers.com)
 * https://github.com/DouglasCAyers/sfdc-add-campaign-members-by-report
 */
@isTest
private class CampaignReportSettingsEditControllerTest {

    /**
     * The Report object is read-only in Apex. It must be created via Metadata API.
     * Therefore our test relies on existing data being available to us, unfortunately.
     * Also, when testing Reports API the test will run with SeeAllData = true, regardless the annotation here.
     * I include the annotation for clarity.
     * https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_analytics_test_reports.htm
     */
    @isTest( seeAllData = true )
    static void test_create_setting() {

        Campaign camp = new Campaign(
            name = 'Test Campaign',
            isActive = true
        );

        insert camp;

        CampaignMemberStatus status = new CampaignMemberStatus(
            campaignId = camp.id,
            label = 'Sent'
        );

        insert status;

        Map<String, AddCampaignMembersByReportSetting__c> settingsMap = AddCampaignMembersByReportSetting__c.getAll();

        // delete existing settings
        delete settingsMap.values();

        Test.startTest();

        CampaignReportSettingsEditController controller = new CampaignReportSettingsEditController( new ApexPages.StandardController( new AddCampaignMembersByReportSetting__c() ) );

        List<SelectOption> statusOptions = controller.getMemberStatusOptions();
        List<SelectOption> folderOptions = controller.getFolderOptions();
        List<SelectOption> reportOptions = controller.getReportOptions();
        List<SelectOption> columnOptions = controller.getReportColumnOptions();

        PageReference page = controller.save();

        System.assertEquals( null, page );

        // -------------------------------------------

        controller = new CampaignReportSettingsEditController( new ApexPages.StandardController( new AddCampaignMembersByReportSetting__c() ) );

        controller.member.campaignId = camp.id;
        controller.member.status = controller.getMemberStatusOptions()[1].getValue();

        controller.selectedFolderId = controller.getFolderOptions()[1].getValue();
        controller.selectedReportId = controller.getReportOptions()[1].getValue();
        controller.selectedReportColumnName = controller.getReportColumnOptions()[1].getValue();

        page = controller.save();

        System.debug( page );
        System.assert( page.getUrl().containsIgnoreCase( 'CampaignReportSettingsListPage?save_success=true' ) );

        // -------------------------------------------

        page = controller.save(); // oops, will try to create duplicate!

        System.assertEquals( null, page );

        // -------------------------------------------

        controller.selectedReportColumnName = 'xyz'; // cause exception, non-existant column in report

        page = controller.save();

        System.assertEquals( null, page );

        // -------------------------------------------

        controller.cancel();

        Test.stopTest();

    }

    /**
     * The Report object is read-only in Apex. It must be created via Metadata API.
     * Therefore our test relies on existing data being available to us, unfortunately.
     * Also, when testing Reports API the test will run with SeeAllData = true, regardless the annotation here.
     * I include the annotation for clarity.
     * https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_analytics_test_reports.htm
     */
    @isTest( seeAllData = true )
    static void test_update_setting() {

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
            report_contact_or_lead_id_column_name__c = 'CONTACT_ID'
        );

        insert setting;

        Test.startTest();

        CampaignReportSettingsEditController controller = new CampaignReportSettingsEditController( new ApexPages.StandardController( setting ) );

        System.assertEquals( reportId, String.valueOf( controller.selectedReportId ).left( 15 ) );
        System.assertEquals( campaignId, String.valueOf( controller.member.campaignId ).left( 15 ) );

        // ---------------------------------------------

        setting.name = UserInfo.getUserId(); // won't match a report id
        update setting;

        controller = new CampaignReportSettingsEditController( new ApexPages.StandardController( setting ) );

        // ---------------------------------------------

        setting.name = reportId;
        setting.report_contact_or_lead_id_column_name__c = 'xyz'; // won't match existing report column
        update setting;

        controller = new CampaignReportSettingsEditController( new ApexPages.StandardController( setting ) );

        // ---------------------------------------------

        setting.campaign_id__c = String.valueOf( UserInfo.getUserId() ).left( 15 ); // won't match a campaign id
        setting.report_contact_or_lead_id_column_name__c = 'CONTACT_ID';
        update setting;

        controller = new CampaignReportSettingsEditController( new ApexPages.StandardController( setting ) );

        Test.stopTest();

    }

}