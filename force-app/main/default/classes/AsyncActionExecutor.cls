/**
 * Created by Yury Nistratau on 19.01.2023.
 */

public with sharing class AsyncActionExecutor {

    public void execute(AsyncAction action) {
        execute(new List<AsyncAction>{action});
    }

    public void execute(List<AsyncAction> actions) {
        List<Async_Action__e> asyncActionEvents = new List<Async_Action__e>();
        for (AsyncAction action : actions) {
            asyncActionEvents.add(new Async_Action__e(
                    Body__c = JSON.serialize(action),
                    Type__c = action.getType().getName()
            ));
        }
        List<Database.SaveResult> results = EventBus.publish(asyncActionEvents);
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                System.debug('Successfully published event.');
            } else {
                for (Database.Error err : sr.getErrors()) {
                    System.debug('Error returned: ' +
                            err.getStatusCode() +
                            ' - ' +
                            err.getMessage());
                }
            }
        }
    }
}