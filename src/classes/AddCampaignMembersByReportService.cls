/**
 * Developed by Doug Ayers (douglascayers.com)
 * https://github.com/DouglasCAyers/sfdc-add-campaign-members-by-report
 */
public with sharing class AddCampaignMembersByReportService {

    /**
     * Given a list of contact or lead ids, will add them to the campaign (if not already exist as members).
     * Optionally, you may specify the default campaign member status to use. If blank then none will be specified and Salesforce default will be used.
     * Returns the list of newly inserted campaign members, if any.
     */
    public static List<CampaignMember> addMembersToCampaign( List<ID> leadOrContactIds, ID campaignId, String campaignMemberStatus ) {

        System.debug( 'adding members to campaign: campaignId=' + campaignId + ', campaignMemberStatus=' + campaignMemberStatus + ', leadOrContactIds=' + leadOrContactIds );

        List<CampaignMember> existingMembers = new List<CampaignMember>([
            SELECT
                id, campaignId, leadOrContactId
            FROM
                CampaignMember
            WHERE
                campaignId = :campaignId
                AND
                leadOrContactId IN :leadOrContactIds
        ]);

        Set<ID> existingContactOrLeadIds = new Set<ID>();

        for ( CampaignMember member : existingMembers ) {
            existingContactOrLeadIds.add( member.leadOrContactId );
        }

        List<CampaignMember> membersToInsert = new List<CampaignMember>();

        for ( ID leadOrContactId : leadOrContactIds ) {

            Boolean isContactId = ( leadOrContactId.getSObjectType() == Contact.sObjectType );
            Boolean isLeadId    = ( leadOrContactId.getSObjectType() == Lead.sObjectType );

            if ( !existingContactOrLeadIds.contains( leadOrContactId ) ) {

                CampaignMember member = new CampaignMember(
                    campaignId = campaignId,
                    contactId = ( isContactId ) ? leadOrContactId : null,
                    leadId = ( isLeadId ) ? leadOrContactId : null,
                    status = campaignMemberStatus
                );

                membersToInsert.add( member );

                System.debug( 'campaign member to add: ' + member );

            } else {

                System.debug( 'campaign member already exists: campaignId=' + campaignId + ', leadOrContactId=' + leadOrContactId );

            }

        }

        if ( membersToInsert.size() > 0 ) {
            insert membersToInsert;
        }

        return membersToInsert;
    }

}