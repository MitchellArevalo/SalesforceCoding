global with sharing class WMSClosedTransfers_BatchClass implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful{
    

    public static List<String> sendToCorreos = new list<String> { 'soportedigital2@impormedical.com.co' , 'dirdigital@impormedical.com.co' , 'soportedigital@impormedical.com.co'};
    public static Map<String, String> docEntriesMap = new Map<String, String>();
    public static Map<String, String> docEntriesTrasladoMap = new Map<String, String>();
    public static List<String> transferFromSAP = new List<String>();
    public static List<Transferencia_de_stock__c> transfersToUpdate = new List<Transferencia_de_stock__c>();

    global Database.QueryLocator start(Database.BatchableContext bc) {
        // collect the batches of records or objects to be passed to execute
        // Product2 updatePrueba = new Product2(Id = productPrueba, Sincronizando_inventario__c = true);
        // update updatePrueba;

        String queryTransfers = 'SELECT Id, Name, DocEntry_Traslado__c, Enviar_a_WMS__c, Path_Transferencia__c '+
        'FROM Transferencia_de_stock__c WHERE Path_Transferencia__c = \'Solicitud de traslado\' AND Enviar_a_WMS__c = true AND 	DocEntry_Traslado__c != null'
         + (Test.isRunningTest() ? ' LIMIT 1': '') ;
        System.debug('Tranferencias desde el query desde el batchQuery: ' + queryTransfers);
        return Database.getQueryLocator(queryTransfers);
    }


    global void execute(Database.BatchableContext bc, List<Transferencia_de_stock__c> transfersQuery){

        system.debug('lista del query: ' + transfersQuery);
        for (Transferencia_de_stock__c transfer : transfersQuery) {
            docEntriesMap.put(transfer.DocEntry_Traslado__c, transfer.Id);
        }

        //Conexión a SAP
        ConexionSAP conectSAP = new ConexionSAP();
        HttpResponse login = conectSAP.loginProduction();
        // HttpResponse login = conectSAP.loginPruebas();
        
        if(login.getStatusCode() != 200){
           EnviarCorreo.enviar('Error de conexión SF-SAP', 'Ocurrió un error al intentar conectarse a SAP desde WMSClosedTransfers_BatchClass' + 
           '<br> Este es el body de la respuesta: <br> ' + login.getBody(), sendToCorreos);
           return;
        }
        
        Deserializaciones.LoginSAP sesion = new Deserializaciones.LoginSAP();
        sesion = (Deserializaciones.LoginSAP)JSON.deserialize(login.getBody(),Deserializaciones.LoginSAP.class);
        
        
        HttpResponse response = GetRelatedTransfer_API.getTransfer(sesion.SessionId); 
        if(response.getStatusCode() != 200){
            EnviarCorreo.enviar('Error al obtener las transferencias abiertas', 'Ocurrió un error al intentar obtener las transferencias abiertas en SAP desde la clase: WMSClosedTransfers_BatchClass '+
            '<br> Este es el body del response: <br> '+ response.getBody(), sendToCorreos);
            return;
        } 
        Deserializaciones.OpenTransfers openTranfer = new Deserializaciones.OpenTransfers();
        openTranfer = (Deserializaciones.OpenTransfers)JSON.deserialize(response.getBody(),Deserializaciones.OpenTransfers.class);
        
        system.debug('resultado de la peticion: ' + openTranfer);
        for (integer i = 0; i < openTranfer.value.size(); i++) {
           
            if (docEntriesMap.containsKey(String.ValueOf(openTranfer.value[i].DocEntry))) {
                System.debug('Entró a la asignación');
                transferFromSAP.add(String.valueOf(openTranfer.value[i].DocEntry));
            }
        }

        for (String transferOpen : docEntriesMap.keySet()) {
            system.debug('iteracion del map de docEntries: ' + transferOpen);
            system.debug('resultado del if: ' + !transferFromSAP.contains(transferOpen));
            
            if (!transferFromSAP.contains(transferOpen)) {
                system.debug('Entra al DML');
                Transferencia_de_stock__c transfer = new Transferencia_de_stock__c();
                transfer.id = docEntriesMap.get(transferOpen);
                transfer.Path_Transferencia__c = 'Completado';
                transfersToUpdate.add(transfer);
                System.debug('DML de transferencia: ' + transfer);
            }
        }

        if (!transfersToUpdate.isEmpty()) {
            update transfersToUpdate;
        }

    }  

    global void finish(Database.BatchableContext bc){

    // System.debug('Transferencias actualizadas desde el batch class');

    // Product2 updatePrueba = new Product2(Id = productPrueba, Sincronizando_inventario__c = false);
    //     update updatePrueba;

    }
}