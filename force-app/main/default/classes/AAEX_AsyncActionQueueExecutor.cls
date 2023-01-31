/**
 * Created by Yury Nistratau on 19.01.2023.
 */

public with sharing class AAEX_AsyncActionQueueExecutor {

    private List<AAEX_AsyncAction> actions;

    public AAEX_AsyncActionQueueExecutor() {
        actions = new List<AAEX_AsyncAction>();
    }

    public AAEX_AsyncActionQueueExecutor(List<AAEX_AsyncAction> actions) {
        this.actions = actions;
    }

    public void addAction(AAEX_AsyncAction action) {
        actions.add(action);
    }

    public void execute() {
        if (actions != null && actions.size() > 0) AAEX_QueueService.enqueueJob(new AsyncActionQueue(actions), actions.get(0).getInterval());
    }

    public with sharing class AsyncActionQueue implements Queueable {

        private List<AAEX_AsyncAction> actions = new List<AAEX_AsyncAction>();
        private List<AAEX_AsyncAction> failedActions = new List<AAEX_AsyncAction>();
        private Integer currentIndex = 0;

        private AsyncActionQueue(List<AAEX_AsyncAction> actions) {
            this.actions = actions;
        }

        public void execute(QueueableContext queueableContext) {
            AAEX_AsyncAction action = actions.get(currentIndex);
            Logger.info('Async Action: ' + action.getType().getName());
            Logger.info(JSON.serializePretty(action));
            try {
                Logger.setParentLogTransactionId(action.getParentTransactionId());
                action.run();
                Logger.info('Async Action: ' + action.getType().getName() + ' executed successfully.');
            } catch (Exception e) {
                Logger.error(e.getMessage());
                if (action.isRetryAvailable()) {
                    failedActions.add(action);
                } else {
                    action.retryFailedHandle(e);
                }
            }
            Integer maxIndex = actions.size() - 1;
            if (currentIndex < maxIndex) {
                Logger.info('Enqueue next Async Action');
                currentIndex++;
                AAEX_QueueService.enqueueJob(this,actions[currentIndex].getInterval());
            } else {
                if (failedActions.size() > 0) new AAEX_AsyncActionQueueExecutor(failedActions).execute();
            }
            Logger.saveLog();
        }
    }
}