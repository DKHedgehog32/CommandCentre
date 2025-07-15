public with sharing class ExistingDossierService {

    public class DossierResponse {
        @AuraEnabled public String addressId;
        @AuraEnabled public String addressName;
        @AuraEnabled public Id accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public Id caseId;
        @AuraEnabled public String caseNumber;
        @AuraEnabled public String subject;
    }

    @AuraEnabled(cacheable=true)
    public static List<DossierResponse> findCasesByAddressAndPerson(
        String street,
        String houseNumber,
        String postalCode,
        String addressId,
        String lastName,
        Date birthdate,
        String phone
    ) {
        List<DossierResponse> results = new List<DossierResponse>();

        // STAP 1: Adres zoeken op basis van straat, huisnummer en postcode
        List<Address__c> addressMatches = new List<Address__c>();
        if (addressId == null) {
            addressMatches = [
                SELECT Id, Name
                FROM Address__c
                WHERE Street__c = :street
                AND House_Number__c = :houseNumber
                AND Postal_Code__c = :postalCode
            ];

            for (Address__c addr : addressMatches) {
                DossierResponse res = new DossierResponse();
                res.addressId = addr.Id;
                res.addressName = addr.Name;
                results.add(res);
            }
            return results;
        }

        // STAP 2: Accounts ophalen via Account_Address__c
        List<Account_Address__c> accountAddressLinks = [
            SELECT Account__c
            FROM Account_Address__c
            WHERE Address__c = :addressId
        ];

        Set<Id> accountIds = new Set<Id>();
        for (Account_Address__c link : accountAddressLinks) {
            if (link.Account__c != null) {
                accountIds.add(link.Account__c);
            }
        }

        if (accountIds.isEmpty()) return results;

        // STAP 3: Match op achternaam, geboortedatum en telefoonnummer
        List<Account> matchedAccounts = [
            SELECT Id, Name, Phone, PersonMobilePhone, PersonBirthdate, LastName
            FROM Account
            WHERE Id IN :accountIds
        ];

        Account matchingAccount;
        for (Account acc : matchedAccounts) {
            Boolean phoneMatch = (acc.Phone != null && acc.Phone.trim() == phone.trim())
                || (acc.PersonMobilePhone != null && acc.PersonMobilePhone.trim() == phone.trim());
            Boolean nameMatch = acc.LastName != null && acc.LastName.equalsIgnoreCase(lastName);
            Boolean birthdateMatch = acc.PersonBirthdate != null && acc.PersonBirthdate == birthdate;

            if (phoneMatch && nameMatch && birthdateMatch) {
                matchingAccount = acc;
                break;
            }
        }

        if (matchingAccount == null) {
            return results; // Geen match
        }

        // STAP 4: Zoek openstaande cases
        List<Case> openCases = [
            SELECT Id, CaseNumber, Subject, Status
            FROM Case
            WHERE AccountId = :matchingAccount.Id
            AND Status NOT IN ('Closed-Accepted', 'Closed-Rejected')
            ORDER BY CreatedDate DESC
        ];

        if (openCases.isEmpty()) {
            // Geen bestaande case → nieuwe aanmaken
            Case newCase = new Case(
                AccountId = matchingAccount.Id,
                Subject = 'Nieuwe aanmelding via kiosk',
                Origin = 'Kiosk'
            );
            insert newCase;

            DossierResponse newRes = new DossierResponse();
            newRes.accountId = matchingAccount.Id;
            newRes.accountName = matchingAccount.Name;
            newRes.caseId = newCase.Id;
            newRes.caseNumber = newCase.CaseNumber;
            newRes.subject = newCase.Subject;
            results.add(newRes);
        } else {
            for (Case c : openCases) {
                DossierResponse res = new DossierResponse();
                res.accountId = matchingAccount.Id;
                res.accountName = matchingAccount.Name;
                res.caseId = c.Id;
                res.caseNumber = c.CaseNumber;
                res.subject = c.Subject;
                results.add(res);
            }
        }

        return results;
    }
}