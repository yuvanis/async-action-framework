/**
 * Created by Yury Nistratau on 19.01.2023.
 */

@IsTest
private class AsyncActionExecutorTest {

    public static final Integer LIMIT_OF_QUEUEABLE_JOBS = 2;

    public with sharing class AsyncActionTestPositive extends AsyncAction {

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

    public with sharing class AsyncActionTestNegative extends AsyncAction {

        public override void execute() {
            insert new Account();
        }

        public override Type getType() {
            return AsyncActionTestNegative.class;
        }
    }

    public with sharing class TestQueue implements QueueService.Queue {

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
        QueueService.setMockQueue(new TestQueue());
        Test.startTest();
        for (Integer i = 0; i < LIMIT_OF_QUEUEABLE_JOBS + 2; i++) {
            AsyncActionExecutor.execute(new AsyncActionTestPositive('Account ' + i));
        }
        Test.stopTest();
        List<Account> accounts = [SELECT Name FROM Account];
        for (Account acc : accounts) {
            System.debug('Account: ' + acc.Name);
        }
        System.assertEquals(LIMIT_OF_QUEUEABLE_JOBS + 2, accounts.size());
    }

    @IsTest
    static void testAsyncActionExecutorList() {
        QueueService.setMockQueue(new TestQueue());
        List<AsyncAction> asyncActions = new List<AsyncAction>();
        for (Integer i = 0; i < LIMIT_OF_QUEUEABLE_JOBS + 2; i++) {
            asyncActions.add(new AsyncActionTestPositive('Account ' + i));
        }
        Test.startTest();
        AsyncActionExecutor.execute(asyncActions);
        Test.stopTest();
        List<Account> accounts = [SELECT Name FROM Account];
        System.assertEquals(LIMIT_OF_QUEUEABLE_JOBS + 2, accounts.size());
    }

    @IsTest
    static void testFailedActions() {
        QueueService.setMockQueue(new TestQueue());
        List<AsyncAction> failedActions = new List<AsyncAction>();
        for (Integer i = 0; i < 5; i++) {
            failedActions.add(new AsyncActionTestNegative().setInterval(1).setRetryCount(3));
        }
        Test.startTest();
        AsyncActionExecutor.execute(failedActions);
        Test.stopTest();
        System.assertEquals(4, failedActions.get(0).getExecutionCount());
    }

    @IsTest
    static void testInvalidInterval() {
        QueueService.setMockQueue(new TestQueue());
        String exceptionStr;
        Test.startTest();
        try {
            AsyncActionExecutor.execute(new AsyncActionTestNegative().setInterval(15));
        } catch (Exception e) {
            exceptionStr = e.getMessage();
        }
        Test.stopTest();
        System.assertEquals(exceptionStr, 'Invalid interval. Please enter an interval from 0 to 10.');
    }

    @IsTest
    static void testQueueDefaultEnqueueJob() {
        AsyncAction action = new AsyncActionTestPositive('Test').setInterval(1).setRetryCount(3);
        Test.startTest();
        new AsyncActionQueueExecutor(new List<AsyncAction>{action}).execute();
        Test.stopTest();
        List<Account> accounts = [SELECT Name FROM Account];
        System.assertEquals(1, accounts.size());
    }

    @IsTest
    static void testQueueDefaultQueueableJobs() {
        AsyncAction action = new AsyncActionTestPositive('Test').setInterval(1).setRetryCount(3);
        Test.startTest();
        AsyncActionExecutor.execute(action);
        Test.stopTest();
        List<Account> accounts = [SELECT Name FROM Account];
        System.assertEquals(1, accounts.size());
    }
}