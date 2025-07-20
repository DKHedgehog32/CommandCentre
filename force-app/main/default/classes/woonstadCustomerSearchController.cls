public with sharing class woonstadCustomerSearchController {
    @AuraEnabled(cacheable=true)
    public static List<AccountSearchResult> searchAccountsByName(String name) {
        if (String.isBlank(name) || name.length() < 2) {
            return new List<AccountSearchResult>();
        }

        List<String> searchTerms = new List<String>();
        for (String term : name.trim().split('\\s+')) {
            if (!String.isBlank(term)) {
                searchTerms.add(normalize(term));
            }
        }

        List<Account> accounts = [
            SELECT Id, Name, FirstName, MiddleName, LastName, PersonBirthdate, Phone, PersonMobilePhone
            FROM Account
            ORDER BY LastModifiedDate DESC
            LIMIT 200
        ];

        Set<Id> accountIds = new Set<Id>();
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }

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

        Map<Id, Address__c> addressMap = new Map<Id, Address__c>();
        if (!accountToAddressId.isEmpty()) {
            addressMap = new Map<Id, Address__c>([
                SELECT Id, Name, Postal_Code__c, Street__c
                FROM Address__c
                WHERE Id IN :accountToAddressId.values()
            ]);
        }

        Map<Id, List<CaseSummary>> accountToCases = new Map<Id, List<CaseSummary>>();
        for (Case c : [
            SELECT AccountId, CaseNumber, Case_Reason__c, Subject, Description,
                   Request__r.Request_Status__c, Wocas_Subject_Number__c, Status
            FROM Case
            WHERE AccountId IN :accountIds
            AND Status != 'Closed'
            ORDER BY CreatedDate DESC
            LIMIT 500
        ]) {
            if (!accountToCases.containsKey(c.AccountId)) {
                accountToCases.put(c.AccountId, new List<CaseSummary>());
            }

            CaseSummary summary = new CaseSummary();
            summary.CaseNumber = c.CaseNumber;
            summary.CaseReason = c.Case_Reason__c;
            summary.Status = c.Request__r != null ? c.Request__r.Request_Status__c : '';
            summary.Subject = c.Subject;
            summary.Description = c.Description;
            summary.WocasNumber = c.Wocas_Subject_Number__c;

            accountToCases.get(c.AccountId).add(summary);
        }

        List<AccountSearchResult> results = new List<AccountSearchResult>();
        for (Account acc : accounts) {
            String first = acc.FirstName != null ? normalize(acc.FirstName) : '';
            String middle = acc.MiddleName != null ? normalize(acc.MiddleName) : '';
            String last = acc.LastName != null ? normalize(acc.LastName) : '';
            String fullName = acc.Name != null ? normalize(acc.Name) : '';
            String phone = acc.Phone != null ? acc.Phone.replaceAll('[^0-9]', '') : '';
            String mobile = acc.PersonMobilePhone != null ? acc.PersonMobilePhone.replaceAll('[^0-9]', '') : '';
            String birthdate = acc.PersonBirthdate != null ? normalize(String.valueOf(acc.PersonBirthdate)) : '';
            String maskedIban = accountToBankIban.get(acc.Id);

            Address__c addr = null;
            if (accountToAddressId.containsKey(acc.Id)) {
                addr = addressMap.get(accountToAddressId.get(acc.Id));
            }

            String addressName = addr != null && addr.Name != null ? normalize(addr.Name) : '';
            String postal = addr != null && addr.Postal_Code__c != null ? normalize(addr.Postal_Code__c) : '';
            String street = addr != null && addr.Street__c != null ? normalize(addr.Street__c) : '';

            // All searchable fields
            List<String> fields = new List<String>{
                first, middle, last, fullName, phone, mobile, birthdate, 
                maskedIban != null ? normalize(maskedIban) : '',
                addressName, postal, street
            };

            // All terms must match at least one field
            Boolean allMatch = true;
            for (String term : searchTerms) {
                Boolean termFound = false;
                for (String field : fields) {
                    if (!String.isBlank(field) && field.contains(term)) {
                        termFound = true;
                        break;
                    }
                }
                if (!termFound) {
                    allMatch = false;
                    break;
                }
            }

            if (allMatch) {
                AccountSearchResult res = new AccountSearchResult();
                res.Id = acc.Id;
                res.Name = acc.Name;
                res.PersonBirthdate = acc.PersonBirthdate;
                res.Phone = acc.Phone;
                res.PersonMobilePhone = acc.PersonMobilePhone;
                res.MaskedIban = maskedIban;
                if (addr != null) {
                    res.AddressName = addr.Name;
                    res.PostalCode = addr.Postal_Code__c;
                }
                if (accountToCases.containsKey(acc.Id)) {
                    res.Cases = accountToCases.get(acc.Id);
                }
                results.add(res);
            }
        }

        return results;
    }

    private static String normalize(String value) {
        return value != null ? value.toLowerCase().replaceAll('[^a-z0-9]', '') : '';
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
        @AuraEnabled public List<CaseSummary> Cases;
    }

    public class CaseSummary {
        @AuraEnabled public String CaseNumber;
        @AuraEnabled public String CaseReason;
        @AuraEnabled public String Status;
        @AuraEnabled public String Subject;
        @AuraEnabled public String Description;
        @AuraEnabled public String WocasNumber;
    }
}