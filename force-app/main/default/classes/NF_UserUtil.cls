/*
	Name: NF_PopulateUserPhotoURL_BatchScheduler
	Description: This is an Utility class which makes use of ConnectApi to populate the UserPhotoURL__c field
				 on User record, used by HMS Profiles Users when sending Emails.
	Test Class: NF_PopulateUserPhotoURL_BatchTest
*/

public with sharing class NF_UserUtil {
	
	public static void updateUserPhotoURL(List<User> userList){
        
		try{
			if(!userList.isEmpty()){
				List<User> usersToUpdateList = new List<User>();
				
				for(User userRecord : userList){
					String userPhotoURL = '';
					if (!Test.isRunningTest()){
						ConnectApi.Photo ph =  ConnectApi.UserProfiles.getPhoto(null, userRecord.Id);
						userPhotoURL = ph.standardEmailPhotoUrl;
					}
					if(userRecord.UserPhotoURL__c != userPhotoURL){
						userRecord.UserPhotoURL__c = userPhotoURL;
						usersToUpdateList.add(userRecord);
					}
				}
				
				if(Schema.sObjectType.User.isUpdateable() && !usersToUpdateList.isEmpty()){
					Database.SaveResult[] srList = Database.update(usersToUpdateList, false);
				} 
			}
		} catch(Exception ex){}
    }
}