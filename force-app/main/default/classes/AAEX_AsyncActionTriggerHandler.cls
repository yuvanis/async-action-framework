/**
 * Created by Yury Nistratau on 19.01.2023.
 */

public with sharing class AAEX_AsyncActionTriggerHandler extends TRGF_TriggerHandler {

    public override void onAfterInsert(List<SObject> newList) {
        createListActions(newList);
    }

    private static void createListActions(List<Async_Action__e> events) {
        Logger.info('Handle action platform events in AAEX_AsyncActionTriggerHandler');
        Logger.saveLog();
        AAEX_AsyncActionQueueExecutor actionQueueExecutor = new AAEX_AsyncActionQueueExecutor();
        for (Async_Action__e event : events) {
            AAEX_AsyncAction action = (AAEX_AsyncAction) JSON.deserialize(event.Body__c, Type.forName(event.Type__c));
            actionQueueExecutor.addAction(action);
        }
            actionQueueExecutor.execute();
    }
}