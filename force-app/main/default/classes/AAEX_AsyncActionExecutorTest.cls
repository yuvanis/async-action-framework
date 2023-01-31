/**
 * Created by Yury Nistratau on 19.01.2023.
 */

@IsTest
private class AAEX_AsyncActionExecutorTest {

    public static final Integer LIMIT_OF_QUEUEABLE_JOBS = 2;

    public with sharing class AsyncActionTestPositive extends AAEX_AsyncAction {

        private String accountName;

        private AsyncActionTestPositive(String accountName) {
            this.accountName = accountName;
        }

        public override void execute() {
            insert new Account(
                    Name = accountName
            );
        }

        public override Type getType() {
            return AsyncActionTestPositive.class;
        }
    }

    public with sharing class AsyncActionTestNegative extends AAEX_AsyncAction {

        public override void execute() {
            insert new Account();
        }

        public override Type getType() {
            return AsyncActionTestNegative.class;
        }
    }

    public with sharing class TestQueue implements AAEX_QueueService.Queue {

        private Integer availableJobsCount = LIMIT_OF_QUEUEABLE_JOBS;

        public void enqueueJob(Queueable queueable, Integer delay) {
            queueable.execute(null);
            availableJobsCount--;
        }

        public Integer getAvailableQueueableJobs() {
            return availableJobsCount;
        }
    }

    @IsTest
    static void testAsyncActionExecutor() {
        AAEX_QueueService.setMockQueue(new TestQueue());
        Test.startTest();
        for (Integer i = 0; i < LIMIT_OF_QUEUEABLE_JOBS + 2; i++) {
            AAEX_AsyncActionExecutor.execute(new AsyncActionTestPositive('Account ' + i));
        }
        Test.stopTest();
        List<Account> accounts = [SELECT Name FROM Account];
        System.assertEquals(LIMIT_OF_QUEUEABLE_JOBS + 2, accounts.size());
    }

    @IsTest
    static void testAsyncActionExecutorList() {
        AAEX_QueueService.setMockQueue(new TestQueue());
        List<AAEX_AsyncAction> asyncActions = new List<AAEX_AsyncAction>();
        for (Integer i = 0; i < LIMIT_OF_QUEUEABLE_JOBS + 2; i++) {
            asyncActions.add(new AsyncActionTestPositive('Account ' + i));
        }
        Test.startTest();
        AAEX_AsyncActionExecutor.execute(asyncActions);
        Test.stopTest();
        List<Account> accounts = [SELECT Name FROM Account];
        System.assertEquals(LIMIT_OF_QUEUEABLE_JOBS + 2, accounts.size());
    }

    @IsTest
    static void testFailedActions() {
        AAEX_QueueService.setMockQueue(new TestQueue());
        List<AAEX_AsyncAction> failedActions = new List<AAEX_AsyncAction>();
        for (Integer i = 0; i < 5; i++) {
            failedActions.add(new AsyncActionTestNegative().setInterval(1).setRetryCount(3));
        }
        Test.startTest();
        AAEX_AsyncActionExecutor.execute(failedActions);
        Test.stopTest();
        System.assertEquals(4, failedActions.get(0).getExecutionCount());
    }

    @IsTest
    static void testInvalidInterval() {
        AAEX_QueueService.setMockQueue(new TestQueue());
        String exceptionStr;
        Test.startTest();
        try {
            AAEX_AsyncActionExecutor.execute(new AsyncActionTestNegative().setInterval(15));
        } catch (Exception e) {
            exceptionStr = e.getMessage();
        }
        Test.stopTest();
        System.assertEquals(exceptionStr, 'Invalid interval. Please enter an interval from 0 to 10.');
    }

    @IsTest
    static void testQueueDefaultEnqueueJob() {
        AAEX_AsyncAction action = new AsyncActionTestPositive('Test').setInterval(1).setRetryCount(3);
        Test.startTest();
        new AAEX_AsyncActionQueueExecutor(new List<AAEX_AsyncAction>{action}).execute();
        Test.stopTest();
        List<Account> accounts = [SELECT Name FROM Account];
        System.assertEquals(1, accounts.size());
    }

    @IsTest
    static void testQueueDefaultQueueableJobs() {
        AAEX_AsyncAction action = new AsyncActionTestPositive('Test').setInterval(1).setRetryCount(3);
        Test.startTest();
        AAEX_AsyncActionExecutor.execute(action);
        Test.stopTest();
        List<Account> accounts = [SELECT Name FROM Account];
        System.assertEquals(1, accounts.size());
    }
}