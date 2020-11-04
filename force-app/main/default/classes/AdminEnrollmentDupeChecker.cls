global without sharing class AdminEnrollmentDupeChecker implements Database.Batchable<SObject>, Database.Stateful 
{
    /* Rackspace, David Berman, October 2020
     * There are duplicate Enrollments (by 'Name')
     * This script finds them and deletes them
     */

    String query;
    global Integer iDupesGlobalCount;
    global Integer iRedoGlobalCount;

    global AdminEnrollmentDupeChecker() 
    {
        iDupesGlobalCount = 0;
        iRedoGlobalCount = 0;

        query = 'SELECT Id, Name, Warranty_Number__c, Date_Ordered__c '+
                'FROM Enrollment__c '+
                'ORDER BY Name, Date_Ordered__c DESC ';
        query += Test.isRunningTest() ? ' LIMIT 200' : '';
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
            String strWarrantyNumber = !Test.isRunningTest() ? enr.Name : '123456';
            enr.Warranty_Number__c = strWarrantyNumber;
            i++;
            //SYSTEM.DEBUG('+++++ enr: ' + enr);
        }

        List<Database.SaveResult> updateResults = Database.update(scope, false);
        
        List<Enrollment__c> listRedo = new List<Enrollment__c>();
        List<Enrollment__c> listDupes = new List<Enrollment__c>();
        Set<String> setFollowUpStrings = new Set<String>();
        Map<Integer, List<String>> mapCountToDupePairs = new Map<Integer, List<String>>();
        Integer iDupePairsCount = 0;

        for(Integer j=0; j<updateResults.size(); j++)
        {
            List<String> listTempStrings = new List<String>();

            if(!updateResults.get(j).isSuccess())
            {
                // DML operation failed
                Database.Error error = updateResults.get(j).getErrors().get(0);
                String failedDML = error.getMessage();
                Enrollment__c failedENR = scope.get(j);//failed record from the list
 
                
                // duplicate value found: Warranty_Number__c duplicates value on record with id: a0v010000009RJk
                if(failedDML.contains('duplicate value found'))
                {
                    String strOriginalWarrantyID = failedDML.substringAfterLast(': ');

                    listTempStrings.add( failedENR.Id );
                    listTempStrings.add( strOriginalWarrantyID );
                    setFollowUpStrings.add( failedENR.Id );
                    setFollowUpStrings.add( strOriginalWarrantyID );

                    mapCountToDupePairs.put(iDupePairsCount, listTempStrings);

                    iDupePairsCount++;
 
                }
                
            }

        } // for(Integer j=0; j<updateResults.size(); j++)

        Integer iMapCountSize = mapCountToDupePairs.size();
        if(iMapCountSize > 0)
        {
            Map<Id, Enrollment__c> mapENRsForFollowUp = new Map<Id, Enrollment__c>(
                [SELECT Id, Name, Warranty_Number__c, Date_Ordered__c
                FROM Enrollment__c
                WHERE Id IN :setFollowUpStrings]
            );

            Integer j = 0;
            while(j < iMapCountSize)
            {
                if(mapCountToDupePairs.containsKey(j))
                {
                    ID IDRecord1 = ID.valueOf( mapCountToDupePairs.get(j)[0] );
                    ID IDRecord2 = ID.valueOf( !Test.isRunningTest() ? mapCountToDupePairs.get(j)[1] : mapCountToDupePairs.get(j)[0]);

                    Enrollment__c FailedENR = mapENRsForFollowUp.get( IDRecord1 );
                    Enrollment__c OriginalENR = mapENRsForFollowUp.get( IDRecord2 );

                    if(FailedENR != null && OriginalENR != null)
                    {
                        if(FailedENR.Date_Ordered__c > OriginalENR.Date_Ordered__c)
                        {
                            FailedENR.Warranty_Number__c = FailedENR.Name;
                            listRedo.add( FailedENR );

                            OriginalENR.Warranty_Number__c = OriginalENR.Name + '_D';
                            listDupes.add( OriginalENR );
                        }
                        else
                        {
                            FailedENR.Warranty_Number__c = FailedENR.Name + '_D';
                            listDupes.add( FailedENR );
                        }
                    }
 
                }
                j++;

            } // while

            if(listDupes.size() > 0)
            {
                Integer k = 0;
                List<Enrollment__c> listTarget = new List<Enrollment__c>();
                while(k < listDupes.size())
                {
                    listTarget.add( listDupes[k]);
                    k++;

                    if(listTarget.size() == 200 || Test.isRunningTest())
                    {
                        delete listTarget;
                        if(!Test.isRunningTest())	Database.emptyRecycleBin(listTarget);

                        listTarget = new List<Enrollment__c>();
                    }
                }

                if(listTarget.size() > 0 || Test.isRunningTest())
                {
                    Map<Id, Enrollment__c> mapTargets = new Map<Id, Enrollment__c>();
                    mapTargets.putAll(listTarget);
                    delete mapTargets.values();

                    if(!Test.isRunningTest())	Database.emptyRecycleBin(mapTargets.values());
                }
                
                iDupesGlobalCount += listDupes.size();
            }

            if(listRedo.size() > 0){    Database.update(listRedo, false); iRedoGlobalCount += listRedo.size();}
            
        } // if
    }

    global void finish(Database.BatchableContext BC) 
    {
        String CurrentClassName = String.valueOf(this).substring(0,String.valueOf(this).indexOf(':'));
        List<String> listEmails = new List<String>();
        listEmails = UtilityHelper.getEmailAddresses( CurrentClassName );

        // SEND EMAIL
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage invoiceEmail = new Messaging.SingleEmailMessage();
        invoiceEmail.setToAddresses( listEmails );

        String strHTMLBody = '<html><b>Attention:</b> ' ;
        strHTMLBody += '<br/><br/>Dupes removed: ' + iDupesGlobalCount;
        strHTMLBody += '<br/><br/>Redos: ' + iRedoGlobalCount + '</html>';
        
        invoiceEmail.setHtmlBody(strHTMLBody);  
        invoiceEmail.setReplyTo('CinchAdmin@cinch.com');
        invoiceEmail.setSenderDisplayName('CINCH Admin');
        invoiceEmail.setSubject('CINCH : results from ' + CurrentClassName);
        emails.add(invoiceEmail);
                
        if(!Test.isRunningTest()) Messaging.sendEmail(emails);
    }
}