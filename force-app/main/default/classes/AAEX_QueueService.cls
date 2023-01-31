/**
 * Created by Yury Nistratau on 27.01.2023.
 */

public with sharing class AAEX_QueueService {

    private static Queue queueInstance;

    public static Queue getQueueInstance() {
        if (queueInstance == null) queueInstance = new QueueDefault();
        return queueInstance;
    }

    public static void setMockQueue(Queue queue) {
        queueInstance = queue;
    }

    public static void enqueueJob(Queueable queueable, Integer delay) {
        getQueueInstance().enqueueJob(queueable, delay);
    }

    public static Integer getAvailableQueueableJobs() {
        return getQueueInstance().getAvailableQueueableJobs();
    }

    public interface Queue {
        void enqueueJob(Queueable queueable, Integer delay);
        Integer getAvailableQueueableJobs();
    }

    public class QueueDefault implements Queue {

        public void enqueueJob(Queueable queueable, Integer delay) {
            System.enqueueJob(queueable);
        }

        public Integer getAvailableQueueableJobs() {
            return Limits.getLimitQueueableJobs() - Limits.getQueueableJobs();
        }
    }
}