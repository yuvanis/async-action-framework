/**
 * Created by Yury Nistratau on 19.01.2023.
 */

public abstract class AsyncAction {

    private String parentTransactionId;

    public void setParentTransactionId(String parentTransactionId) {
        this.parentTransactionId = parentTransactionId;
    }

    public String getParentTransactionId(){
        return parentTransactionId;
    }

    public abstract void execute();
    public abstract Type getType();
}