/**
 * Created by Yury Nistratau on 19.01.2023.
 */

public abstract class AAEX_AsyncAction {

    private String parentTransactionId;
    private Integer retryLimit = 0;
    private Integer retryIntervalMin = 0;
    private Integer executionCount = 0;
    private Datetime lastExecutedDT;

    public void setParentTransactionId(String parentTransactionId) {
        this.parentTransactionId = parentTransactionId;
    }

    public String getParentTransactionId(){
        return parentTransactionId;
    }

    public AAEX_AsyncAction setRetryCount(Integer retryCount) {
        this.retryLimit = retryCount;
        return this;
    }

    public AAEX_AsyncAction setInterval(Integer retryIntervalMin) {
        if (retryIntervalMin < 0 || retryIntervalMin > 10) {
            throw new AAEX_AsyncActionException('Invalid interval. Please enter an interval from 0 to 10.');
        } else {
            this.retryIntervalMin = retryIntervalMin;
        }
        return this;
    }

    public Integer getInterval() {
        if (retryIntervalMin == 0 || lastExecutedDT == null) {
            return 0;
        } else {
            Long executionDeltaMin = (System.now().getTime() - lastExecutedDT.getTime()) / (1000 * 60);
            return retryIntervalMin - executionDeltaMin.intValue();
        }
    }

    public Integer getExecutionCount() {
        return executionCount;
    }

    public Boolean isRetryAvailable() {
        return executionCount <= retryLimit;
    }

    public void run() {
        executionCount++;
        lastExecutedDT = System.now();
        execute();
    }

    public virtual void retryFailedHandle(Exception e) {
    }

    public abstract void execute();
    public abstract Type getType();
}