/*
	Name: NF_PopulateUserPhotoURL_BatchTest
	Description: Test Class.
	Classes Covered: NF_PopulateUserPhotoURL_BatchScheduler
                     NF_PopulateUserPhotoURL_Batch
                     NF_UserUtil
*/

@isTest
private class NF_PopulateUserPhotoURL_BatchTest {

    @testSetup static void setupUser() {
        
        List<User> userList = new List<User>();
        
        Profile pf= [SELECT Id FROM Profile WHERE Name = 'System Administrator']; 
        
        String orgId = UserInfo.getOrganizationId(); 
        
        for(Integer i=0; i<2; i++){
            String dateString=String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','') ;
            Integer randomId=Integer.valueOf(Math.rint(Math.random()*1000000)); 
            String uniqueName=orgId+dateString+RandomId+i; 
            userList.add(new User(firstname = 'ABC-'+i, 
                             lastName = 'XYZ', 
                             email = uniqueName + '@test'+ orgId + '.org', 
                             Username = uniqueName + '@test' + orgId + '.org', 
                             EmailEncodingKey = 'ISO-8859-1', 
                             Alias = uniqueName.substring(18, 23), 
                             TimeZoneSidKey = 'America/Los_Angeles', 
                             LocaleSidKey = 'en_US', 
                             LanguageLocaleKey = 'en_US', 
                             ProfileId = pf.Id
                            )); 
        }
        
        if(!userList.isEmpty()){
            insert userList;
        }
    }
    
    static testMethod void testUpdateUserPhotoURL(){
    
        List<User> userList = [SELECT Id, Name, UserPhotoURL__c FROM User LIMIT 5];
        System.assertEquals(true,userList.size()>0);
        String CRON_EXP = '0 0 0 15 3 ? *';
        Test.startTest();
            String jobId = System.schedule('PopulateUserPhotoScheduler',  CRON_EXP, new NF_PopulateUserPhotoURL_BatchScheduler());
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
            System.assertEquals(CRON_EXP, ct.CronExpression);
        Test.stopTest();
        
    }

    static testMethod void testUpdateUserPhotoURL_Negative(){
        
        List<User> userList = new List<User>();

        Profile pf= [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        String orgId = UserInfo.getOrganizationId(); 
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','') ;
        Integer randomId = Integer.valueOf(Math.rint(Math.random()*1000000)); 
        String uniqueName = orgId+dateString+RandomId; 

        userList.add(new User(firstname = 'ABC-', 
                            lastName = 'XYZ', 
                            email = uniqueName + '@test'+ orgId + '.org', 
                            Username = uniqueName + '@test' + orgId + '.org', 
                            EmailEncodingKey = 'ISO-8859-1', 
                            Alias = uniqueName.substring(18, 23), 
                            TimeZoneSidKey = 'America/Los_Angeles', 
                            LocaleSidKey = 'en_US', 
                            LanguageLocaleKey = 'en_US', 
                            ProfileId = pf.Id
                        )); 
        System.assertEquals(true,userList.size()>0);
        Test.startTest();
            NF_UserUtil.updateUserPhotoURL(userList);
        Test.stopTest();
        
    }

}