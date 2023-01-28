/**
 * Created by Yury Nistratau on 19.01.2023.
 */

public with sharing class AsyncActionQueueExecutor {

    private List<AsyncAction> actions;

    public AsyncActionQueueExecutor() {
        actions = new List<AsyncAction>();
    }

    public AsyncActionQueueExecutor(List<AsyncAction> actions) {
        this.actions = actions;
    }

    public void addAction(AsyncAction action) {
        actions.add(action);
    }

    public void execute() {
        if (actions != null && actions.size() > 0) QueueService.enqueueJob(new AsyncActionQueue(actions), actions.get(0).getInterval());
    }

    public with sharing class AsyncActionQueue implements Queueable {

        private List<AsyncAction> actions = new List<AsyncAction>();
        private List<AsyncAction> failedActions = new List<AsyncAction>();
        private Integer currentIndex = 0;

        private AsyncActionQueue(List<AsyncAction> actions) {
            this.actions = actions;
        }

        public void execute(QueueableContext queueableContext) {
            AsyncAction action = actions.get(currentIndex);
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
                QueueService.enqueueJob(this,actions[currentIndex].getInterval());
            } else {
                if (failedActions.size() > 0) new AsyncActionQueueExecutor(failedActions).execute();
            }
            Logger.saveLog();
        }
    }
}