public with sharing class CPQB_SalesAgreeSectionController {
    public Id quoteId {get; set;}
    public SBQQ__QuoteTemplate__c template {get; set;}
    public Id agreementId {get; set;}
    public List<PrintableTable> pTables {get; set;}

    public CPQB_SalesAgreeSectionController() {
        quoteId = ApexPages.currentPage().getParameters().get('qid');
        Id templateId = ApexPages.currentPage().getParameters().get('tid');
        template = getTemplate(templateId);
        agreementId = getAgreementId(quoteId);
        Map<Id, SalesAgreementProduct> agreementProdsMap = getSAProducts(agreementId);
        Map<Id, List<SalesAgreementProductSchedule>> agreementSchedulesMap = getSAPSchedulesByProductId(agreementProdsMap);
        pTables = buildTables(agreementProdsMap,agreementSchedulesMap);

    }

    public Id getAgreementId(Id quoteId) {
        List<SalesAgreement> agreements = [SELECT 
                                                Id,
                                                Quote__c
                                            FROM SalesAgreement
                                            WHERE Quote__c = :quoteId
                                            LIMIT 1];

        if(agreements.size() > 0) {
            return agreements[0].Id;
        }
        return null;
    }

        public SBQQ__QuoteTemplate__c getTemplate(Id templateId) {
        return [SELECT Id
                FROM SBQQ__QuoteTemplate__c
                WHERE Id = :templateId];
    }

    public Map<Id, SalesAgreementProduct> getSAProducts(Id agreementId) {
        return new Map<Id, SalesAgreementProduct>([SELECT
                                                        Id,
                                                        Name,
                                                        ProductId,
                                                        Product.Name,
                                                        InitialPlannedQuantity,
                                                        ListPrice,
                                                        SalesAgreementId,
                                                        SalesPrice
                                                    FROM SalesAgreementProduct
                                                    WHERE SalesAgreementId = :agreementId]);
    }

    public Map<Id, List<SalesAgreementProductSchedule>> getSAPSchedulesByProductId(Map<Id, SalesAgreementProduct> saProductsMap) {
        Map<Id, List<SalesAgreementProductSchedule>> mapSAPSList = new Map<Id, List<SalesAgreementProductSchedule>>();

        List<SalesAgreementProductSchedule> prodScheds = [SELECT
                                                                Id,
                                                                Name,
                                                                SalesAgreementProductId,
                                                                SalesAgreementProduct.ProductId,
                                                                SalesAgreementProduct.Product.Name,
                                                                DerivedPlannedAmount,
                                                                PlannedQuantity,
                                                                SalesPrice,
                                                                StartDate,
                                                                EndDate
                                                            FROM SalesAgreementProductSchedule
                                                            WHERE SalesAgreementProductId IN :saProductsMap.keySet()
                                                            ORDER BY StartDate ASC];
        
        for(SalesAgreementProductSchedule saps : prodScheds) {
            if(mapSAPSList.containsKey(saps.SalesAgreementProductId)) {
                List<SalesAgreementProductSchedule> saProdSched = mapSAPSList.get(saps.SalesAgreementProductId);
                saProdSched.add(saps);
                mapSAPSList.put(saps.SalesAgreementProductId, saProdSched);
            } else {
                mapSAPSList.put(saps.SalesAgreementProductId, new List<SalesAgreementProductSchedule> { saps });
            }
        }

        return mapSAPSList;
    }

    public List<PrintableTable> buildTables(Map<Id, SalesAgreementProduct> productMap, Map<Id, List<SalesAgreementProductSchedule>> scheduleMap) {
        List<PrintableTable> tables = new List<PrintableTable>();

        for(Id saProdId : productMap.keySet()) {
            PrintableTable table = new PrintableTable();
            table.productName = productMap.get(saProdId).Product.Name;
            table.lines = buildLines(scheduleMap.get(saProdId));
            tables.add(table);
        }

        return tables;
    }

    public List<PrintableLine> buildLines(List<SalesAgreementProductSchedule> prodSchedules) {
        List<PrintableLine> pLines = new List<PrintableLine>();

        for(SalesAgreementProductSchedule prodSched : prodSchedules) {
            PrintableLine newLine = new PrintableLine();
            newLine.productName = prodSched.SalesAgreementProduct.Product.Name;
            newLine.startDate = prodSched.StartDate;
            newLine.endDate = prodSched.EndDate;
            newLine.amount = prodSched.DerivedPlannedAmount;
            newLine.price = prodSched.SalesPrice;
            newLine.quantity = prodSched.PlannedQuantity;
            pLines.add(newLine);
        }

        return pLines;

    }

    public class PrintableTable {
        public String productName {get; set;}
        public List<PrintableLine> lines {get; set;}

        public PrintableTable() {
            this.lines = new List<PrintableLine>();
        }
    }


    public class PrintableLine {
        public String productName {get; set;}
        public Date startDate {get; set;} // start - end
        public Date endDate {get; set;} // start - end
        public Integer quantity {get; set;}
        public Decimal price {get; set;} // SalesPrice
        public Decimal amount {get; set;} // DerivedPlannedAmount

        public PrintableLine() {
        }
    }
}