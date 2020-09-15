@isTest
private  class AgentCCMIDConsolidation_Test 
{
   static TestMethod void testThis()
   {
       Test.startTest();
        AgentCCMIDConsolidation batchable = new AgentCCMIDConsolidation();
        Database.executeBatch(batchable);
        Test.stopTest();
        
        Contact con = [SELECT Id, CCMID__c FROM Contact LIMIT 1];
        SYSTEM.assertEquals(con.CCMID__c , '142434064');
   }

   static TestMethod void testThisWithQuery() 
   {
        String query = 'SELECT Id, CCMID__c, Previous_CCMID__c FROM Contact ';

        Test.startTest();
        AgentCCMIDConsolidation batchable = new AgentCCMIDConsolidation(query);
        Database.executeBatch(batchable);
        Test.stopTest();
        
        Contact con = [SELECT Id, CCMID__c FROM Contact LIMIT 1];
        SYSTEM.assertEquals(con.CCMID__c , '142434064');
   }

   public static String CRON_EXP = '0 0 0 15 3 ? 2022';

    static testmethod void testSchedulable()
    {
        Test.startTest();

        //Schedule the test job
        String jobId = System.schedule('ScheduleApexClassTest', CRON_EXP, 
                new AgentCCMIDConsolidation());
        
        // Get the info from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                         FROM CronTrigger WHERE Id =:jobId];
                         
        // Verify the expressions are the same
        System.assertEquals(CRON_EXP, ct.CronExpression);
        
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
        
        // Verify the next time the job will run
        System.assertEquals('2022-03-15 00:00:00', String.valueOf(ct.NextFireTime));

        Test.stopTest();
        
        // Verify the job has now run
        System.assertNotEquals(1, ct.TimesTriggered);
    }

   
   @TestSetup
   static void makeData()
   {
       Account testAgency = new Account();
       testAgency.Name = 'Test Agency';
       testAgency.CCMID__c = '141777791';
       testAgency.Account_Status__c = 'Prospect';
       testAgency.ShippingStreet = '3290 N RIDGE RD #150';
       testAgency.ShippingPostalCode = '21043';
       insert testAgency;

       Contact testAgent = new Contact();
       testAgent.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Contacts for HMS').getRecordTypeId();
       testAgent.FirstName = 'ADRIENNE';
       testAgent.LastName = 'WAGNER';
       testAgent.Email = 'adrienne.wagner@roadrunner.com';
       testAgent.CCMID__c = '142437000';
       testAgent.AccountId = testAgency.Id;
       insert testAgent;

       Enrollment__c ENROlder = new Enrollment__c();
       ENROlder.Name = '11569457';
       ENROlder.Date_Ordered__c = SYSTEM.TODAY()-10;
       ENROlder.Warranty_Type__c = 'BCW';
       ENROlder.Base_year_zero_contract_value__c = 489.0;
       ENROlder.CCMID_of_Agency__c = testAgency.CCMID__c;
       ENROlder.Agent_Address__c = '3802 STATE RT. 31';
       ENROlder.Agent_Zip_Code__c = '15628';
       ENROlder.Agency_Office__c = 'BHHS THE PREFERRED REALTY - LAUREL HIGHLANDS BHHS';
       ENROlder.CCMID_of_Agent__c = '142437000';
       ENROlder.Agent_First_Name__c = 'ADRIENNE';
       ENROlder.Agent_Last_Name__c = 'WAGNER';
       ENROlder.Status__c = 'Success';
       ENROlder.Agent__c = testAgent.Id;
       insert ENROlder;

       Enrollment__c ENRNewer = new Enrollment__c();
       ENRNewer.Name = '11569458';
       ENRNewer.Date_Ordered__c = SYSTEM.TODAY()-5;
       ENRNewer.Warranty_Type__c = 'BCW';
       ENRNewer.Base_year_zero_contract_value__c = 489.0;
       ENRNewer.CCMID_of_Agency__c = testAgency.CCMID__c;
       ENRNewer.Agent_Address__c = '3802 STATE RT. 31';
       ENRNewer.Agent_Zip_Code__c = '15628';
       ENRNewer.Agency_Office__c = 'BHHS THE PREFERRED REALTY - LAUREL HIGHLANDS BHHS';
       ENRNewer.CCMID_of_Agent__c = '142434064';
       ENRNewer.Agent_First_Name__c = 'ADRIENNE';
       ENRNewer.Agent_Last_Name__c = 'WAGNER';
       ENRNewer.Status__c = 'Success';
       ENRNewer.Agent__c = testAgent.Id;
       insert ENRNewer;

   }
}
