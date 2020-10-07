@isTest
private class UtilityHelper_Test 
{
    static TestMethod void testit() 
    {
        Integer i = UtilityHelper.getRandomNumber(10);
        String sNow = UtilityHelper.getNowDateTimeString();
        List<String> listEmails = new List<String>();
        listEmails = UtilityHelper.getEmailAddresses('AdminEnrollmentDupeChecker');
    }
}