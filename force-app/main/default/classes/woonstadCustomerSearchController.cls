public with sharing class woonstadCustomerSearchController {
    @AuraEnabled(cacheable=true)
    public static List<AccountSearchResult> searchAccountsByName(String name) {
        List<Account> accounts = [
            SELECT Id, Name, PersonBirthdate, Phone
            FROM Account
            WHERE Name LIKE :('%' + name + '%')
            LIMIT 10
        ];

        Set<Id> accountIds = new Set<Id>();
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }

        // Query Bank Accounts for matching Accounts
        Map<Id, String> accountToBankIban = new Map<Id, String>();
        for (Bank_Account__c ba : [
            SELECT Account__c, IBAN__c
            FROM Bank_Account__c
            WHERE Account__c IN :accountIds
        ]) {
            if (String.isNotBlank(ba.IBAN__c) && ba.IBAN__c.length() >= 4) {
                String masked = '*' + ba.IBAN__c.right(4);
                accountToBankIban.put(ba.Account__c, masked);
            }
        }

        // Find primary, active address relations
        Map<Id, Id> accountToAddressId = new Map<Id, Id>();
        for (Account_Address__c aa : [
            SELECT Account__c, Address__c
            FROM Account_Address__c
            WHERE Account__c IN :accountIds
            AND Is_Primary__c = true
            AND Active__c = true
        ]) {
            accountToAddressId.put(aa.Account__c, aa.Address__c);
        }

        // Fetch address details
        Map<Id, Address__c> addressMap = new Map<Id, Address__c>();
        if (!accountToAddressId.isEmpty()) {
            addressMap = new Map<Id, Address__c>([
                SELECT Id, Name, Postal_Code__c
                FROM Address__c
                WHERE Id IN :accountToAddressId.values()
            ]);
        }

        // Combine results
        List<AccountSearchResult> results = new List<AccountSearchResult>();
        for (Account acc : accounts) {
            AccountSearchResult res = new AccountSearchResult();
            res.Id = acc.Id;
            res.Name = acc.Name;
            res.PersonBirthdate = acc.PersonBirthdate;
            res.Phone = acc.Phone;
            res.MaskedIban = accountToBankIban.get(acc.Id);

            Id addrId = accountToAddressId.get(acc.Id);
            if (addrId != null && addressMap.containsKey(addrId)) {
                Address__c addr = addressMap.get(addrId);
                res.AddressName = addr.Name;
                res.PostalCode = addr.Postal_Code__c;
            }

            results.add(res);
        }

        return results;
    }

    public class AccountSearchResult {
        @AuraEnabled public Id Id;
        @AuraEnabled public String Name;
        @AuraEnabled public Date PersonBirthdate;
        @AuraEnabled public String Phone;
        @AuraEnabled public String MaskedIban;
        @AuraEnabled public String AddressName;
        @AuraEnabled public String PostalCode;
    }
}