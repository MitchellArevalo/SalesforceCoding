//TEST: TestUpdateStockImpormedical
global with sharing class UpdateStockImpormedicalBatchClass implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.stateful{

    public static Id productPrueba = [SELECT Id FROM Product2 WHERE Name = 'PRUEBA'][0].Id;
    public static List<String> sendToCorreos= new List<String>{'dirdigital@impormedical.com.co', 'profesionaldigital@impormedical.com.co', 'soportedigital2@impormedical.com.co', 'soportedigital@impormedical.com.co'};
    
    public Map<String, Map<String, Decimal>> mapInventoryTotals = new Map<String,Map<String, Decimal>>();

    global Database.QueryLocator start(Database.BatchableContext bc) {
        // collect the batches of records or objects to be passed to execute
         //Conexión a SAP
       ConexionSAP conectSAP = new ConexionSAP();
       HttpResponse login = conectSAP.loginProduction();

       System.debug('StatusCode login: ' + login.getStatusCode());
        if(login.getStatusCode() != 200){
            EnviarCorreo.enviar('Error de conexión SF-SAP', 'Ocurrió un error al intentar conectarse a SAP desde UpdateStockImpormedicalBatchClass' + login.getBody(), sendToCorreos);
            System.debug('Entró al error de conexión con SAP' + login.getBody() );
            return Database.getQueryLocator('SELECT Id FROM Product2 WHERE Id = null');
        }
        Deserializaciones.LoginSAP sesion = new Deserializaciones.LoginSAP();
        sesion = (Deserializaciones.LoginSAP)JSON.deserialize(login.getBody(),Deserializaciones.LoginSAP.class);

       ActInvImpor_API inventoryAPI = new ActInvImpor_API();

       HttpResponse inventorySAP = inventoryAPI.getInventory(sesion.SessionId);

       if (inventorySAP.getStatusCode() != 200 ) {
           EnviarCorreo.enviar('Error al obtener el inventario en SAP', 'Ocurrió un error al intentar obtener el inventario en SAP desde la clase: UpdateStockImpormedicalBatchClass' + inventorySAP.getBody(), sendToCorreos);
           System.debug('Entró al error de obtener los valores' + inventorySAP.getBody());
           return Database.getQueryLocator('SELECT Id FROM Product2 WHERE Id = null');
      }

      Deserializaciones.itemsStockSAP inventorySAPValues = new Deserializaciones.itemsStockSAP();
      inventorySAPValues = (Deserializaciones.itemsStockSAP)JSON.deserialize(inventorySAP.getBody(),Deserializaciones.itemsStockSAP.class);

      System.debug('size de la consulta: ' + inventorySAPValues.value.size());
      for (Integer i = 0; i < inventorySAPValues.value.size(); i++) {
        Map<String, Decimal> mapProductValues = new Map<String, Decimal>();
        mapProductValues.put('Cantidad', inventorySAPValues.value[i].OnHand - inventorySAPValues.value[i].IsCommited + inventorySAPValues.value[i].OnOrder);
        mapProductValues.put('Costo', inventorySAPValues.value[i].AvgPrice);
       mapInventoryTotals.put(inventorySAPValues.value[i].ItemCode + '/' + inventorySAPValues.value[i].WhsCode, mapProductValues);
      }

      system.debug(mapInventoryTotals);
        Product2 updatePrueba = new Product2(Id = productPrueba, Sincronizando_inventario__c = true);
        update updatePrueba;
        String queryProduct = 'SELECT Id, Name FROM Product2 WHERE IsActive = true AND Sin_rentabilidad__c = false' + (Test.isRunningTest() ? ' LIMIT 1': '') ;
        return Database.getQueryLocator(queryProduct);
    }

    global void execute(Database.BatchableContext bc, List<Product2> productQuery){
        // process each batch of records
        List<Product2> updateProductList = new List<product2>();
        system.debug(mapInventoryTotals);

        for (Product2 productSF : productQuery) {

            if (mapInventoryTotals.containsKey(productSF.Name + '/' + 'B32') || mapInventoryTotals.containsKey(productSF.Name + '/' + 'B34') || mapInventoryTotals.containsKey(productSF.Name + '/' + 'B6')) {
                Product2 newStock = new Product2();
                newStock.id = productSF.id;
                newStock.B32__c = mapInventoryTotals.get(productSF.Name + '/' + 'B32').get('Cantidad');
                newStock.B34__c = mapInventoryTotals.get(productSF.Name + '/' + 'B34').get('Cantidad');
                newStock.B6__c = mapInventoryTotals.get(productSF.Name + '/' + 'B6').get('Cantidad');
                newStock.Costo_B32__c = mapInventoryTotals.get(productSF.Name + '/' + 'B32').get('Costo');
                newStock.Costo_B34__c = mapInventoryTotals.get(productSF.Name + '/' + 'B34').get('Costo');
                newStock.Costo_B6__c = mapInventoryTotals.get(productSF.Name + '/' + 'B6').get('Costo');
    
                updateProductList.add(newStock);
            }
            
        }
        
        if (!updateProductList.isEmpty()) {
            update updateProductList;
        }
    }    

    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
       Product2 updatePrueba = new Product2(Id = productPrueba, Sincronizando_inventario__c = false, Fecha_de_sincronizaci_n__c = system.now());
        update updatePrueba;

    }
}