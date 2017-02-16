/**
 * Developed by Doug Ayers (douglascayers.com)
 * https://github.com/DouglasCAyers/sfdc-add-campaign-members-by-report
 */
public with sharing class CampaignReportSettingsListController {

    public List<SettingWrapper> settingWrappers { get; private set; }

    public CampaignReportSettingsListController() {

        this.settingWrappers = buildSettingWrappers();

        Map<String, String> params = ApexPages.currentPage().getParameters();

        if ( params.get( 'save_success' ) == 'true' ) {
            ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.CONFIRM, 'Save successful!' ) );
        }

    }

    private List<SettingWrapper> buildSettingWrappers() {

        List<SettingWrapper> wrappers = new List<SettingWrapper>();

        Map<String, AddCampaignMembersByReportSetting__c> settingsMap = AddCampaignMembersByReportSetting__c.getAll();

        if ( settingsMap.size() > 0 ) {

            Set<ID> reportIds = new Set<ID>();
            Set<ID> campaignIds = new Set<ID>();

            for ( AddCampaignMembersByReportSetting__c setting : settingsMap.values() ) {
                reportIds.add( setting.name );
                campaignIds.add( setting.campaign_id__c );
            }

            Map<ID, Report> reportsMap = new Map<ID, Report>([
                SELECT
                    id, name
                FROM
                    Report
                WHERE
                    id IN :reportIds
            ]);

            Map<ID, Campaign> campaignsMap = new Map<ID, Campaign>([
                SELECT
                    id, name
                FROM
                    Campaign
                WHERE
                    id IN :campaignIds
            ]);

            for ( AddCampaignMembersByReportSetting__c setting : settingsMap.values() ) {

                wrappers.add( new SettingWrapper(
                    setting,
                    reportsMap.get( setting.name ),
                    campaignsMap.get( setting.campaign_id__c )
                ));

            }

        }

        wrappers.sort();

        return wrappers;
    }

    public class SettingWrapper implements Comparable {

        public AddCampaignMembersByReportSetting__c setting { get; set; }

        public Report report { get; set; }

        public Campaign campaign { get; set; }

        public SettingWrapper( AddCampaignMembersByReportSetting__c setting, Report report, Campaign campaign ) {
            this.setting = setting;
            this.report = report;
            this.campaign = campaign;
        }

        public Integer compareTo( Object other ) {

            SettingWrapper otherWrapper = (SettingWrapper) other;

            return this.report.name.compareTo( otherWrapper.report.name );
        }

    }

}