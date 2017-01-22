/**
 * Developed by Doug Ayers (douglascayers.com)
 * https://github.com/DouglasCAyers/sfdc-add-campaign-members-by-report
 */
public with sharing class AddCampaignMembersByReportBatchable implements Database.Batchable<ID>, Database.Stateful {

    private ID reportId;
    private ID campaignId;
    private String campaignMemberStatus;

    // The report service paginates through all the records in the report
    // by making multiple invocations, this gets around the 2,000 record limit in Analytics API.
    // To do this it sorts the report by a column, ideally with unique values, and applies a filter
    // to get the next round of records greater than the last value seen in the previous iteration.
    // These variables are the column label and name in the report to use for this sorting purpose.
    // And for our adding campaign members purpose, should be a Contact ID or Lead ID column.
    private String columnLabel;
    private String columnName;

    // ----------------------------------------------------

    public AddCampaignMembersByReportBatchable( ID reportId ) {

        System.debug( 'AddCampaignMembersByReportBatchable.init' );

        // to avoid having to check 15 and 18 character ids, the custom setting name is supposed to be the 15 character id for the report
        AddCampaignMembersByReportSetting__c setting = AddCampaignMembersByReportSetting__c.getValues( String.valueOf( reportId ).left( 15 ) );

        if ( setting == null ) {
            throw new AddCampaignMembersByReportException( 'Missing custom setting AddCampaignMembersByReportSetting__c record with name "' + reportId + '"' );
        }

        Reports.ReportExtendedMetadata metadata = Reports.ReportManager.describeReport( reportId ).getReportExtendedMetadata();
        Map<String, String> columnLabelsToNamesMap = getIdColumnNamesByLabelsMap( metadata );

        if ( columnLabelsToNamesMap == null ) {
            throw new AddCampaignMembersByReportException( 'Report with id "' + reportId + '" is missing columns that reference record ids like Contact.Id or Lead.Id' );
        }

        String columnName = columnLabelsToNamesMap.get( setting.report_contact_or_lead_id_column_label__c );

        if ( String.isBlank( columnName ) ) {
            throw new AddCampaignMembersByReportException( 'Report with id "' + reportId + '" is missing expected column label "' + setting.report_contact_or_lead_id_column_label__c + '" that references a record id like Contact.Id or Lead.Id' );
        }

        this.reportId = reportId;
        this.campaignId = setting.campaign_id__c;
        this.campaignMemberStatus = setting.campaign_member_added_status__c;
        this.columnLabel = setting.report_contact_or_lead_id_column_label__c;
        this.columnName = columnName;

        System.debug( 'reportId=' + this.reportId );
        System.debug( 'campaignId=' + this.campaignId );
        System.debug( 'campaignMemberStatus=' + this.campaignMemberStatus );
        System.debug( 'columnLabel=' + this.columnLabel );
        System.debug( 'columnName=' + this.columnName );

    }

    // ----------------------------------------------------

    public Iterable<ID> start( Database.BatchableContext context ) {

        System.debug( 'AddCampaignMembersByReportBatchable.start: ' + context );

        Iterable<Id> reportRowIdIterable = new NPSP_ReportService.ReportRowIdIterableIterator( this.reportId, this.columnName );

        return (Iterable<ID>) reportRowIdIterable;
    }

    public void execute( Database.BatchableContext context, List<ID> recordIds ) {

        System.debug( 'AddCampaignMembersByReportBatchable.execute: ' + context );

        new AddCampaignMembersByReportService().addMembersToCampaign( recordIds, this.campaignId, this.campaignMemberStatus );

    }

    public void finish( Database.BatchableContext context ) {

        System.debug( 'AddCampaignMembersByReportBatchable.finish: ' + context );

    }

    // ----------------------------------------------------

    private Map<String, String> getIdColumnNamesByLabelsMap( Reports.ReportExtendedMetadata metadata ) {

        System.debug( 'getting id column names by labels map' );
        System.debug( metadata );

        Map<String, Reports.DetailColumn> reportColumns = metadata.getDetailColumnInfo();

        System.debug( reportColumns );

        Map<String, String> columnLabelsToNamesMap = new Map<String, String>();

        for ( Reports.DetailColumn column : reportColumns.values() ) {
            if ( Reports.ColumnDataType.ID_DATA == column.getDataType() ) {
                columnLabelsToNamesMap.put(
                    column.getLabel(),
                    column.getName()
                );
            }
        }

        System.debug( columnLabelsToNamesMap );

        return columnLabelsToNamesMap;
    }

    public class AddCampaignMembersByReportException extends Exception {}

}