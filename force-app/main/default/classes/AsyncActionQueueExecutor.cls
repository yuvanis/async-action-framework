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
        if (actions != null && actions.size() > 0) System.enqueueJob(new AsyncActionQueue(actions));
    }

    public with sharing class AsyncActionQueue implements Queueable {

        private Iterator<AsyncAction> actionIterator;

        private AsyncActionQueue(List<AsyncAction> actions) {
            actionIterator = actions.iterator();
        }

        public void execute(QueueableContext param1) {
            AsyncAction action = (AsyncAction) actionIterator.next();
            try {
                action.execute();
            } catch (Exception e) {
                //Log
            }
            if(actionIterator.hasNext()) System.enqueueJob(this);
        }
    }
}