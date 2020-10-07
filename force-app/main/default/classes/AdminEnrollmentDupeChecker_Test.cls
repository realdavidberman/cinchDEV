@IsTest(seealldata=false)
private without sharing class AdminEnrollmentDupeChecker_Test 
{
    static TestMethod void testTheBatch()
    {
        Enrollment__c enc1 = new Enrollment__c();
        enc1.Warranty_Number__c = '123456';
        enc1.Date_Ordered__c = SYSTEM.TODAY();
        insert enc1;

        Enrollment__c enc2 = new Enrollment__c();
        enc2.Warranty_Number__c = '123457';
        enc2.Date_Ordered__c = SYSTEM.TODAY().addDays(-10);
        insert enc2;

        AdminEnrollmentDupeChecker aedc = new AdminEnrollmentDupeChecker();
        Test.startTest();
        Database.executeBatch(aedc);
        Test.stopTest();
    }
}