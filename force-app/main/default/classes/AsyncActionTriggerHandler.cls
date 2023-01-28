/**
 * Created by Yury Nistratau on 19.01.2023.
 */

public with sharing class AsyncActionTriggerHandler extends TRGF_TriggerHandler {

    public override void onAfterInsert(List<SObject> newList) {
        createListActions(newList);
    }

    private static void createListActions(List<Async_Action__e> events) {
        Logger.info('Handle action platform events in AsyncActionTriggerHandler');
        Logger.saveLog();
        System.debug('AsyncActionTriggerHandler in Test');
        AsyncActionQueueExecutor actionQueueExecutor = new AsyncActionQueueExecutor();
        for (Async_Action__e event : events) {
            AsyncAction action = (AsyncAction) JSON.deserialize(event.Body__c, Type.forName(event.Type__c));
            System.debug('Action Trigger Handler Test: ' + JSON.serializePretty(action));
            actionQueueExecutor.addAction(action);
        }
        actionQueueExecutor.execute();
    }
}