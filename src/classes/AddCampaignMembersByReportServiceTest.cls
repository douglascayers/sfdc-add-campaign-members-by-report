/**
 * Developed by Doug Ayers (douglascayers.com)
 * https://github.com/DouglasCAyers/sfdc-add-campaign-members-by-report
 */
@isTest
private class AddCampaignMembersByReportServiceTest {

    @isTest
    static void test_add_members() {

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

        List<ID> leadOrContactIds = new List<ID>{ cont.id, ld.id };

        System.assertEquals( 1, [ SELECT count() FROM CampaignMember WHERE campaignId = :camp.id AND leadOrContactId IN :leadOrContactIds ] );

        Test.startTest();

        new AddCampaignMembersByReportService().addMembersToCampaign( leadOrContactIds, camp.id, null );

        Test.stopTest();

        System.assertEquals( 2, [ SELECT count() FROM CampaignMember WHERE campaignId = :camp.id AND leadOrContactId IN :leadOrContactIds ] );

    }

}