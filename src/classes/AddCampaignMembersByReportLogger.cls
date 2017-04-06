/**
 * Developed by Doug Ayers (douglascayers.com)
 * https://github.com/DouglasCAyers/sfdc-add-campaign-members-by-report
 */
public with sharing class AddCampaignMembersByReportLogger {

    /**
     * Designed to be called once when exception is caught.
     */
    public static void log( Exception e ) {

        System.debug( LoggingLevel.ERROR, 'error: ' + e.getMessage() + ' : ' + e.getStackTraceString() );

        Add_Campaign_Members_by_Report_Log__c log = new Add_Campaign_Members_by_Report_Log__c(
            summary__c = e.getMessage(),
            detail__c = e.getStackTraceString()
        );

        insert log;

    }

    /**
     * Designed to be called once when exception is caught
     * during a batch or queued job conversion.
     */
    public static void log( ID jobId, Exception e ) {

        System.debug( LoggingLevel.ERROR, 'jobId: ' + jobId + ', error: ' + e.getMessage() + ' : ' + e.getStackTraceString() );

        Add_Campaign_Members_by_Report_Log__c log = new Add_Campaign_Members_by_Report_Log__c(
            job_id__c = jobId,
            summary__c = e.getMessage(),
            detail__c = e.getStackTraceString()
        );

        insert log;

    }

    /**
     * Checks if any log records have been created since the job started.
     * If yes then sends an email to any Salesforce users configured for Apex Exception Email.
     */
    public static void sendApexExceptionEmailIfAnyErrorsSince( ID jobId ) {

        AsyncApexJob job = [ SELECT id, createdDate FROM AsyncApexJob WHERE id = :jobId ];

        sendApexExceptionEmailIfAnyErrorsSince( job.createdDate );

    }

    /**
     * Checks if any log records have been created since the given date/time.
     * If yes then sends an email to any Salesforce users configured for Apex Exception Email.
     */
    public static void sendApexExceptionEmailIfAnyErrorsSince( DateTime sinceDateTime ) {

        Integer count = [ SELECT count() FROM Add_Campaign_Members_by_Report_Log__c WHERE createdDate >= :sinceDateTime ];

        if ( count > 0 ) {

            List<ID> usersToNotify = new List<ID>();

            for ( ApexEmailNotification notif : [ SELECT userId FROM ApexEmailNotification WHERE userId != null LIMIT 100 ] ) {
                usersToNotify.add( notif.userId );
            }

            if ( usersToNotify.size() > 0 ) {

                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.toAddresses = usersToNotify;
                message.subject = 'Errors: Add Campaign Members by Report Logs';
                message.plainTextBody = 'Errors have occurred. Please review the log records for more details ' +
                                        URL.getSalesforceBaseURL().toExternalForm() + '/' + Add_Campaign_Members_by_Report_Log__c.sObjectType.getDescribe().getKeyPrefix();

                Messaging.sendEmail( new Messaging.SingleEmailMessage[] { message } );

            }

        }

    }

}