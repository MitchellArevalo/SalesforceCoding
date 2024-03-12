//Test: TestSerialesLotesLWC
public with sharing class addSerialesLotesLWC_Future {
    public static List<String> correos= new List<String>{'dirdigital@impormedical.com.co', 'soportedigital2@impormedical.com.co', 'soportedigital@impormedical.com.co'};
    public static String body = 'Ocurrió un error al intentar conectarse con SAP desde la clase: addSerialesLotesLWC_Future';
    public static String asunto = 'Ocurrio un error al intentar conectase con SAP';
    public static Boolean foundBatch = false;
    public static Boolean foundQuantity = false;
    
    @future(callout = true)
    public static void ConsultaLote(String Lote, String Cantidad, String objetoActualizar){

        data dataObject = (data)JSON.deserialize(objetoActualizar, data.class);
        List<String> camposSelect = new List<String>();
        try {
            system.debug(dataObject.ObjetoActualizar);
            SObjectType sObjType = ((SObject) Type.forName(dataObject.ObjetoActualizar).newInstance()).getSObjectType();
            
            sObject record2Update = sObjType.newSObject();
            record2Update.put('Id', dataObject.Id);
            record2Update.put(dataObject.Campo, dataObject.ValorCampo);

            camposSelect.add(dataObject.ProductField);
            camposSelect.add(dataObject.BodegaField);

            List<sObject> sObjectQuery = getObjectById(dataObject.Id, camposSelect);

            String idProduct = String.valueOf(sObjectQuery[0].get(dataObject.ProductField));

            Product2 producto = [SELECT Id, Name FROM Product2 WHERE Id =: idProduct];
    
           //Conexión a SAP
            ConexionSAP conectSAP = new ConexionSAP();
            // HttpResponse login = conectSAP.loginProduction();
            HttpResponse login = conectSAP.loginPruebas();
    
            if (login.getStatusCode() != 200) {
                EnviarCorreo.enviar('Error al conectarse con SAP: addSerialesLotesLWC_Future', 'Clase: addSerialesLotesLWC_Future <br> body de la respuesta: ' + 
                login.getBody(), correos);
                return;    
            }
            System.debug('Inicio de sesión en SAP exitoso');
            //Deserializo el inicio de sesión
            Deserializaciones.LoginSAP sesion = (Deserializaciones.LoginSAP)JSON.deserialize(login.getBody(),Deserializaciones.LoginSAP.class);

            String bodegaSearch = String.valueOf(sObjectQuery[0].get(dataObject.BodegaField));
            String referenciaSearch = producto.Name;

            BatchSerialNumbers_API getLotesSeriales = new BatchSerialNumbers_API();
            HttpResponse batchSerialResponse = getLotesSeriales.getLotes(sesion.SessionId, bodegaSearch.split(' - ')[0],referenciaSearch);
    
            if (batchSerialResponse.getStatusCode() != 200) {
                EnviarCorreo.enviar('Error al obtener los lotes/seriales en la clase: addSerialesLotesLWC_Future', 'Clase: addSerialesLotesLWC_Future <br> body de la respuesta: ' + 
                batchSerialResponse.getBody() + '<br> Id del registro: ' + dataObject.Id, correos);
                return;
            }
    
            Deserializaciones.BatchProducts batchnumbers = new Deserializaciones.BatchProducts();
            batchnumbers = (Deserializaciones.BatchProducts)JSON.deserialize(batchSerialResponse.getBody(),Deserializaciones.BatchProducts.class);

            System.debug('BatchNumbers consultados: ' + batchnumbers.value);

            for (Integer i = 0; i < batchnumbers.value.size(); i++) {
                if (batchnumbers.value[i].BatchNum == Lote) {
                    foundBatch = true;
                    if (Integer.valueOf(Cantidad) <= Integer.valueOf(Math.round(batchnumbers.value[i].Quantity))) {
                        foundQuantity = true;
                    }
                    
                }
            }

            System.debug('Lote encontrado: ' + foundBatch);
            System.debug('Cantidad correcta: ' + foundQuantity);

            if (foundBatch && foundQuantity) {
                
                update record2Update;
                AddBatchSerialNumber__e addEvent = new AddBatchSerialNumber__e();
                addEvent.PT_id__c = dataObject.Id;
                addEvent.Status__c = 'Successful';
    
                Database.SaveResult results = EventBus.publish(addEvent);
            
            }

            if (!foundBatch) {
                
                AddBatchSerialNumber__e addEvent = new AddBatchSerialNumber__e();
                addEvent.PT_id__c = dataObject.Id;
                addEvent.Status__c = 'Not found';
    
                Database.SaveResult results = EventBus.publish(addEvent);

            }
            if (foundBatch && !foundQuantity) {
                
                AddBatchSerialNumber__e addEvent = new AddBatchSerialNumber__e();
                addEvent.PT_id__c = dataObject.Id;
                addEvent.Status__c = 'QuantityError';
    
                Database.SaveResult results = EventBus.publish(addEvent);

            }
            

        }catch(Exception e) {
            AddBatchSerialNumber__e addEvent = new AddBatchSerialNumber__e();
            addEvent.PT_id__c = dataObject.Id;
            addEvent.Status__c = 'Error';
            addEvent.ErrorMessage__c = e.getMessage();

            Database.SaveResult results = EventBus.publish(addEvent);
        }
    }

    @future(callout = true)
    public static void ConsultaSerie(String Serie, String objetoJson) {
        data dataObject = (data)JSON.deserialize(objetoJson, data.class);
        List<String> camposSelect = new List<String>();
        try {
            system.debug(dataObject.ObjetoActualizar);
            SObjectType sObjType = ((SObject) Type.forName(dataObject.ObjetoActualizar).newInstance()).getSObjectType();
            
            sObject record2Update = sObjType.newSObject();
            record2Update.put('Id', dataObject.Id);
            record2Update.put(dataObject.Campo, dataObject.ValorCampo);

            camposSelect.add(dataObject.ProductField);
            camposSelect.add(dataObject.BodegaField);

            List<sObject> sObjectQuery = getObjectById(dataObject.Id, camposSelect);

            String idProduct = String.valueOf(sObjectQuery[0].get(dataObject.ProductField));

            Product2 producto = [SELECT Id, Name FROM Product2 WHERE Id =: idProduct];
    
           //Conexión a SAP
            ConexionSAP conectSAP = new ConexionSAP();
            // HttpResponse login = conectSAP.loginProduction();
            HttpResponse login = conectSAP.loginPruebas();
    
            if (login.getStatusCode() != 200) {
                EnviarCorreo.enviar('Error al conectarse con SAP: addSerialesLotesLWC_Future', 'Clase: addSerialesLotesLWC_Future <br> body de la respuesta: ' + 
                login.getBody(), correos);
                return;    
            }
            System.debug('Inicio de sesión en SAP exitoso');
            //Deserializo el inicio de sesión
            Deserializaciones.LoginSAP sesion = (Deserializaciones.LoginSAP)JSON.deserialize(login.getBody(),Deserializaciones.LoginSAP.class);

            String bodegaSearch = String.valueOf(sObjectQuery[0].get(dataObject.BodegaField));
            String referenciaSearch = producto.Name;

            BatchSerialNumbers_API getLotesSeriales = new BatchSerialNumbers_API();
            HttpResponse batchSerialResponse = getLotesSeriales.getSeriales(sesion.SessionId, bodegaSearch.split(' - ')[0], referenciaSearch, Serie);
    
            if (batchSerialResponse.getStatusCode() != 200) {
                EnviarCorreo.enviar('Error al obtener los lotes/seriales en la clase: addSerialesLotesLWC_Future', 'Clase: addSerialesLotesLWC_Future <br> body de la respuesta: ' + 
                batchSerialResponse.getBody() + '<br> Id del registro: ' + dataObject.Id, correos);
                return;
            }
    
            Deserializaciones.BatchProducts serialNumbers = new Deserializaciones.BatchProducts();
            serialNumbers = (Deserializaciones.BatchProducts)JSON.deserialize(batchSerialResponse.getBody(),Deserializaciones.BatchProducts.class);

            System.debug('serialNumbers consultados: ' + serialNumbers.value);
            System.debug('tamaño de la lista consultada: ' + serialNumbers.value.size());

            if (serialNumbers.value.size() == 1) {
                
                update record2Update;
                AddBatchSerialNumber__e addEvent = new AddBatchSerialNumber__e();
                addEvent.PT_id__c = dataObject.Id;
                addEvent.Status__c = 'Successful';
    
                Database.SaveResult results = EventBus.publish(addEvent);
            
            }

            if (serialNumbers.value.size() < 1) {
                
                AddBatchSerialNumber__e addEvent = new AddBatchSerialNumber__e();
                addEvent.PT_id__c = dataObject.Id;
                addEvent.Status__c = 'Not found';
    
                Database.SaveResult results = EventBus.publish(addEvent);

            }
            

        }catch(Exception e) {
            AddBatchSerialNumber__e addEvent = new AddBatchSerialNumber__e();
            addEvent.PT_id__c = dataObject.Id;
            addEvent.Status__c = 'Error';
            addEvent.ErrorMessage__c = e.getMessage();

            Database.SaveResult results = EventBus.publish(addEvent);
        }
    }

    public static List<SObject> getObjectById(String recordId, List<String> campos){

        Id id = (Id) recordId;
        SObjectType objectType = id.getSObjectType();
        DescribeSObjectResult objectDescribe = objectType.getDescribe();
        
        String objeto = objectDescribe.getName();
        system.debug('El objeto del registro es: ' + objeto);
            
        String consulta = 'SELECT ' + String.join(campos, ',') + ' FROM ' + objeto + ' WHERE Id = \'' + id + '\'';
        List<sObject> resultados = Database.query(consulta);
        system.debug('El resultado del query es: ' + resultados);

        return resultados;
    }

    public class data {
        public String ObjetoActualizar;
        public String Id;
        public String Campo;
        public String ValorCampo;
        public String ProductoId;
        public String ProductField;
        public String BodegaField;
    }
}