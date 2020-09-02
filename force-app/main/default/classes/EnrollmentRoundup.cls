global class EnrollmentRoundup implements Database.Batchable<sObject>, Schedulable, Database.Stateful
{
    /* David Berman, Rackspace, 13 August 2020
    * Collects Enrollments and distributes them to a Queueable class for processing
    * Currently it is scheduled to run every 15 seconds (after the job finishes,
    * it reschedules itself to 15 seconds from 'now')
    *
    * Tested by "EnrollmentRoundup_Test"
    * 
    * -"Pick-up Date/Time"[*3] is blank or has a value in the past AND
    * - 	(EITHER: the Status is "New" or "Retry"
    * - 	OR: the Status is "Failed" and the "Failure Count" < 10)
    */
    
	String query;
    Integer iScopeSize;
    
 	global EnrollmentRoundup()
    {
        String strNow = UtilityHelper.getNowDateTimeString();
        iScopeSize = 0;
        
        query = 'SELECT Id, Name, Status__c, Failure_Count__c, Failure_Message__c, Pick_up_Date_Time__c, '+
            		'Agency_Office__c, Agent_Address__c, Agent_Zip_Code__c, CCMID_of_Agency__c, '+
            		'CCMID_of_Agent__c, Agent_First_Name__c, Agent_Last_Name__c, ' +
            		'Agency_or_Agent_is_CCMID__c, '+
            		'Agency__c, Agent__c, Exclude_from_Processing__c, Agent_Matching_Method__c, Agency_Matching_Method__c ' +
            'FROM Enrollment__c ';
        
        query += !Test.isRunningTest() ? 'WHERE Agency_or_Agent_is_CCMID__c = true ' +
            							' AND ((Pick_up_Date_Time__c = null OR Pick_up_Date_Time__c < ' + strNow + ') ' +
            							' AND (Status__c IN ( \'New\',\'Retry\'  ) ' +
            							'OR (Status__c = \'Failed\' AND Failure_Count__c < 10))) ' +
            							' AND Exclude_from_Processing__c != true '
            							: '';
        
        query += ' ORDER BY Name ';
        
        query += Test.isRunningTest() ? ' LIMIT 1 ' : ' LIMIT 10000'; 
        SYSTEM.DEBUG('+++++ query: ' + query);
        
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) 
    {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Enrollment__c> scope) 
    {
        iScopeSize = scope.size();
        
        SYSTEM.DEBUG('+++++ iScopeSize: ' + iScopeSize);
        
        Integer i = 0;
        List<Enrollment__c> updateScope = new List<Enrollment__c>();
        while(i < iScopeSize)
        {
            scope[i].Status__c = 'Picked up by Queueable';
            updateScope.add(scope[i]);
            i += 1;
        }
        
        try
        {
            update updateScope;
            
            EnrollmentRoundupQueueable createAccountsContacts = new EnrollmentRoundupQueueable(scope);
        	SYSTEM.enqueueJob(createAccountsContacts);  
        }
        catch(Exception ex){SYSTEM.DEBUG('+++++ EX MSG: ' + ex.getMessage());}
    }
    
    global void execute(SchedulableContext sc) 
    {  
        EnrollmentRoundup batch = new EnrollmentRoundup();
        Database.executeBatch(batch, 100);
        
        //remove from scheduled job list
        try{System.abortJob( sc.getTriggerID() );}catch(Exception e){}
    }
    
    global void finish(Database.BatchableContext BC) 
    {
        // Schedule next run
        Datetime sysTime = System.now();
        Datetime sysTimeTomorrow = sysTime.addDays(1);
        sysTime = sysTime.addSeconds( 15 );
        Datetime logTime = sysTime.addHours(-7);
        String sHour = String.valueOf(sysTime.hour());
        sHour = (sHour.length() == 1 ? '0' + sHour : sHour);
        String sMinute = String.valueOf(sysTime.minute());
        sMinute = (sMinute.length() == 1 ? '0' + sMinute : sMinute);
        
        String chron_expTomorrow = '' + sysTimeTomorrow.second() + ' 0 4 ' + sysTimeTomorrow.day() + ' ' + sysTimeTomorrow.month() + ' ? ' + sysTimeTomorrow.year();
        String chron_exp = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
        if(!Test.isRunningTest())	
        {
            if(iScopeSize > 0)	try{System.schedule('Next EnrollmentRoundup Batch: ' + sHour + ':' + sMinute, chron_exp, this);}catch(Exception ex){  }
            else try{System.schedule('Next EnrollmentRoundup Batch: 4:00am', chron_expTomorrow, this);}catch(Exception ex2){  }
        }
    }
    
    
}