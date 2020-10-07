public without sharing class UtilityHelper 
{
    public static List<String> getEmailAddresses(String strSource)
    {
        List<String> listEmails = new List<String>();
        for(Email_Recipients__mdt cmdt : [SELECT Email_Address__c 
                                            FROM Email_Recipients__mdt 
                                            WHERE Source__c = :strSource])
        {
            listEmails.add(cmdt.Email_Address__c);
        }    
        
        return listEmails;
    }

	public static Integer getRandomNumber(Integer size)
    {
        // return random number between 0 and <size>
		Double d = math.random() * size;
		return d.intValue();
	}
    
    public static String getNowDateTimeString()
    {
        Datetime dtNow = SYSTEM.NOW().addHours(7); //GMT adjustment
        //2005-10-08T01:02:03Z
        
        String sYear = String.valueOf(dtNow.year());
        String sMonth = String.valueOf(dtNow.month());
        sMonth = sMonth.length() == 1 ? '0' + sMonth : sMonth;
        String sDay = String.valueOf(dtNow.day());
        sDay = sDay.length() == 1 ? '0' + sDay : sDay;
        String sHour = String.valueOf(dtNow.hour());
        sHour = sHour.length() == 1 ? '0' + sHour : sHour;
        String sMinute = String.valueOf(dtNow.minute());
        sMinute = sMinute.length() == 1 ? '0' + sMinute : sMinute;
        String sSecond = String.valueOf(dtNow.second());
        sSecond = sSecond.length() == 1 ? '0' + sSecond : sSecond;
        
        return sYear+'-'+sMonth+'-'+sDay+'T'+sHour+':'+sMinute+':'+sSecond+'Z';
    }
}