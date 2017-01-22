/**
 * Developed by Doug Ayers (douglascayers.com)
 * https://github.com/DouglasCAyers/sfdc-add-campaign-members-by-report
 */
public with sharing class AddCampaignMembersByReportAction implements Reports.NotificationAction {

    public void execute( Reports.NotificationActionContext context ) {

        System.debug( 'AddCampaignMembersByReportAction.execute: ' + context );

        Database.executeBatch( new AddCampaignMembersByReportBatchable( context.getReportInstance().getReportId() ) );

    }

}