/**
 * Developed by Doug Ayers (douglascayers.com)
 * https://github.com/DouglasCAyers/sfdc-add-campaign-members-by-report
 */
public with sharing class AddCampaignMembersInstallHandler implements InstallHandler {

    public void onInstall( InstallContext context ) {

        // http://salesforce.stackexchange.com/questions/28974/determining-namespace-prefix-in-javascript-and-apex

        NamespaceSettings__c setting = NamespaceSettings__c.getOrgDefaults();

        String prefix = AddCampaignMembersInstallHandler.class.getName().substringBefore( 'AddCampaignMembersInstallHandler' ).substringBefore( '.' );

        if ( String.isNotBlank( prefix ) ) {
            setting.rawPrefix__c = prefix;
            setting.dotPrefix__c = prefix + '.';
            setting.barPrefix__c = prefix + '__';
        }

        upsert setting;

        System.debug( setting );

    }

}