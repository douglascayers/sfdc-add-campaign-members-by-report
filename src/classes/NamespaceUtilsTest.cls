/**
 * Developed by Doug Ayers (douglascayers.com)
 * https://github.com/DouglasCAyers/sfdc-add-campaign-members-by-report
 */
@isTest
private class NamespaceUtilsTest {

    @isTest
    static void test_get_qualified_page_name_without_namespace() {

        Test.startTest();

        String qualifiedName = NamespaceUtils.getQualifiedPageName( 'MyPage' );

        Test.stopTest();

        System.assertEquals( 'MyPage', qualifiedName );

    }

    @isTest
    static void test_get_qualified_page_name_with_namespace() {

        NamespaceSettings__c settings = NamespaceSettings__c.getOrgDefaults();
        settings.rawPrefix__c = 'foo';
        settings.dotPrefix__c = 'foo.';
        settings.barPrefix__c = 'foo__';

        upsert settings;

        Test.startTest();

        String qualifiedName = NamespaceUtils.getQualifiedPageName( 'MyPage' );

        Test.stopTest();

        System.assertEquals( 'foo__MyPage', qualifiedName );

    }

}