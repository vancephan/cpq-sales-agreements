public with sharing class CPQB_SetSalesAgreeHeader {
    public SBQQ__Quote__c quote {get;set;}
    public SalesAgreement sa {get;set;}
    public Integer calcMonths {get;set;}
    public Integer calcedScheduleCount {get;set;}

    public CPQB_SetSalesAgreeHeader(ApexPages.StandardController controller) {
        SBQQ__Quote__c q = (SBQQ__Quote__c)controller.getRecord();

        quote = [SELECT Id, Name,
                    SBQQ__StartDate__c, SBQQ__EndDate__c,
                    SBQQ__SubscriptionTerm__c, SBQQ__Account__c,
                    SBQQ__PriceBook__c, Schedule_Frequency__c
                    FROM SBQQ__Quote__c
                    WHERE Id =: q.Id].get(0);

        calculateNumberOfMonths();
        setScheduleCount(); 

    }

    public Integer calculateNumberOfMonths(){
        Integer rawMonths = 0;

        if(quote.SBQQ__EndDate__c != null){
            rawMonths = quote.SBQQ__StartDate__c.monthsBetween(quote.SBQQ__EndDate__c);

            if(quote.SBQQ__EndDate__c.day() > quote.SBQQ__StartDate__c.day()){
                calcMonths = rawMonths + 1;
            }else{
                calcMonths = rawMonths;
            }        
        }else{
            calcMonths = Integer.valueOf(quote.SBQQ__SubscriptionTerm__c);

            system.debug('Calculated count of rawMonths is ' + rawMonths);
        }

        return calcMonths;
    }

    public Integer setScheduleCount(){

        if(quote.Schedule_Frequency__c == 'Weekly'){
            calcedScheduleCount = Integer.valueOf((Decimal.valueOf((quote.SBQQ__StartDate__c.daysBetween(quote.SBQQ__EndDate__c))/7)).round(System.RoundingMode.CEILING));

            system.debug('Rounded count of weeks is ' + calcedScheduleCount);

        }else if(quote.Schedule_Frequency__c == 'Monthly'){
            
            calcedScheduleCount = calcMonths;

            system.debug('Rounded count of Months is ' + calcedScheduleCount);

        }else if(quote.Schedule_Frequency__c == 'Quarterly'){
            
            calcedScheduleCount = Integer.valueOf((Decimal.valueOf(calcMonths/3)).round(System.RoundingMode.CEILING));

            system.debug('Rounded count of Quarters is ' + calcedScheduleCount);

        }else if(quote.Schedule_Frequency__c == 'Yearly'){
            calcedScheduleCount = Integer.valueOf((Decimal.valueOf(calcMonths/12)).round(System.RoundingMode.CEILING));

            system.debug('Rounded count of Years is ' + calcedScheduleCount);
        }else if(quote.Schedule_Frequency__c == 'One-Time'){
            calcedScheduleCount = 1;
        }

        return calcedScheduleCount;
    }

    public SalesAgreement createSalesAgreementHeader(){

        sa = new SalesAgreement(AccountId = quote.SBQQ__Account__c, 
                                Name = quote.Name + ' Sales Agreement', 
                                PricebookId = quote.SBQQ__PriceBook__c, 
                                ScheduleCount = calcedScheduleCount, 
                                ScheduleFrequency = quote.Schedule_Frequency__c,
                                StartDate = quote.SBQQ__StartDate__c, 
                                Status = 'Draft', 
                                Quote__c = quote.Id);

        insert sa;

        return sa;
    }

    public PageReference execute(){
        createSalesAgreementHeader();
        PageReference currentQuotePage = new PageReference('/'+quote.Id);
        return currentQuotePage;
    }

}