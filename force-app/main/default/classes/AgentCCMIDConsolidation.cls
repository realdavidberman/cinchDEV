global with sharing class AgentCCMIDConsolidation implements Database.Batchable<SObject>, Schedulable 
{
    /* Rackspace, David Berman, 11 September 2020

     * Agents with multiple CCMIDs
     * To help correct this, need to identify an agent with multiple CCMIDs, 
     * then reference all CCMIDs that exist for that 1 agent (contact) and,
     * then select the one that has been enrolled to most recently. 
     * The CCMID that was enrolled to most recently would then become the "Master" CCMID 
     * for that agent (contact) and all enrollments that are associated with that agent (contact) 
     * would then also be updated to have that "master" CCMID.
     */

    String query;
    global static String defaultAgent = Label.Contact_Enrollment_CCMID_Not_Found;
    ID IDContactTACoordinatorsRecType = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('TA Coordinators').getRecordTypeId();
    ID IDContactContactsHMSRecType = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Contacts for HMS').getRecordTypeId();
        
    Set<Id> setAgentRecordTypes = new Set<Id>{IDContactTACoordinatorsRecType, IDContactContactsHMSRecType};

    global AgentCCMIDConsolidation() 
    {
        query = 'SELECT Id, CCMID__c, Previous_CCMID__c '+
                'FROM Contact ' + 
                'WHERE RecordTypeId IN :setAgentRecordTypes ';
        query += Test.isRunningTest() ? ' LIMIT 10' : '';
    }

    global AgentCCMIDConsolidation(String customQuery)
    {
        query = customQuery;
    }


    global Database.QueryLocator start(Database.BatchableContext BC) 
    {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Contact> scope) 
    {
        Integer iListSize = scope.size();
        Integer i = 0;

        Set<ID> setContactIDs = new Set<Id>();
        while(i < iListSize)
        {
            setContactIDs.add(scope[i].Id);
            i++;
        }

        List<Enrollment__c> listEnrollmentsForAgents;
        try 
        {
            listEnrollmentsForAgents = new List<Enrollment__c>(
                [SELECT Id, CCMID_of_Agent__c, CCMID_of_Agent_formula__c, Agent__c, Date_Ordered__c 
                FROM Enrollment__c
                WHERE Status__c = 'Success'
                    AND Agent__c IN :setContactIDs
                ORDER BY Agent__c, Date_Ordered__c DESC, CCMID_of_Agent__c DESC]
            );
        }catch (Exception exEnrollments) {}


        Integer iEnrollmentsListSize = listEnrollmentsForAgents.size();
        Integer j = 0;
        Map<Id, Contact> mapContactUpdates = new Map<Id, Contact>();
        while(j < iEnrollmentsListSize)
        {
            Enrollment__c ENR = listEnrollmentsForAgents[j];
            j++;

            if(!mapContactUpdates.containsKey(ENR.Agent__c) && ENR.CCMID_of_Agent__c != ENR.CCMID_of_Agent_formula__c)
            {
                Contact conUpdate = new Contact();
                conUpdate.Id = ENR.Agent__c;
                conUpdate.Previous_CCMID__c = ENR.CCMID_of_Agent_formula__c;
                conUpdate.CCMID__c = ENR.CCMID_of_Agent__c;

                mapContactUpdates.put(ENR.Agent__c, conUpdate);
            }
        }

        if(mapContactUpdates.size() > 0)
        {
            AgentCCMIDConsolidationQueueable updateContactsAsynchronously = new AgentCCMIDConsolidationQueueable(mapContactUpdates.values());
        	SYSTEM.enqueueJob( updateContactsAsynchronously );  
        }

    }

    global void execute(SchedulableContext sc) 
    {  
        AgentCCMIDConsolidation batch = new AgentCCMIDConsolidation();
        Database.executeBatch(batch, 200);
    }

    global void finish(Database.BatchableContext BC) 
    {

    }

}
