/**
 * Created by Yury Nistratau on 19.01.2023.
 */

trigger AsyncActionTrigger on Async_Action__e (after insert) {

    AsyncActionTriggerHandler.createListActions(Trigger.new);
}