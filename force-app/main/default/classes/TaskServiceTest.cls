@isTest
private class TaskServiceTest {

    @testSetup
    static void setup() {
        Account acc = new Account(Name = 'Task Test Account');
        insert acc;
    }

    @isTest
    static void testLogInteraction() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        Task t = TaskService.logInteraction(acc.Id, 'Call', 'Discussed contract');
        Test.stopTest();

        System.assertNotEquals(null, t.Id);
        System.assertEquals(acc.Id, t.WhatId);
        System.assertEquals('Call', t.Subject);
        System.assertEquals('Discussed contract', t.Description);
        System.assertEquals('Completed', t.Status);
    }

    @isTest
    static void testGetInteractions() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        TaskService.logInteraction(acc.Id, 'Email', 'Sent proposal');
        TaskService.logInteraction(acc.Id, 'Call', 'Follow up');
        
        Test.startTest();
        List<Task> tasks = TaskService.getInteractions(acc.Id);
        Test.stopTest();

        System.assertEquals(2, tasks.size());
    }
}
