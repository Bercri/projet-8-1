/**
 * @description Service class for Task (Interaction) management.
 * Used to log interactions with clients (Accounts) or regarding Trips.
 */
public with sharing class TaskService {

    /**
     * @description Logs a call or interaction.
     */
    public static Task logInteraction(Id whatId, String subject, String comments) {
        Task t = new Task(
            WhatId = whatId, // Can be Account, Opportunity, Trip__c, etc.
            Subject = subject,
            Description = comments,
            Status = 'Completed',
            Priority = 'Normal',
            ActivityDate = Date.today()
        );
        DataManager.secureInsert(new List<Task>{t});
        return t;
    }

    /**
     * @description Retrieves interaction history for a specific record safely.
     */
    public static List<Task> getInteractions(Id recordId) {
        String query = 'SELECT Id, Subject, Description, Status, ActivityDate, Owner.Name FROM Task WHERE WhatId = \'' + String.escapeSingleQuotes(recordId) + '\' ORDER BY ActivityDate DESC';
        return (List<Task>) DataManager.secureQuery(query);
    }
}
