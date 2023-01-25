/**
 * Created by Yury Nistratau on 19.01.2023.
 */

public with sharing class AsyncActionExecutor {

    public void execute(AsyncAction action) {
        execute(new List<AsyncAction>{action});
    }

    public void execute(List<AsyncAction> actions) {
        Logger.info('Start AsyncActionExecutor');
        Integer availableQueueableJobsCount = Limits.getLimitQueueableJobs() - Limits.getQueueableJobs();
        List<Async_Action__e> asyncActionEvents = new List<Async_Action__e>();
        for (AsyncAction action : actions) {
            action.setParentTransactionId(Logger.getTransactionId());
            if (availableQueueableJobsCount > 0) {
                new AsyncActionQueueExecutor(new List<AsyncAction>{action}).execute();
            } else {
                asyncActionEvents.add(new Async_Action__e(
                        Body__c = JSON.serialize(action),
                        Type__c = action.getType().getName()
                ));
                List<Database.SaveResult> results = EventBus.publish(asyncActionEvents);
                for (Database.SaveResult sr : results) {
                    if (sr.isSuccess()) {
                        Logger.fine('Async Action Event published successfully.');
                    } else {
                        Logger.error('Async Action Event not published.', sr);
                    }
                }
            }
        }
        Logger.saveLog();
    }
}