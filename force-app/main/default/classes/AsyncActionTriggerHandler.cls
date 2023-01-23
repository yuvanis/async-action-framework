/**
 * Created by Yury Nistratau on 19.01.2023.
 */

public with sharing class AsyncActionTriggerHandler {

    public static void createListActions(List<Async_Action__e> events) {
        AsyncActionQueueExecutor actionQueueExecutor = new AsyncActionQueueExecutor();
        for (Async_Action__e event : events) {
            AsyncAction action = (AsyncAction) JSON.deserialize(event.Body__c, Type.forName(event.Type__c));
            actionQueueExecutor.addAction(action);
        }
        actionQueueExecutor.execute();
    }
}