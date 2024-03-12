// Test: TestSeriales_Lotes_PD
public class Seriales_Lotes_PD_Future {

    public static List<String> sendToCorreos = new List<String>{'dirdigital@impormedical.com.co', 'profesionaldigital@impormedical.com.co', 'soportedigital2@impormedical.com.co', 'soportedigital@impormedical.com.co'};
    public static Map<integer, Seriales_Lotes_PD__c> serialesLotesMap = new Map<integer, Seriales_Lotes_PD__c>();
    public static Map<Id,Seriales_Lotes_PD__c> serialesLotesDeclaracionImportacion = new Map<Id,Seriales_Lotes_PD__c>();
    public static Id recordTypeConsignacionOpportunity = [SELECT Id, Name FROM RecordType WHERE Name = 'Consignación' LIMIT 1][0].id;
    

    @future(callout = true)
    public static void updateLotesSeriesProductoDespacho(id idCase){
        
        Case caseActual = [
            SELECT Id, DocEntry_factura__c, Cotizaci_n__c, Cotizaci_n__r.OpportunityId,
                (SELECT Id, Referencia__r.Administraci_n__c, Referencia__r.Name, Caso__c, Cantidad__c
                 FROM Productos_de_despacho__r)
            FROM Case
            WHERE Id = :idCase
        ];
        Opportunity opportunity = new Opportunity();
        try {
            opportunity = [
                SELECT Id, Name, DocEntry__c, RecordTypeId,
                    (SELECT Id, Name FROM Quotes)
                FROM Opportunity
                WHERE Id = :caseActual.Cotizaci_n__r.OpportunityId
            ];
            // Resto del código si la consulta es exitosa
        } catch (System.QueryException ex) {
            System.debug('Error en la consulta SOQL: ' + ex.getMessage());
            // Otra lógica de manejo de errores
        }

        ConexionSAP conectSAP = new ConexionSAP();
        HttpResponse login = conectSAP.loginProduction();
        // HttpResponse login = conectSAP.loginPruebas();

        if(login.getStatusCode() != 200){
            EnviarCorreo.enviar('Error de conexión SF-SAP', 'Ocurrió un error al intentar conectarse a SAP desde Seriales_Lotes_PD_Future', sendToCorreos);
            return;
        }
        Deserializaciones.LoginSAP sesion = new Deserializaciones.LoginSAP();
        sesion = (Deserializaciones.LoginSAP)JSON.deserialize(login.getBody(),Deserializaciones.LoginSAP.class);

        Deserializaciones.deliveryNotesProducts deserializeFields = new Deserializaciones.deliveryNotesProducts();

        if (Opportunity.RecordTypeId == recordTypeConsignacionOpportunity) {
            
            GetBatchSerialFromTransfer_API getLotesSerialesTranfer = new GetBatchSerialFromTransfer_API();
            HttpResponse transfer = getLotesSerialesTranfer.getLotesSeriales(sesion.SessionId, Opportunity.DocEntry__c);

            if (transfer.getStatusCode() != 200) {
                EnviarCorreo.enviar('Error al obtener los lotes/seriales en la clase: Seriales_Lotes_PD_Future', 'Clase: Seriales_Lotes_PD_Future <br> body de la respuesta: ' + transfer.getBody() + '<br> Id del caso: ' + caseActual.Id, sendToCorreos);
                return;
            }

            deserializeFields = (Deserializaciones.deliveryNotesProducts)JSON.deserialize(transfer.getBody(),Deserializaciones.deliveryNotesProducts.class);

        }else{
            
            DeliveryNotes_API getLotesSeriales = new DeliveryNotes_API();
            HttpResponse delivery = getLotesSeriales.getLotesSerialesEntrega(sesion.SessionId, caseActual.DocEntry_factura__c);
    
            if (delivery.getStatusCode() != 200) {
                EnviarCorreo.enviar('Error al obtener los lotes/seriales en la clase: Seriales_Lotes_PD_Future', 'Clase: Seriales_Lotes_PD_Future <br> body de la respuesta: ' + delivery.getBody() + '<br> Id del caso: ' + caseActual.Id, sendToCorreos);
                return;
            }
    
            deserializeFields = (Deserializaciones.deliveryNotesProducts)JSON.deserialize(delivery.getBody(),Deserializaciones.deliveryNotesProducts.class);
    
            
        }
        System.debug(deserializeFields.value);

        system.debug(caseActual.Productos_de_despacho__r);
        for (Producto_de_despacho__c productoDespacho : caseActual.Productos_de_despacho__r) {
            decimal cantidadSAP = 0;
            for (integer i = 0; i < deserializeFields.value.size(); i++) {
                system.debug('deserializefields: ' + deserializeFields.value[i].ItemCode + ' NamePD: ' + productoDespacho.Referencia__r.Name);
                if (deserializeFields.value[i].ItemCode == productoDespacho.Referencia__r.Name) {

                    Seriales_Lotes_PD__c loteSerial = new Seriales_Lotes_PD__c();
                    loteSerial.Producto_de_despacho__c = productoDespacho.id;
                    loteSerial.Cantidad__c = deserializeFields.value[i].Quantity == null ? 1: deserializeFields.value[i].Quantity;
                    loteSerial.Lote_Serie__c = deserializeFields.value[i].MnfSerial == null ? deserializeFields.value[i].DistNumber : deserializeFields.value[i].MnfSerial;
                    if (cantidadSAP != productoDespacho.Cantidad__c && !serialesLotesMap.containsKey(i)){
                        system.debug('serial lote ' + i + ': ' + loteSerial);
                        serialesLotesMap.put(i,loteSerial);                        
                        cantidadSAP += deserializeFields.value[i].Quantity == null? 1: deserializeFields.value[i].Quantity;
                    }
                } 
            }    
        } 

        system.debug('Seriales a insertar: ' + serialesLotesMap.values());


        Database.SaveResult[] resultados = Database.insert(serialesLotesMap.values());
        List<Id> idsSerialesLotes = new List<Id>();
        for(Database.SaveResult resultado : resultados) {
            if(resultado.isSuccess()) {
                system.debug('insertados correctamente');
                idsSerialesLotes.add(resultado.getId());
            }else{
                system.debug('Fallo en la inserción');

            }
        }
        if (!idsSerialesLotes.isEmpty()) {
            getDeclaracionDeImportacion(idsSerialesLotes);
        }

    }

