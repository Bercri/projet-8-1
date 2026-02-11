// Debug Script: Insert Directly as Closed Won
System.debug('--- START DEBUG DIRECT INSERT ---');
try {
    Account acc = new Account(Name = 'Debug Direct Account');
    insert acc;

    Opportunity opp = new Opportunity(
        Name = 'Debug Direct Closed Won',
        StageName = 'Closed Won', // Direct Closed Won
        CloseDate = Date.today(),
        AccountId = acc.Id,
        Destination__c = 'Berlin',
        Start_Date__c = Date.today().addDays(30),
        End_Date__c = Date.today().addDays(40),
        Number_of_Participants__c = 5,
        Amount = 5000
    );
    insert opp;
    System.debug('Opportunity inserted as Closed Won: ' + opp.Id);

    List<Trip__c> trips = [SELECT Id, Name, Status__c FROM Trip__c WHERE Opportunity__c = :opp.Id];
    if (!trips.isEmpty()) {
        System.debug('SUCCESS: Trip Created: ' + trips[0]);
    } else {
        System.debug('FAILURE: No Trip Created on Direct Insert');
    }

} catch (Exception e) {
    System.debug('EXCEPTION: ' + e.getMessage());
}
System.debug('--- END DEBUG ---');
