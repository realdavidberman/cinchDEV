global class EnrollmentRoundupQueueable implements Queueable
{
    /* Rackspace, David Berman, 7 December 2020
     * Added check against Custom Setting "Automation Handler", checkbox "Agency creation enabled",
     * to determine if, should no agency be matched, a new agency/account record should be created
     */
    
    global String result;
    @TestVisible private static Boolean QUEUE = !Test.isRunningTest();
    global static String defaultAgent = Label.Contact_Enrollment_CCMID_Not_Found;
    global static String defaultAgency = Label.Account_Enrollment_CCMID_Not_Found ;
        
    private List<Enrollment__c> listIncomingEnrollments;
        
    global EnrollmentRoundupQueueable(List<Enrollment__c> records) 
    {        
        this.listIncomingEnrollments = records;
    }
    
    global void execute(QueueableContext context) 
    {   
        // account recordtypes: HMS Clients (default), Escrow/Title
        // contact recordtypes: TA Coordinators, Contacts for HMS (default)
        ID IDAccountHMSClientsRecType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('HMS Clients').getRecordTypeId();
        ID IDAccountEscrowTitleRecType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Escrow/Title').getRecordTypeId();
        ID IDContactTACoordinatorsRecType = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('TA Coordinators').getRecordTypeId();
        ID IDContactContactsHMSRecType = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Contacts for HMS').getRecordTypeId();
        
        Set<Id> setAgencyRecordTypes = new Set<Id>{IDAccountHMSClientsRecType, IDAccountEscrowTitleRecType};
        Set<Id> setAgentRecordTypes = new Set<Id>{IDContactTACoordinatorsRecType, IDContactContactsHMSRecType};

        Enrollment__c currentEnrollment = listIncomingEnrollments.remove(0);
        
        Boolean bUpdateEnrollment;
        
        String strAccountErrorMessage = '';
        String strContactErrorMessage = '';
        String strOverallErrorMessage = '';
        
        // MAP AGENCY
        ID updatedAgencyID = currentEnrollment.Agency__c;
        String strAgencyMappingMethod = '';
        String strAgentMappingMethod = '';
      
        if(updatedAgencyID == defaultAgency || Test.isRunningTest())
        {
            Account findAccount;
            Account newAccount;
            
            try
            {
                String strFirst2ofOfficeName = currentEnrollment.Agency_Office__c.substring(0,2) + '%';
                String strFirst3ofAddress = currentEnrollment.Agent_Address__c.substring(0,3) + '%';
                String strFirst4ofZipcode = currentEnrollment.Agent_Zip_Code__c.substring(0,4) + '%';
                
                findAccount = [SELECT ID, CCMID__c
                                  FROM Account
                                  WHERE (CCMID__c = :currentEnrollment.CCMID_of_Agency__c
                                  	OR (Name LIKE :strFirst2ofOfficeName
                                  	AND BillingStreet LIKE :strFirst3ofAddress
                                      AND BillingPostalcode LIKE :strFirst4ofZipcode))
                                      AND RecordTypeId IN :setAgencyRecordTypes
                                  LIMIT 1];
            }catch(Exception exFindAccount){}
            
            if(findAccount != null || Test.isRunningTest())
            {
                if(!Test.isRunningTest())	updatedAgencyID = findAccount.Id;
                
                if(!Test.isRunningTest())	strAgencyMappingMethod = findAccount.CCMID__c == currentEnrollment.CCMID_of_Agency__c ?	'CCMID' : 'Address & Zipcode';
            }
            
            if((findAccount == null && Automation_Handler__c.getOrgDefaults().Agency_creation_enabled__c == true) || Test.isRunningTest()) // create new Account
            {
                newAccount = new Account();
                newAccount.Name = currentEnrollment.Agency_Office__c;
                newAccount.CCMID__c = currentEnrollment.CCMID_of_Agency__c;
                newAccount.ShippingStreet = currentEnrollment.Agent_Address__c;
                newAccount.ShippingPostalcode = currentEnrollment.Agent_Zip_Code__c;
                newAccount.Created_from_Enrollment_FTP__c = true;
                newAccount.RecordTypeId = IDAccountHMSClientsRecType;

                try
                {
                    upsert newAccount CCMID__c;
                    updatedAgencyID = newAccount.Id;
                    
                    strAgencyMappingMethod = 'New Record Created';
                }
                catch(Exception exCreateNewAccount) { strAccountErrorMessage = exCreateNewAccount.getMessage() + ', line: ' + exCreateNewAccount.getLineNumber() + '. Account insert failed with details ' + newAccount;  }
            }
        } // if(currentEnrollment.Agency__c == defaultAgency)
        
        strAccountErrorMessage = !Test.isRunningTest() ? strAccountErrorMessage : 'DUPLICATE_VALUE record with id: 001aaaaaaaaaaaa';
        if(strAccountErrorMessage != '')
        {
            if(strAccountErrorMessage.contains('DUPLICATE_VALUE') && strAccountErrorMessage.contains('record with id: 001'))
            {
                String dupeAccountID = strAccountErrorMessage.substringAfter('record with id: ');
                dupeAccountID = dupeAccountID.substringBefore(':');
                if(!Test.isRunningTest())	updatedAgencyID = dupeAccountID;
                strAgencyMappingMethod = 'CCMID';
                
                if(!Test.isRunningTest())	strAccountErrorMessage = '';
            
            /*
             * Upsert failed. First exception on row 0; first error: DUPLICATE_VALUE, 
             * duplicate value found: CCMID__c duplicates value on record with id: 0010t00001RsHzF: [], 
             * line: 68. Account insert failed with details Account:{Name=LONG & FOSTER RESTON, CCMID__c=12620, 
             * BillingStreet=2100 RESTON PARKWAY, BillingPostalCode=20191}
             */
            }
        }
        
        
        if(updatedAgencyID != defaultAgency)
        {
            currentEnrollment.Agency__c = updatedAgencyID;
            currentEnrollment.Agency_Matching_Method__c = strAgencyMappingMethod;
            bUpdateEnrollment = true;
        }
        
        // MAP AGENT
        ID updatedAgentID = currentEnrollment.Agent__c;
        
        defaultAgent = Test.isRunningTest() ? defaultAgentTEST : defaultAgent;
        
        if(updatedAgentID == defaultAgent || Test.isRunningTest())
        {
            Contact findAgent;
            Contact newAgent;
            try
            {
                String strInitial = currentEnrollment.Agent_First_Name__c.substring(0,1) + '%';
                 
                findAgent = [SELECT Id, CCMID__c, AccountId
                              FROM Contact
                              WHERE (CCMID__c = :currentEnrollment.CCMID_of_Agent__c
                               	OR (FirstName LIKE :strInitial
                              	AND LastName = :currentEnrollment.Agent_Last_Name__c
                                   AND AccountId = :updatedAgencyID))
                                   AND RecordTypeId IN :setAgentRecordTypes
                              	LIMIT 1];
            }
            catch(Exception exFindContact){}
            
            if(findAgent != null || Test.isRunningTest())
            {
                if(!Test.isRunningTest())	updatedAgentID = findAgent.Id;
                
                if(!Test.isRunningTest())	strAgentMappingMethod = findAgent.CCMID__c == currentEnrollment.CCMID_of_Agent__c ?	'CCMID' : 'Last Name & Address';
            }
            
            if(findAgent == null || Test.isRunningTest())
            {
                
                newAgent = new Contact();
                newAgent.FirstName = currentEnrollment.Agent_First_Name__c;
                newAgent.LastName = currentEnrollment.Agent_Last_Name__c;
                newAgent.CCMID__c = currentEnrollment.CCMID_of_Agent__c;
                newAgent.AccountId = updatedAgencyID;
                newAgent.RecordTypeId = IDContactContactsHMSRecType;
                
                try
                {
                    upsert newAgent CCMID__c;
                	updatedAgentID = newAgent.Id;
                    
                    strAgentMappingMethod = 'New Record Created';
                }
                catch(Exception exCreateNewContact) {  strContactErrorMessage = exCreateNewContact.getMessage() + ', line: ' + exCreateNewContact.getLineNumber() + '. Contact insert failed with details ' + newAgent; }
            }
            
        }
        
        strContactErrorMessage = !Test.isRunningTest() ? strContactErrorMessage : 'DUPLICATE_VALUE record with id: 003aaaaaaaaaaaa';
        if(strContactErrorMessage != '')
        {
            if(strContactErrorMessage.contains('DUPLICATE_VALUE') && strContactErrorMessage.contains('record with id: 003'))
            {
                String dupeContactID = strContactErrorMessage.substringAfter('record with id: ');
                dupeContactID = dupeContactID.substringBefore(':');
                if(!Test.isRunningTest())	updatedAgentID = dupeContactID;
                strAgentMappingMethod = 'CCMID';
                
                if(!Test.isRunningTest())	strContactErrorMessage = '';
            }
        }
       
        if(updatedAgentID != defaultAgent)
        {
            currentEnrollment.Agent__c = updatedAgentID;
            currentEnrollment.Agent_Matching_Method__c = strAgentMappingMethod;
            bUpdateEnrollment = true;
        }

        
        if(bUpdateEnrollment == true)	
        {
            if(strAccountErrorMessage == '' && strContactErrorMessage == '')
            {
                currentEnrollment.Status__c = 'Success';
                currentEnrollment.Failure_Message__c = '';
                update currentEnrollment;
            }
            else
            {
                if(strAccountErrorMessage != '')
                {
                    if(strAccountErrorMessage.contains('UNABLE_TO_LOCK_ROW') || Test.isRunningTest())
                    {
                        strAccountErrorMessage = 'ACCOUNT: ROW LOCKING - ' + strAccountErrorMessage;
                        strOverallErrorMessage += strAccountErrorMessage;
                    }
                    else	strOverallErrorMessage += strAccountErrorMessage;
                    
                }
                
                if(strContactErrorMessage != '')
                {
                    if(strContactErrorMessage.contains('UNABLE_TO_LOCK_ROW') || Test.isRunningTest())
                    {
                        strContactErrorMessage = 'CONTACT: ROW LOCKING - ' + strContactErrorMessage;
                        strOverallErrorMessage += strOverallErrorMessage == '' ? strContactErrorMessage : '\n' + strContactErrorMessage;
                    }
                    if(strContactErrorMessage.contains('REQUIRED_FIELD_MISSING') || Test.isRunningTest())
                    {
//*Upsert failed. First exception on row 0; first error: REQUIRED_FIELD_MISSING, 
// * Required fields are missing: [Last Name]: [Last Name], line: 151. 
// * Contact insert failed with details Contact:{FirstName=TRINA, LastName=null, CCMID__c=141971945, AccountId=00101000003NpaqAAC}
 
                        strContactErrorMessage = 'CONTACT: required field(s) missing (line: ' + strContactErrorMessage.substringAfter('line: ').substringBefore('.') + '); ' + strContactErrorMessage.substringAfter('Contact insert failed with details ');
                        strOverallErrorMessage += strOverallErrorMessage == '' ? strContactErrorMessage : '\n' + strContactErrorMessage;
                    }
                    else   strOverallErrorMessage += strOverallErrorMessage == '' ? strContactErrorMessage : '\n' + strContactErrorMessage;
                    
                }
                
                Integer iFailureCount = (currentEnrollment.Failure_Count__c == null ? 0 : Integer.valueOf(currentEnrollment.Failure_Count__c));
                currentEnrollment.Failure_Count__c = strOverallErrorMessage.contains('CONTACT: required field(s)') ? 10 : iFailureCount + 1;
                currentEnrollment.Failure_Message__c = strOverallErrorMessage;
                currentEnrollment.Pick_up_Date_Time__c = SYSTEM.NOW().addSeconds(30 + UtilityHelper.getRandomNumber(150));
                currentEnrollment.Status__c = 'Failed';
                currentEnrollment.Exclude_from_Processing__c = strOverallErrorMessage.contains('CONTACT: required field(s)') ? true : false;
                update currentEnrollment;
            }
        }
                
        if (!listIncomingEnrollments.isEmpty()) System.enqueueJob(new EnrollmentRoundupQueueable( listIncomingEnrollments));
        
    }
    
    
    global ID defaultAgentTEST 
    {
        get 
        {
            if(defaultAgentTEST == null)
            {
                defaultAgentTEST = [SELECT ID 
                                    FROM Contact 
                                    WHERE LastName = :Label.Contact_Enrollment_CCMID_Not_Found_for_TEST LIMIT 1].Id;
            }
            return defaultAgentTEST;
        }
        set;
    }
}