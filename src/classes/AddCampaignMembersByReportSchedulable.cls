/**
 * Developed by Doug Ayers (douglascayers.com)
 * https://github.com/DouglasCAyers/sfdc-add-campaign-members-by-report
 */
global with sharing class AddCampaignMembersByReportSchedulable implements Schedulable {

    private Integer batchSize { get; set; }

    global AddCampaignMembersByReportSchedulable() {
        this( 200 );
    }

    global AddCampaignMembersByReportSchedulable( Integer batchSize ) {
        this.batchSize = batchSize;
    }

    global void execute( SchedulableContext context ) {

        System.debug( 'AddCampaignMembersByReportSchedulable.execute: ' + context );

        for ( AddCampaignMembersByReportSetting__c setting : AddCampaignMembersByReportSetting__c.getAll().values() ) {

            System.debug( setting );

            Database.executeBatch( new AddCampaignMembersByReportBatchable( setting.name ), this.batchSize );

        }

    }

}