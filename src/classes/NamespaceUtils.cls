/**
 * Developed by Doug Ayers (douglascayers.com)
 * https://github.com/DouglasCAyers/sfdc-add-campaign-members-by-report
 */
public with sharing class NamespaceUtils {

    public static String getQualifiedPageName( String name ) {

        String prefix = NamespaceSettings__c.getOrgDefaults().barPrefix__c;

        return ( String.isBlank( prefix ) ? name : prefix + name );
    }

}