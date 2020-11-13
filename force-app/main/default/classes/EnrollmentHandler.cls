public without sharing class EnrollmentHandler 
{
    /*
     * SHW (seller warranty) will come in with a unique Warranty Number and the fields of 
     * NAME_FIRST and NAME_LAST and Date Ordered will be the **seller's name*
     *
     * After it is "Converted", it will then come in through the FTP in a future daily import with 
     * the same Warranty Number  but it will then be the Warranty Type of BCW and the same fields 
     * of NAME_FIRST and NAME_LAST in the FTP will now be the **buyer's name**
     *
     * Based on the Warranty's Type (SHW vs everything else), the NAME_FIRST & NAME_LAST fields need to be
     * mapped to the SELLER FIRST NAME, SELLER LAST NAME vs BUYER FIRST NAME, BUYER LAST NAME
     * fields respectively
     * 
     * Based on the Warranty's Type (SHW vs everything else), the Date Ordered field needs to be
     * mapped to the Seller Date Ordered vs. Buyer Date Ordered fields respectively.
     */

    public static void processBeforeInserts(List<Enrollment__c> listNew)
    {
        List<Enrollment__c> listApplicableEnrollments = new List<Enrollment__c>();
        Integer iListSize = listNew.size();
        Integer i = 0;

        while(i < iListSize)
        {
            Enrollment__c enr = listNew[i];
            if(enr.Warranty_Type__c != null)
                listApplicableEnrollments.add( enr );

            i += 1;
        }

        if(listApplicableEnrollments.size() > 0)    
        {
            handleNamesBasedOnType(listNew, listApplicableEnrollments);
            handleDateOrderedBasedOnType(listNew, listApplicableEnrollments);
        }
            
    }


    public static void processBeforeUpdates(List<Enrollment__c> listNew, List<Enrollment__c> listOld)
    {
        List<Enrollment__c> listApplicableEnrollments = new List<Enrollment__c>();
        Integer iListSize = listNew.size();
        Integer i = 0;

        while(i < iListSize)
        {
            Enrollment__c enr = listNew[i];
            Enrollment__c enrOld = listOld[i];

            if((enr.Warranty_Type__c != null) && (enrOld.Warranty_Type__c != enr.Warranty_Type__c))
                listApplicableEnrollments.add( enr );

            i += 1;
        }

        if(listApplicableEnrollments.size() > 0) 
        {
            handleNamesBasedOnType(listNew, listApplicableEnrollments);
            handleDateOrderedBasedOnType(listNew, listApplicableEnrollments);
        }   
            
    }


    public static void handleNamesBasedOnType(List<Enrollment__c> theTriggerList, List<Enrollment__c> theApplicableList)
    {
        Integer iListSize = theTriggerList.size();
        Integer i = 0;

        while(i < iListSize)
        {
            Enrollment__c enr = theTriggerList[i];
            if(theApplicableList.contains( enr )) // it's a valid candidate, proceed
            {
                switch on enr.Warranty_Type__c
                {
                    when 'SHW'
                    {
                        enr.SELLER_FIRST_NAME__c = enr.NAME_FIRST__c;
                        enr.SELLER_LAST_NAME__c = enr.NAME_LAST__c;
                        enr.Seller_Name_Populated__c = SYSTEM.NOW();
                        
                    }
                    when else
                    {
                        enr.BUYER_FIRST_NAME__c = enr.NAME_FIRST__c;
                        enr.BUYER_LAST_NAME__c = enr.NAME_LAST__c;
                        enr.Buyer_Name_Populated__c = SYSTEM.NOW();
                    }
                }
            }
            i += 1;
        }
    }

    public static void handleDateOrderedBasedOnType(List<Enrollment__c> theTriggerList, List<Enrollment__c> theApplicableList)
    {
        Integer iListSize = theTriggerList.size();
        Integer i = 0;

        while(i < iListSize)
        {
            Enrollment__c enr = theTriggerList[i];
            if(theApplicableList.contains( enr )) // it's a valid candidate, proceed
            {
                switch on enr.Warranty_Type__c
                {
                    when 'SHW'
                    {
                        enr.SELLER_FIRST_NAME__c = enr.NAME_FIRST__c;
                        enr.SELLER_LAST_NAME__c = enr.NAME_LAST__c;
                        enr.Seller_Name_Populated__c = SYSTEM.NOW();
                        
                        
                    }
                    when else
                    {
                        enr.BUYER_FIRST_NAME__c = enr.NAME_FIRST__c;
                        enr.BUYER_LAST_NAME__c = enr.NAME_LAST__c;
                        enr.Buyer_Name_Populated__c = SYSTEM.NOW();
                    }
                }
            }
            i += 1;
        }
    }
}