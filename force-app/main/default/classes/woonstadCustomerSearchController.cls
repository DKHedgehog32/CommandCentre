public with sharing class woonstadCustomerSearchController {
    @AuraEnabled(cacheable=true)
    public static List<AccountSearchResult> searchAccountsByName(String name) {
        String search = name != null ? name.toLowerCase().replaceAll('[^a-zA-Z0-9]', '') : '';
        if (String.isBlank(search)) {
            return new List<AccountSearchResult>();
        }

        // Step 1: Get matching Accounts
        List<Account> accounts = [
            SELECT Id, Name, PersonBirthdate, Phone, PersonMobilePhone
            FROM Account
            ORDER BY LastModifiedDate DESC
            LIMIT 200
        ];

        Set<Id> accountIds = new Set<Id>();
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }

        // Step 2: Fetch Bank Accounts
        Map<Id, String> accountToBankIban = new Map<Id, String>();
        for (Bank_Account__c ba : [
            SELECT Account__c, IBAN__c
            FROM Bank_Account__c
            WHERE Account__c IN :accountIds
        ]) {
            if (String.isNotBlank(ba.IBAN__c) && ba.IBAN__c.length() >= 4) {
                accountToBankIban.put(ba.Account__c, '*' + ba.IBAN__c.right(4));
            }
        }

        // Step 3: Fetch Account_Address links
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

        // Step 4: Fetch Address details
        Map<Id, Address__c> addressMap = new Map<Id, Address__c>();
        if (!accountToAddressId.isEmpty()) {
            addressMap = new Map<Id, Address__c>([
                SELECT Id, Name, Postal_Code__c
                FROM Address__c
                WHERE Id IN :accountToAddressId.values()
            ]);
        }

        // Step 5: Filter and build results
        List<AccountSearchResult> results = new List<AccountSearchResult>();
        for (Account acc : accounts) {
            String phone = acc.Phone != null ? acc.Phone.replaceAll('[^0-9]', '') : '';
            String mobile = acc.PersonMobilePhone != null ? acc.PersonMobilePhone.replaceAll('[^0-9]', '') : '';
            String birthdate = acc.PersonBirthdate != null ? String.valueOf(acc.PersonBirthdate) : '';
            String maskedIban = accountToBankIban.get(acc.Id);

            Address__c addr = null;
            if (accountToAddressId.containsKey(acc.Id)) {
                addr = addressMap.get(accountToAddressId.get(acc.Id));
            }

            String addressName = addr != null && addr.Name != null ? addr.Name.toLowerCase() : '';
            String postal = addr != null && addr.Postal_Code__c != null
                ? addr.Postal_Code__c.replaceAll('\\s+', '').toUpperCase()
                : '';

            // Create normalized string for search
            String composite = (
                acc.Name +
                phone +
                mobile +
                birthdate +
                (maskedIban != null ? maskedIban : '') +
                addressName +
                postal
            ).toLowerCase();

            if (composite.contains(search)) {
                AccountSearchResult res = new AccountSearchResult();
                res.Id = acc.Id;
                res.Name = acc.Name;
                res.PersonBirthdate = acc.PersonBirthdate;
                res.Phone = acc.Phone;
                res.PersonMobilePhone = acc.PersonMobilePhone;
                res.MaskedIban = maskedIban;
                if (addr != null) {
                    res.AddressName = addr.Name;
                    res.PostalCode = postal;
                }
                results.add(res);
            }
        }

        return results;
    }

    public class AccountSearchResult {
        @AuraEnabled public Id Id;
        @AuraEnabled public String Name;
        @AuraEnabled public Date PersonBirthdate;
        @AuraEnabled public String Phone;
        @AuraEnabled public String PersonMobilePhone;
        @AuraEnabled public String MaskedIban;
        @AuraEnabled public String AddressName;
        @AuraEnabled public String PostalCode;
    }
}