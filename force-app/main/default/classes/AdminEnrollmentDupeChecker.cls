global with sharing class AdminEnrollmentDupeChecker implements Database.Batchable<SObject> 
{
    String query;

    global AdminEnrollmentDupeChecker() 
    {
        /*query = 'SELECT Id, Name, Warranty_Number__c '+
                'FROM Enrollment__c '+
                'WHERE Warranty_Number__c = null';*/
        query = 'SELECT Id, Name, Warranty_Number__c, Date_Ordered__c FROM Enrollment__c where Name = \'10338950\' order by Name, Date_Ordered__c DESC';
    }

    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Enrollment__c> scope) 
    {
        Integer iSize = scope.size();
        Integer i = 0;
        
        Map<Id, Enrollment__c> mapEnrollments = new Map<Id, Enrollment__c>();
        mapEnrollments.putAll(scope);

        while(i < iSize)
        {
            Enrollment__c enr = scope[i];
            enr.Warranty_Number__c = enr.Name;
            SYSTEM.DEBUG('++++ while loop: date -- ' + enr.Date_Ordered__c);
            i++;
        }

        List<Database.SaveResult> updateResults = Database.update(scope, false);
        Map<Integer, Enrollment__c> mapIndexBasedEnrollments = new Map<Integer, Enrollment__c>();

        List<Enrollment__c> listRedo = new List<Enrollment__c>();
        List<Enrollment__c> listDupes = new List<Enrollment__c>();

        for(Integer j=0; j<updateResults.size(); j++)
        {
            mapIndexBasedEnrollments.put(j, scope.get(j));

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
                    Enrollment__c originalENR = mapEnrollments.get( strOriginalWarrantyID );

                    system.debug('+++++ originalENR: ' + originalENR.Date_Ordered__c);
                    system.debug('+++++ failedENR: '+ failedENR.Date_Ordered__c);

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
                }
                
            }

        } // for(Integer j=0; j<updateResults.size(); j++)

        if(listDupes.size() > 0)    update listDupes;

        if(listRedo.size() > 0) update listRedo;
    }

    global void finish(Database.BatchableContext BC) 
    {

    }
}
