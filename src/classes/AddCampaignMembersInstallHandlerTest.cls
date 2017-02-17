/**
 * Developed by Doug Ayers (douglascayers.com)
 * https://github.com/DouglasCAyers/sfdc-add-campaign-members-by-report
 */
@isTest
private class AddCampaignMembersInstallHandlerTest {

    @isTest
    static void test_install() {

        NamespaceSettings__c settings = NamespaceSettings__c.getOrgDefaults();
        System.assertEquals( null, settings.id );

        AddCampaignMembersInstallHandler handler = new AddCampaignMembersInstallHandler();
        handler.testNamespace = 'foo';

        Test.startTest();

        Test.testInstall( handler, null );

        Test.stopTest();

        settings = NamespaceSettings__c.getOrgDefaults();
        System.assertNotEquals( null, settings.id );
        System.assertEquals( 'foo', settings.rawPrefix__c );
        System.assertEquals( 'foo.', settings.dotPrefix__c );
        System.assertEquals( 'foo__', settings.barPrefix__c );

    }

}