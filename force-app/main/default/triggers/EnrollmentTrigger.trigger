trigger EnrollmentTrigger on Enrollment__c (before insert, after insert, before update, after update, before delete, after delete) 
{
    
    switch on Trigger.operationType 
    {
        when BEFORE_INSERT
        {
            EnrollmentHandler.processBeforeInserts(Trigger.new);
        } 
        when AFTER_INSERT{}
        when BEFORE_UPDATE
        {
            EnrollmentHandler.processBeforeUpdates(Trigger.new, Trigger.old);
        }
        when AFTER_UPDATE{}
        when BEFORE_DELETE{} 
    }

}