/**
 * Developed by Doug Ayers (douglascayers.com)
 * https://github.com/DouglasCAyers/sfdc-add-campaign-members-by-report
 */
public with sharing class AddCampaignMembersByReportSchedulable implements Schedulable {

    public void execute( SchedulableContext context ) {

        System.debug( 'AddCampaignMembersByReportSchedulable.execute: ' + context );

        for ( AddCampaignMembersByReportSetting__c setting : AddCampaignMembersByReportSetting__c.getAll().values() ) {

            System.debug( setting );

            Database.executeBatch( new AddCampaignMembersByReportBatchable( setting.name ) );

        }

    }

}