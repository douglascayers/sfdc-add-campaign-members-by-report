/**
 * Developed by Doug Ayers (douglascayers.com)
 * https://github.com/DouglasCAyers/sfdc-add-campaign-members-by-report
 */
public with sharing class AddCampaignMembersByReportBatchable implements Database.Batchable<ID>, Database.Stateful {

    @TestVisible
    private ID reportId;

    @TestVisible
    private ID campaignId;

    @TestVisible
    private String campaignMemberStatus;

    // The report service paginates through all the records in the report
    // by making multiple invocations, this gets around the 2,000 record limit in Analytics API.
    // To do this it sorts the report by a column, ideally with unique values, and applies a filter
    // to get the next round of records greater than the last value seen in the previous iteration.
    // This is the column name in the report to use for this sorting purpose.
    // Note, this is not the Column Label which may change based on running user's language/locale settings.
    // And for our adding campaign members purpose, should be a Contact ID or Lead ID column.
    private String columnName;

    // ----------------------------------------------------

    public AddCampaignMembersByReportBatchable( ID reportId ) {

        try {

            System.debug( 'AddCampaignMembersByReportBatchable.init' );

            // to avoid having to check 15 and 18 character ids, the custom setting name is supposed to be the 15 character id for the report
            AddCampaignMembersByReportSetting__c setting = AddCampaignMembersByReportSetting__c.getValues( String.valueOf( reportId ).left( 15 ) );

            if ( setting == null ) {
                throw new AddCampaignMembersByReportException( 'Missing custom setting AddCampaignMembersByReportSetting__c record with name "' + reportId + '"' );
            }

            this.reportId = reportId;
            this.campaignId = setting.campaign_id__c;
            this.campaignMemberStatus = setting.campaign_member_added_status__c;
            this.columnName = setting.report_contact_or_lead_id_column_name__c;

            System.debug( 'reportId=' + this.reportId );
            System.debug( 'campaignId=' + this.campaignId );
            System.debug( 'campaignMemberStatus=' + this.campaignMemberStatus );
            System.debug( 'columnName=' + this.columnName );

            Reports.ReportExtendedMetadata metadata = Reports.ReportManager.describeReport( reportId ).getReportExtendedMetadata();
            Map<String, Reports.DetailColumn> reportColumnsMap = metadata.getDetailColumnInfo();

            System.debug( 'reportColumnsMap: ' + reportColumnsMap );

            if ( !reportColumnsMap.containsKey( columnName ) ) {
                throw new AddCampaignMembersByReportException( 'Report with id "' + reportId + '" is missing expected column "' + setting.report_contact_or_lead_id_column_label__c + '" that references a record id like Contact.Id or Lead.Id' );
            }

        } catch ( Exception e ) {

            AddCampaignMembersByReportLogger.log( e );

        }

    }

    // ----------------------------------------------------

    public Iterable<ID> start( Database.BatchableContext context ) {

        try {

            System.debug( 'AddCampaignMembersByReportBatchable.start: ' + context );

            Iterable<ID> reportRowIdIterable = new NPSP_ReportService.ReportRowIdIterableIterator( this.reportId, this.columnName );

            Iterator<ID> reportRowIdIterator = reportRowIdIterable.iterator();

            // when running test ensure at most one batch execution will run, otherwise send back the real iterable
            return (Iterable<ID>) ( ( Test.isRunningTest() && reportRowIdIterator.hasNext() ) ? new List<ID>{ reportRowIdIterator.next() } : reportRowIdIterable );

        } catch ( Exception e ) {

            AddCampaignMembersByReportLogger.log( context.getJobId(), e );

            return new EmptyIterator();

        }

    }

    public void execute( Database.BatchableContext context, List<ID> recordIds ) {

        SavePoint sp = Database.setSavePoint();

        try {

            System.debug( 'AddCampaignMembersByReportBatchable.execute: ' + context );

            new AddCampaignMembersByReportService().addMembersToCampaign( recordIds, this.campaignId, this.campaignMemberStatus );

        } catch ( Exception e ) {

            Database.rollback( sp );

            AddCampaignMembersByReportLogger.log( context.getJobId(), e );

        }

    }

    public void finish( Database.BatchableContext context ) {

        System.debug( 'AddCampaignMembersByReportBatchable.finish: ' + context );

        AddCampaignMembersByReportLogger.sendApexExceptionEmailIfAnyErrorsSince( context.getJobId() );

    }

    // ----------------------------------------------------

    public class AddCampaignMembersByReportException extends Exception {}

    @TestVisible
    private class EmptyIterator implements Iterator<ID>, Iterable<ID> {

        public Boolean hasNext() {
            return false;
        }

        public ID next() {
            return null;
        }

        public Iterator<ID> iterator() {
            return new EmptyIterator();
        }

    }

}