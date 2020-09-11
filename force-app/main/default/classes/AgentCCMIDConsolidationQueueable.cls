global with sharing class AgentCCMIDConsolidationQueueable implements Queueable
{
    private List<Contact> listContactsForAsyncUpdate = new List<Contact>();

    global AgentCCMIDConsolidationQueueable(List<Contact> records)
    {
        this.listContactsForAsyncUpdate = records;
    }

    global void execute(QueueableContext context) 
    { 
        // Asynchronous update of Contact records
        update listContactsForAsyncUpdate;
    }
}