    public static void getDeclaracionDeImportacion(List<Id> idsSerieLote){

        List<Seriales_Lotes_PD__c> SerialesLotesPD = [SELECT id, Name, Lote_Serie__c, Producto_de_despacho__r.Referencia__r.Name
                                                        FROM Seriales_Lotes_PD__c WHERE id IN: idsSerieLote];
        Map<String, String> declaracionesMap = new Map<String, String>();
        List<String> LotesSeries = new List<String>();
        List<String> referencias = new List<String>();

        for (Seriales_Lotes_PD__c serialLote : SerialesLotesPD) {
            LotesSeries.add(serialLote.Lote_Serie__c);
            referencias.add(serialLote.Producto_de_despacho__r.Referencia__r.Name);
        }

        String term = String.join(LotesSeries, ' OR ');

        List<List<SObject>> proImportacionSOSL = [FIND :term IN ALL FIELDS
                                        RETURNING Productos_de_Importaci_n__c (Id, Name, Referencia_Impormedical__c, Caso_de_importaci_n__r.Declaraciones_de_importaci_n__c, Administraci_n__c,
                                                                                Seriales__c, No_de_lote__c WHERE Referencia_Impormedical__c IN:referencias) ];

        Productos_de_Importaci_n__c[] piSearch = (Productos_de_Importaci_n__c[])proImportacionSOSL[0];

        for(Productos_de_Importaci_n__c resultado : piSearch){
            system.debug('nombre PI: ' + resultado.Name + ' referencia IM: ' + resultado.Referencia_Impormedical__c + ' Declaracion de importacion link ' + resultado.Caso_de_importaci_n__r.Declaraciones_de_importaci_n__c);
            if (resultado.Administraci_n__c == 'Serie') {
                declaracionesMap.put(resultado.Seriales__c, resultado.Caso_de_importaci_n__r.Declaraciones_de_importaci_n__c);
            }else {
                declaracionesMap.put(resultado.No_de_lote__c, resultado.Caso_de_importaci_n__r.Declaraciones_de_importaci_n__c);
            }
        }

        for (Seriales_Lotes_PD__c serialLote : SerialesLotesPD) {
            Seriales_Lotes_PD__c serialLoteDML = new Seriales_Lotes_PD__c();
            serialLoteDML.id = serialLote.id;
            for (String key : declaracionesMap.keySet()) {
                if (key.contains(serialLote.Lote_Serie__c)) {
                    serialLoteDML.Declaraci_n_de_importaci_n__c = declaracionesMap.get(key);
                    break;
                }
            }
            serialesLotesDeclaracionImportacion.put(serialLote.id, serialLoteDML);
        }

        Database.SaveResult[] resultados = Database.update(serialesLotesDeclaracionImportacion.values());
        for(Database.SaveResult resultado : resultados) {
            if(!resultado.isSuccess()) {           
                for(Database.Error err : resultado.getErrors()) {
                    EnviarCorreo.enviar('Error al actualizar las declaraciones de importación', 
                    'Clase: Seriales_Lotes_PD_Future <br> el error es el siguiente ' + err.getStatusCode() + ': ' + err.getMessage() +
                    'Campos de los Seriales_Lotes_PD que afectaron en el error' + err.getFields(), sendToCorreos);
                    return;
                }
              
            }
        }
    }
}