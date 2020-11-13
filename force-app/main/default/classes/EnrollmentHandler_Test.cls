@isTest
private with sharing class EnrollmentHandler_Test 
{
    static TestMethod void insertBCWRecord()
    {
        Enrollment__c Enr = new Enrollment__c();
        Enr.Status__c = 'New';
        Enr.Agency_Office__c = 'Test Office';
        Enr.Agent_Address__c = 'Test Street 1';
        Enr.CCMID_of_Agency__c = 'Agency1000';
        Enr.Agent_Zip_Code__c = '99999';
        Enr.Agent_First_Name__c = 'JOHN';
        Enr.Agent_Last_Name__c = 'DOE';
        Enr.CCMID_of_Agent__c = 'Agent8000';
        Enr.NAME_FIRST__c = 'Billy';
        Enr.NAME_LAST__c = 'Buyer';
        Enr.Warranty_Type__c = 'BCW';
        Enr.Warranty_Number__c = '123456';
        Enr.Date_Ordered__c = SYSTEM.TODAY();

        Test.startTest();
        insert Enr;
        Test.stopTest();

        Enrollment__c enrAfter = [SELECT Id, BUYER_FIRST_NAME__c, BUYER_LAST_NAME__c, NAME_FIRST__c, NAME_LAST__c,
                                    Buyer_Date_Ordered__c
                                FROM Enrollment__c 
                                WHERE Id = :Enr.Id LIMIT 1];
        SYSTEM.assertEquals(enrAfter.BUYER_FIRST_NAME__c, enrAfter.NAME_FIRST__c);
        SYSTEM.assertEquals(enrAfter.BUYER_LAST_NAME__c, enrAfter.NAME_LAST__c);
        SYSTEM.assertEquals(enrAfter.Buyer_Date_Ordered__c, SYSTEM.TODAY());
    }

    static TestMethod void insertSHWRecord()
    {
        Enrollment__c Enr = new Enrollment__c();
        Enr.Status__c = 'New';
        Enr.Agency_Office__c = 'Test Office';
        Enr.Agent_Address__c = 'Test Street 1';
        Enr.CCMID_of_Agency__c = 'Agency1000';
        Enr.Agent_Zip_Code__c = '99999';
        Enr.Agent_First_Name__c = 'JOHN';
        Enr.Agent_Last_Name__c = 'DOE';
        Enr.CCMID_of_Agent__c = 'Agent8000';
        Enr.NAME_FIRST__c = 'Sara';
        Enr.NAME_LAST__c = 'Seller';
        Enr.Warranty_Type__c = 'SHW';
        Enr.Warranty_Number__c = '123456';
        Enr.Date_Ordered__c = SYSTEM.TODAY();

        Test.startTest();
        insert Enr;
        Test.stopTest();

        Enrollment__c enrAfter = [SELECT Id, SELLER_FIRST_NAME__c, SELLER_LAST_NAME__c, NAME_FIRST__c, NAME_LAST__c,
                                    Seller_Date_Ordered__c
                                FROM Enrollment__c 
                                WHERE Id = :Enr.Id LIMIT 1];
        SYSTEM.assertEquals(enrAfter.SELLER_FIRST_NAME__c, enrAfter.NAME_FIRST__c);
        SYSTEM.assertEquals(enrAfter.SELLER_LAST_NAME__c, enrAfter.NAME_LAST__c);
        SYSTEM.assertEquals(enrAfter.Seller_Date_Ordered__c, SYSTEM.TODAY());
    }

    static TestMethod void updateToBCWRecord()
    {
        Enrollment__c Enr = new Enrollment__c();
        Enr.Status__c = 'New';
        Enr.Agency_Office__c = 'Test Office';
        Enr.Agent_Address__c = 'Test Street 1';
        Enr.CCMID_of_Agency__c = 'Agency1000';
        Enr.Agent_Zip_Code__c = '99999';
        Enr.Agent_First_Name__c = 'JOHN';
        Enr.Agent_Last_Name__c = 'DOE';
        Enr.CCMID_of_Agent__c = 'Agent8000';
        Enr.NAME_FIRST__c = 'Johnny';
        Enr.NAME_LAST__c = 'Nobody';
        Enr.Warranty_Number__c = '123456';
        
        insert Enr;

        
        Enrollment__c enrAfterInsert = [SELECT Id, Warranty_Type__c, BUYER_FIRST_NAME__c, BUYER_LAST_NAME__c, Buyer_Name_Populated__c,
                                            Buyer_Date_Ordered__c
                                        FROM Enrollment__c 
                                        WHERE Id = :Enr.Id LIMIT 1];

        SYSTEM.assertEquals(enrAfterInsert.BUYER_FIRST_NAME__c, null);
        SYSTEM.assertEquals(enrAfterInsert.BUYER_LAST_NAME__c, null);
        SYSTEM.assertEquals(enrAfterInsert.Buyer_Name_Populated__c, null);
        SYSTEM.assertEquals(enrAfterInsert.Buyer_Date_Ordered__c, null);

        Test.startTest();
            enrAfterInsert.Warranty_Type__c = 'BCW';
            enrAfterInsert.Date_Ordered__c = SYSTEM.TODAY();
            update enrAfterInsert;
        Test.stopTest();

        Enrollment__c enrAfterUpdate = [SELECT Id, BUYER_FIRST_NAME__c, BUYER_LAST_NAME__c, Buyer_Name_Populated__c, NAME_FIRST__c, NAME_LAST__c,
                                            Buyer_Date_Ordered__c FROM Enrollment__c 
                                        WHERE Id = :Enr.Id LIMIT 1];

        SYSTEM.assertEquals(enrAfterUpdate.BUYER_FIRST_NAME__c, enrAfterUpdate.NAME_FIRST__c);
        SYSTEM.assertEquals(enrAfterUpdate.BUYER_LAST_NAME__c, enrAfterUpdate.NAME_LAST__c);
        SYSTEM.assertNotEquals(enrAfterUpdate.Buyer_Name_Populated__c, null);
        SYSTEM.assertEquals(enrAfterUpdate.Buyer_Date_Ordered__c, SYSTEM.TODAY());
    }


    static TestMethod void updateToSHWRecord()
    {
        Enrollment__c Enr = new Enrollment__c();
        Enr.Status__c = 'New';
        Enr.Agency_Office__c = 'Test Office';
        Enr.Agent_Address__c = 'Test Street 1';
        Enr.CCMID_of_Agency__c = 'Agency1000';
        Enr.Agent_Zip_Code__c = '99999';
        Enr.Agent_First_Name__c = 'JOHN';
        Enr.Agent_Last_Name__c = 'DOE';
        Enr.CCMID_of_Agent__c = 'Agent8000';
        Enr.NAME_FIRST__c = 'Johnny';
        Enr.NAME_LAST__c = 'Nobody';
        Enr.Warranty_Number__c = '123456';
        
        insert Enr;

        
        Enrollment__c enrAfterInsert = [SELECT Id, Warranty_Type__c, SELLER_FIRST_NAME__c, SELLER_LAST_NAME__c, Seller_Name_Populated__c,
                                            Seller_Date_Ordered__c
                                        FROM Enrollment__c 
                                        WHERE Id = :Enr.Id LIMIT 1];

        SYSTEM.assertEquals(enrAfterInsert.SELLER_FIRST_NAME__c, null);
        SYSTEM.assertEquals(enrAfterInsert.SELLER_LAST_NAME__c, null);
        SYSTEM.assertEquals(enrAfterInsert.Seller_Name_Populated__c, null);
        SYSTEM.assertEquals(enrAfterInsert.Seller_Date_Ordered__c, null);

        Test.startTest();
            enrAfterInsert.Warranty_Type__c = 'SHW';
            enrAfterInsert.Date_Ordered__c = SYSTEM.TODAY();
            update enrAfterInsert;
        Test.stopTest();

        Enrollment__c enrAfterUpdate = [SELECT Id, SELLER_FIRST_NAME__c, SELLER_LAST_NAME__c, Seller_Name_Populated__c, NAME_FIRST__c, NAME_LAST__c,
                                            Seller_Date_Ordered__c 
                                        FROM Enrollment__c 
                                        WHERE Id = :Enr.Id LIMIT 1];

        SYSTEM.assertEquals(enrAfterUpdate.SELLER_FIRST_NAME__c, enrAfterUpdate.NAME_FIRST__c);
        SYSTEM.assertEquals(enrAfterUpdate.SELLER_LAST_NAME__c, enrAfterUpdate.NAME_LAST__c);
        SYSTEM.assertNotEquals(enrAfterUpdate.Seller_Name_Populated__c, null);
        SYSTEM.assertEquals(enrAfterUpdate.Seller_Date_Ordered__c, SYSTEM.TODAY());
    }
}