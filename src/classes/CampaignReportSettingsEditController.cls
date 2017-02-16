/**
 * Developed by Doug Ayers (douglascayers.com)
 * https://github.com/DouglasCAyers/sfdc-add-campaign-members-by-report
 */
public with sharing class CampaignReportSettingsEditController {

    private ApexPages.StandardController stdController { get; set; }

    public String selectedFolderId { get; set; }

    public String selectedReportId { get; set; }

    public String selectedReportColumnName { get; set; }

    public CampaignMember member { get; set; } // used by apex:inputField to select campaign and member status

    public CampaignReportSettingsEditController( ApexPages.StandardController stdController ) {

        this.stdController = stdController;

        this.member = new CampaignMember();

        if ( String.isNotBlank( stdController.getId() ) ) {

            AddCampaignMembersByReportSetting__c setting = [
                SELECT
                    id,
                    name,
                    campaign_id__c,
                    campaign_member_added_status__c,
                    report_contact_or_lead_id_column_label__c,
                    report_contact_or_lead_id_column_name__c
                FROM
                    AddCampaignMembersByReportSetting__c
                WHERE
                    id = :stdController.getId()
                LIMIT 1
            ];

            this.selectedReportColumnName = setting.report_contact_or_lead_id_column_name__c;

            List<Report> reportsList = new List<Report>([ SELECT id, ownerId, name FROM Report WHERE id = :setting.name LIMIT 1 ]);

            if ( reportsList.size() == 0 ) {

                ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, 'No report found with id: ' + setting.name + '. Please verify report exists and update this Custom Setting directly in Setup menu.' ) );

            } else {

                this.selectedReportId = reportsList[0].id;
                this.selectedFolderId = reportsList[0].ownerId;

                Reports.ReportExtendedMetadata metadata = Reports.ReportManager.describeReport( this.selectedReportId ).getReportExtendedMetadata();
                Map<String, Reports.DetailColumn> reportColumnsMap = metadata.getDetailColumnInfo();
                Reports.DetailColumn reportColumn = reportColumnsMap.get( this.selectedReportColumnName );

                if ( reportColumn == null ) {
                    ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, 'No report column found "' + setting.report_contact_or_lead_id_column_label__c + '" (' + setting.report_contact_or_lead_id_column_name__c + '). Please choose another report column that contains a Lead or Contact ID.' ) );
                }

            }

            List<Campaign> campaignsList = new List<Campaign>([ SELECT id, name FROM Campaign WHERE id = :setting.campaign_id__c LIMIT 1 ]);

            if ( campaignsList.size() == 0 ) {

                ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, 'No Campaign found with id: ' + setting.campaign_id__c + '. Please choose a new Campaign to use.' ) );

            } else {

                this.member.campaignId = campaignsList[0].id;
                this.member.status = setting.campaign_member_added_status__c;

            }

        }

    }

    public PageReference cancel() {
        return this.stdController.cancel();
    }

    public PageReference save() {

        PageReference page = null;

        SavePoint sp = Database.setSavePoint();

        try {

            // Validate Inputs

            Boolean hasError = false;

            if ( String.isBlank( member.campaignId ) ) {
                ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, 'Campaign is required.' ) );
                hasError = true;
            }

            if ( String.isBlank( this.selectedReportId ) ) {
                ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, 'Report is required.' ) );
                hasError = true;
            }

            if ( String.isBlank( this.selectedReportColumnName ) ) {
                ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, 'Report Column is required.' ) );
                hasError = true;
            }

            if ( !hasError ) {

                Reports.ReportExtendedMetadata metadata = Reports.ReportManager.describeReport( this.selectedReportId ).getReportExtendedMetadata();
                Map<String, Reports.DetailColumn> reportColumnsMap = metadata.getDetailColumnInfo();
                Reports.DetailColumn reportColumn = reportColumnsMap.get( this.selectedReportColumnName );

                AddCampaignMembersByReportSetting__c setting = new AddCampaignMembersByReportSetting__c(
                    id = this.stdController.getId(),
                    name = this.selectedReportId.left( 15 ),
                    campaign_id__c = String.valueOf( this.member.campaignId ).left( 15 ),
                    campaign_member_added_status__c = this.member.status,
                    report_contact_or_lead_id_column_label__c = reportColumn.getLabel(),
                    report_contact_or_lead_id_column_name__c = reportColumn.getName()
                );

                upsert setting;

                page = new PageReference( '/apex/CampaignReportSettingsListPage' );
                page.getParameters().put( 'save_success', 'true' );
                page.setRedirect( true );

            }

        } catch ( Exception e ) {

            Database.rollback( sp );

            logAndAddErrorMessages( e );

        }

        return page;
    }

    public List<SelectOption> getMemberStatusOptions() {

        List<SelectOption> options = new List<SelectOption>();

        if ( String.isNotBlank( this.member.campaignId ) ) {

            options.add( new SelectOption( '', '--Select--') );

            for ( CampaignMemberStatus status : [ SELECT id, label FROM CampaignMemberStatus WHERE campaignId = :this.member.campaignId ORDER BY sortOrder ] ) {
                options.add( new SelectOption( status.label, status.label ) );
            }

        } else {

            options.add( new SelectOption( '', '--Choose Campaign--') );

        }

        return options;
    }

    public List<SelectOption> getFolderOptions() {

        List<SelectOption> options = new List<SelectOption>();

        options.add( new SelectOption( '', '--Select--') );

        for ( Folder folder : [ SELECT id, name FROM Folder WHERE type = 'Report' AND developerName != null ORDER BY name ] ) {
            options.add( new SelectOption( folder.id, folder.name ) );
        }

        return options;
    }

    public List<SelectOption> getReportOptions() {

        List<SelectOption> options = new List<SelectOption>();

        if ( String.isNotBlank( this.selectedFolderId ) ) {

            options.add( new SelectOption( '', '--Select--') );

            for ( Report report : [ SELECT id, name FROM Report WHERE ownerId = :this.selectedFolderId ORDER BY name ] ) {
                options.add( new SelectOption( report.id, report.name ) );
            }

        } else {

            options.add( new SelectOption( '', '--Choose Folder--') );

        }

        return options;
    }

    public List<SelectOption> getReportColumnOptions() {

        List<SelectOption> options = new List<SelectOption>();

        if ( String.isNotBlank( this.selectedReportId ) ) {

            options.add( new SelectOption( '', '--Select--') );

            Reports.ReportExtendedMetadata metadata = Reports.ReportManager.describeReport( this.selectedReportId ).getReportExtendedMetadata();
            Map<String, Reports.DetailColumn> reportColumnsMap = metadata.getDetailColumnInfo();

            for ( Reports.DetailColumn column : reportColumnsMap.values() ) {
                options.add( new SelectOption( column.getName(), column.getLabel() ) );
            }

        } else {

            options.add( new SelectOption( '', '--Choose Report--') );

        }

        return options;
    }

    private void logAndAddErrorMessages( Exception e ) {

        System.debug( LoggingLevel.ERROR, e.getMessage() + ' : ' + e.getStackTraceString() );

        if ( e instanceof DmlException ) {

            for ( Integer i = 0; i < e.getNumDml(); i++ ) {
                ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, e.getDmlMessage( i ) ) );
            }

        } else {

            ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, e.getMessage() + ' : ' + e.getStackTraceString() ) );

        }

    }

    public class CampaignReportSettingsException extends Exception {}

}