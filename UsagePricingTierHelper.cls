public class UsagePricingTierHelper {

    // Main method to create UsagePricingTier records
    public static void parseAndCreateUsagePricingTiers(Id opportunityProductId) {
        OpportunityLineItem oppProduct = [SELECT Id, Pricing_Model_JSon__c, 
                                                 (SELECT Id FROM UsagePricingTiers__r) 
                                          FROM OpportunityLineItem 
                                          WHERE Id = :opportunityProductId LIMIT 1];

        System.debug('oppProduct: ' + oppProduct);

        // Check if the JSON field is null, empty, or just {}
        if (String.isBlank(oppProduct.Pricing_Model_JSon__c) || oppProduct.Pricing_Model_JSon__c == '{}') {
            System.debug('No valid JSON found, skipping process.');
            return; // Exit the method if JSON is null or empty
        }

        // Delete existing UsagePricingTier records if they exist
        if (oppProduct.UsagePricingTiers__r != null && !oppProduct.UsagePricingTiers__r.isEmpty()) {
            System.debug('Deleting existing UsagePricingTiers');
            delete oppProduct.UsagePricingTiers__r;
        }

        // Parse the JSON and create new UsagePricingTier records
        System.debug('JSON is present: ' + oppProduct.Pricing_Model_JSon__c);
        List<UsagePricingTier__c> usagePricingTiers = new List<UsagePricingTier__c>();
        
        Object deserializedJson = JSON.deserializeUntyped(oppProduct.Pricing_Model_JSon__c);
        System.debug('Deserialized JSON: ' + deserializedJson);
        
        if (deserializedJson instanceof List<Object>) {
            List<Object> jsonList = (List<Object>) deserializedJson;
            
            Decimal oneTrillion = 1000000000000.0;
            
            for (Object tierObject : jsonList) {
                Map<String, Object> tier = (Map<String, Object>) tierObject;
                System.debug('Processing tier: ' + tier);
                
                UsagePricingTier__c newTier = new UsagePricingTier__c();
                newTier.Opportunity_Product__c = oppProduct.Id;
                
                newTier.Min__c = (tier.get('min') == 'Infinity') ? oneTrillion : Decimal.valueOf((String) tier.get('min'));
                newTier.Max__c = (tier.get('max') == 'Infinity') ? oneTrillion : Decimal.valueOf((String) tier.get('max'));
                newTier.ListPrice__c = (tier.get('listPrice') == 'Infinity') ? oneTrillion : Decimal.valueOf((String) tier.get('listPrice'));
                newTier.MonthlyPrice__c = (tier.get('monthlyFee') == 'Infinity') ? oneTrillion : Decimal.valueOf((String) tier.get('monthlyFee'));

                usagePricingTiers.add(newTier);
            }

            if (!usagePricingTiers.isEmpty()) {
                insert usagePricingTiers;

                String baseUrl = URL.getOrgDomainUrl().toExternalForm();

                for (UsagePricingTier__c tier : usagePricingTiers) {
                    String recordUrl = baseUrl + '/' + tier.Id;
                    System.debug('Created UsagePricingTier record: ' + recordUrl);
                }
            } else {
                System.debug('No UsagePricingTiers to insert.');
            }
        } else {
            System.debug('Unexpected JSON format: ' + deserializedJson);
        }
    }

    // Convenience method to run without parameters
    public static void runForOpportunityProduct(Id oppProdId) {
        parseAndCreateUsagePricingTiers(oppProdId);
    }
}