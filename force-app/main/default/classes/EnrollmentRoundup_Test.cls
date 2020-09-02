@isTest
private class EnrollmentRoundup_Test 
{
    @TestSetup
	static void setupTestData()
    {
        Account acc = new Account(Name = Label.Account_Enrollment_CCMID_Not_Found_TEST );
        insert acc;
        
        Contact con = new Contact(LastName = Label.Contact_Enrollment_CCMID_Not_Found_for_TEST , AccountId = acc.Id);
        insert con;    
    }
 
    
    static TestMethod void testBatchDefaultAgentAndAgency()
    {
                
        Enrollment__c Enr = new Enrollment__c();
        Enr.Status__c = 'New';
        Enr.Agency_Office__c = 'Test Office';
        Enr.Agent_Address__c = 'Test Street 1';
        Enr.CCMID_of_Agency__c = 'Agency1000';
        Enr.Agent_Zip_Code__c = '99999';
        Enr.Agent_First_Name__c = 'JOHN';
        Enr.Agent_Last_Name__c = 'DOE';
        Enr.CCMID_of_Agent__c = 'Agent8000';
        Enr.Agency__c = [SELECT ID FROM Account WHERE Name = :Label.Account_Enrollment_CCMID_Not_Found_TEST LIMIT 1].Id;
        Enr.Agent__c = [SELECT ID FROM Contact WHERE LastName = :Label.Contact_Enrollment_CCMID_Not_Found_for_TEST LIMIT 1].Id;
        insert Enr;
        
        Test.startTest();
        EnrollmentRoundup batch = new EnrollmentRoundup();
        Database.executeBatch(batch, 1);
        Test.stopTest();
        
    }
 
    
    public static String CRON_EXP = '0 0 0 15 3 ? 2022';

    static testmethod void testSchedulable()
    {
        Test.startTest();

        //Schedule the test job
        String jobId = System.schedule('ScheduleApexClassTest', CRON_EXP, 
                new EnrollmentRoundup());
        
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
}