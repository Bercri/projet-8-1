// Debug Script to Instantiate Trip Logic
System.debug('--- START DEBUG ---');
try {
    // 1. Create Account
    Account acc = new Account(Name = 'Debug Account');
    insert acc;
    System.debug('Account created: ' + acc.Id);

    // 2. Create Opportunity (Prospecting)
    Opportunity opp = new Opportunity(
        Name = 'Debug Trip Opportunity',
        StageName = 'Prospecting',
        CloseDate = Date.today().addDays(10),
        AccountId = acc.Id,
        Destination__c = 'Tokyo',
        Start_Date__c = Date.today().addDays(30),
        End_Date__c = Date.today().addDays(40),
        Number_of_Participants__c = 5,
        Amount = 5000
    );
    insert opp;
    System.debug('Opportunity created: ' + opp.Id);

    // 3. Update to Closed Won (Trigger should fire)
    opp.StageName = 'Closed Won';
    update opp;
    System.debug('Opportunity updated to Closed Won');

    // 4. Query Trip
    List<Trip__c> trips = [SELECT Id, Name, Status__c FROM Trip__c WHERE Opportunity__c = :opp.Id];
    System.debug('Trips found: ' + trips.size());
    if (!trips.isEmpty()) {
        System.debug('Trip Details: ' + trips[0]);
    } else {
        System.debug('NO TRIP CREATED - Checking Permissions?');
        // Check manually if field is createable for current user
        System.debug('Trip__c Createable: ' + Schema.sObjectType.Trip__c.isCreateable());
        System.debug('Trip__c.Name Createable: ' + Schema.sObjectType.Trip__c.fields.Name.isCreateable());
    }

} catch (Exception e) {
    System.debug('EXCEPTION: ' + e.getMessage());
    System.debug(e.getStackTraceString());
}
System.debug('--- END DEBUG ---');
