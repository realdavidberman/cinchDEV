global with sharing class AdminEnrollmentDupeChecker implements Database.Batchable<SObject>, Database.Stateful 
{
    String query;
    global Set<String> setEnrollmentIDs;

    global AdminEnrollmentDupeChecker() 
    {
        setEnrollmentIDs = new Set<String>();
        /*query = 'SELECT Id, Name, Warranty_Number__c '+
                'FROM Enrollment__c '+
                'WHERE Warranty_Number__c = null';*/
        query = 'SELECT Id, Name, Warranty_Number__c, Date_Ordered__c FROM Enrollment__c  order by Name, Date_Ordered__c DESC';
    }

    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Enrollment__c> scope) 
    {
        Integer iSize = scope.size();
        Integer i = 0;
        
        while(i < iSize)
        {
            Enrollment__c enr = scope[i];
            enr.Warranty_Number__c = enr.Name;
            i++;
        }

        List<Database.SaveResult> updateResults = Database.update(scope, false);
        
        List<Enrollment__c> listRedo = new List<Enrollment__c>();
        List<Enrollment__c> listDupes = new List<Enrollment__c>();

        for(Integer j=0; j<updateResults.size(); j++)
        {
            if(!updateResults.get(j).isSuccess())
            {
                // DML operation failed
                Database.Error error = updateResults.get(j).getErrors().get(0);
                String failedDML = error.getMessage();
                Enrollment__c failedENR = scope.get(j);//failed record from the list
                // duplicate value found: Warranty_Number__c duplicates value on record with id: a0v010000009RJk
                if(failedDML.contains('duplicate value found: Warranty_Number__c'))
                {
                    String strOriginalWarrantyID = failedDML.substringAfterLast(': ');

                    setEnrollmentIDs.add(failedENR.Id);
                    setEnrollmentIDs.add( strOriginalWarrantyID );
                    /*Enrollment__c originalENR = mapEnrollments.get( strOriginalWarrantyID );

                    if(failedENR.Date_Ordered__c > originalENR.Date_Ordered__c)
                    {
                        failedENR.Warranty_Number__c = failedENR.Name;
                        listRedo.add( failedENR );

                        originalENR.Warranty_Number__c = originalENR.Name + '_D';
                        listDupes.add( originalENR );
                    }
                    else
                    {
                        failedENR.Warranty_Number__c = failedENR.Name + '_D';
                        listDupes.add( failedENR );
                    }
                    */
                }
                
            }

        } // for(Integer j=0; j<updateResults.size(); j++)

        //if(listDupes.size() > 0)    update listDupes;

        //if(listRedo.size() > 0) update listRedo;
    }

    global void finish(Database.BatchableContext BC) 
    {
        SYSTEM.DEBUG('+++++ setEnrollmentIDs: ' + setEnrollmentIDs.SIZE());

        // SEND EMAIL
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage invoiceEmail = new Messaging.SingleEmailMessage();
        invoiceEmail.setToAddresses(new List<String>{'david.berman@rackspace.com'});
        String strHTMLBody = '<html><b>Attention:</b> ' + setEnrollmentIDs.SIZE() + '</html>';
        
        invoiceEmail.setHtmlBody(strHTMLBody);  
        invoiceEmail.setReplyTo('david@relationedge.com');
        invoiceEmail.setSenderDisplayName('CINCH count');
        invoiceEmail.setSubject('CINCH number of affected records');
        emails.add(invoiceEmail);
                
            
        if(!Test.isRunningTest()) Messaging.sendEmail(emails);
    }
}
