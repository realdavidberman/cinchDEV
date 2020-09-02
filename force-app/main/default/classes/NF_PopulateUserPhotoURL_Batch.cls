/*
	Name: NF_PopulateUserPhotoURL_Batch
	Description: This Batch makes use of ConnectApi to populate the UserPhotoURL__c field
				 on User record, used by HMS Profiles Users when sending Emails.
	Test Class: NF_PopulateUserPhotoURL_BatchTest
*/

public class NF_PopulateUserPhotoURL_Batch implements Database.Batchable<sObject> {
	
	private String profileName = '';
	
	public NF_PopulateUserPhotoURL_Batch(String profName){
        profileName = profName;
	}
	
	public Database.QueryLocator start(Database.BatchableContext BC) {
		
		String query = 'SELECT Id, UserPhotoURL__c FROM User ';
        if(profileName != NULL && profileName != ''){
            query += ' WHERE Profile.Name =: profileName ';
        }
        query += ' ORDER BY Name';

		return Database.getQueryLocator(query);
	}

   	public void execute(Database.BatchableContext BC, List<sObject> scope) {
		try{
		   NF_UserUtil.updateUserPhotoURL(scope);
		} catch(Exception ex){} 
	}
	
	public void finish(Database.BatchableContext BC) {
		
	}
	
}