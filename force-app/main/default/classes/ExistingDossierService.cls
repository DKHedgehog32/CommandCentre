public with sharing class ExistingDossierService {

    public class DossierRequest {
        @InvocableVariable(label='Achternaam')
        public String lastName;
        @InvocableVariable(label='Telefoonnummer')
        public String phone;
    }

    public class DossierResponse {
        @InvocableVariable(label='AccountId')
        public Id accountId;
        @InvocableVariable(label='AccountName')
        public String accountName;
        @InvocableVariable(label='CaseNumber')
        public String caseNumber;
        @InvocableVariable(label='CaseSubject')
        public String subject;
        @InvocableVariable(label='CaseId')
        public Id caseId;
    }

    @AuraEnabled(cacheable=true)
    public static List<DossierResponse> findMatchingCases(String lastName, String phone) {
        List<Account> matchedAccounts = [
            SELECT Id, Name, Phone
            FROM Account
            WHERE LastName = :lastName
        ];

        List<DossierResponse> results = new List<DossierResponse>();

        for (Account acc : matchedAccounts) {
            if (acc.Phone != null && acc.Phone.trim() == phone.trim()) {
                List<Case> relatedCases = [
                    SELECT Id, CaseNumber, Subject, Status
                    FROM Case
                    WHERE AccountId = :acc.Id
                    AND Status != 'Closed'
                    ORDER BY CreatedDate DESC
                ];

                if (relatedCases.isEmpty()) {
                    Case newCase = new Case(
                        AccountId = acc.Id,
                        Subject = 'Nieuwe aanmelding via kiosk',
                        Origin = 'Kiosk'
                    );
                    insert newCase;

                    results.add(buildResponse(acc, newCase));
                } else {
                    for (Case c : relatedCases) {
                        results.add(buildResponse(acc, c));
                    }
                }

                break; // Only allow one match based on phone
            }
        }

        return results;
    }

    private static DossierResponse buildResponse(Account acc, Case c) {
        DossierResponse res = new DossierResponse();
        res.accountId = acc.Id;
        res.accountName = acc.Name;
        res.caseId = c.Id;
        res.caseNumber = c.CaseNumber;
        res.subject = c.Subject;
        return res;
    }
}