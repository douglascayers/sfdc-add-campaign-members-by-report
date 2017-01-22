/**
 * Developed by Doug Ayers (douglascayers.com)
 * https://github.com/DouglasCAyers/sfdc-add-campaign-members-by-report
 */
@isTest
private class AddCampaignMembersByReportActionTest {

    /**
     * The Report object is read-only in Apex. It must be created via Metadata API.
     * Therefore our test relies on existing data being available to us, unfortunately.
     * Also, when testing Reports API the test will run with SeeAllData = true, regardless the annotation here.
     * I include the annotation for clarity.
     * https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_analytics_test_reports.htm
     */
    @isTest( seeAllData = true )
    static void test_notification() {

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

        AddCampaignMembersByReportSetting__c setting = settingsMap.get( reportId );

        if ( setting == null ) {

            setting = new AddCampaignMembersByReportSetting__c(
                setupOwnerId = UserInfo.getOrganizationId(),
                name = reportId,
                campaign_id__c = campaignId,
                report_contact_or_lead_id_column_label__c = 'Contact ID'
            );

            insert setting;

        } else {

            setting.campaign_id__c = campaignId;
            setting.report_contact_or_lead_id_column_label__c = 'Contact ID';
            setting.campaign_member_added_status__c = null;

            update setting;

        }

        // Ideas how to create report notification action test from Andy Fawcett and Dominick Medley
        // http://andyinthecloud.com/2015/11/07/supercharging-salesforce-report-subscriptions-with-apex-and-flow/

        Test.startTest();

        Boolean includeDetails = true;

        Reports.ReportInstance reportInstance = Reports.ReportManager.runAsyncReport( reportId, includeDetails );

        Test.stopTest();

        // Despite what the Salesforce docs say, at this time the Reports.EvaluatedCondition object
        // cannot be constructed; always get error that constructor not defined.
        // Instead, we use a trick to deserialize json into an apex object.

        List<Map<String, Object>> evaluatedConditionsAsObjectList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'aggregateName' => 'RecordCount',
                'aggregateLabel' => 'Record Count',
                'compareTo' => Double.valueOf( 0 ),
                'value' => Double.valueOf( 1 ),
                'operator' => Reports.EvaluatedConditionOperator.GREATER_THAN
            }
        };

        List<Reports.EvaluatedCondition> evaluatedConditions = (List<Reports.EvaluatedCondition>) JSON.deserialize( JSON.serialize( evaluatedConditionsAsObjectList ), List<Reports.EvaluatedCondition>.class );

        Reports.NotificationActionContext context = new Reports.NotificationActionContext(
            reportInstance, new Reports.ThresholdInformation( evaluatedConditions )
        );

        // now we're to the part we actually want to test
        // however, we can't have it be within the Test.startTest() / Test.stopTest()
        // because we already used that above to generate the async report instance.
        // So bear with me here, the Reports API isn't the nicest thing to test with.

        AddCampaignMembersByReportAction action = new AddCampaignMembersByReportAction();
        action.execute( context );

    }

}