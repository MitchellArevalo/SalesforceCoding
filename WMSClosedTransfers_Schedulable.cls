public with sharing class WMSClosedTransfers_Schedulable implements Schedulable {

    public WMSClosedTransfers_Schedulable(){
        System.debug('Entró al scheduable');
    }
    public void execute(SchedulableContext sc){

        WMSClosedTransfers_BatchClass batchJob = new WMSClosedTransfers_BatchClass();
        ID batchprocessid = Database.executeBatch(batchJob);
    }

}