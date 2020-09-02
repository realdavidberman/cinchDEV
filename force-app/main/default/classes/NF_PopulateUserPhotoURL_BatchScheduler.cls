/*
	Name: NF_PopulateUserPhotoURL_BatchScheduler
	Description: This is a scheduler class for NF_PopulateUserPhotoURL_Batch Batch Apex Class.
	Test Class: NF_PopulateUserPhotoURL_BatchTest
*/

global class NF_PopulateUserPhotoURL_BatchScheduler implements Schedulable {
   
   global void execute(SchedulableContext sc) {
      
      try{
          String profileName = '';
          
          if(Label.ProfileNameForPhotoURL != NULL && Label.ProfileNameForPhotoURL != 'NA'){
              profileName = Label.ProfileNameForPhotoURL.trim();
          }
          Database.executeBatch(new NF_PopulateUserPhotoURL_Batch(profileName));
          
      } catch(Exception ex){}
   }
}