/**
 * Created by Yury Nistratau on 19.01.2023.
 */

trigger AAEX_AsyncActionTrigger on Async_Action__e (after insert) {

    TRGF_TriggerHandlersProvider.execute();
}