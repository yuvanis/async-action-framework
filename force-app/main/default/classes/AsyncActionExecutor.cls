/**
 * Created by Yury Nistratau on 19.01.2023.
 */

public with sharing class AsyncActionExecutor {

    public static void execute(AsyncAction action) {
        execute(new List<AsyncAction>{action});
    }

    public static void execute(List<AsyncAction> actions) {
        Logger.info('Start AsyncActionExecutor');
        List<Async_Action__e> asyncActionEvents = new List<Async_Action__e>();
        for (AsyncAction action : actions) {
            action.setParentTransactionId(Logger.getTransactionId());
            if (QueueService.getAvailableQueueableJobs() > 0) {
                new AsyncActionQueueExecutor(new List<AsyncAction>{action}).execute();
            } else {
                asyncActionEvents.add(new Async_Action__e(
                        Body__c = JSON.serialize(action),
                        Type__c = action.getType().getName()
                ));
            }
        }
        if (asyncActionEvents.size() > 0) {
            List<Database.SaveResult> results = EventBus.publish(asyncActionEvents);
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {
                    Logger.fine('Async Action Event published successfully.');
                } else {
                    Logger.error('Async Action Event not published.', sr);
                }
            }
        }
        Logger.saveLog();
    }
}