//Test: TestSerialesLotesLWC
public with sharing class addSerialesLotesLWC {

    public static List<String> sendToCorreos = new List<String> {'soportedigital2@impormedical.com.co', 'dirdigital@impormedical.com.co', 'soportedigital@impormedical.com.co'};
    public static String subject = 'Error al añadir un Serial/Lote desde un LWC';
    public static String mail = 'Ha ocurrido un error al intentar añadir un serial/lote desde la clase: addSerialesLotesLWC <br> el error es el siguiente: ';

    @AuraEnabled
    public static void AddBatchNumber(String lote, String cantidad, String recordId, String campo, String productField, String BodegaField, String QuantityField) {
        
        try {
            Boolean duplicatedBatch = false;
            Integer counter = 0;
            String formatedBatch = lote + ' / ' + cantidad + '<br>';
    
            Id id = (Id) recordId;
            SObjectType objectType = id.getSObjectType();
            DescribeSObjectResult objectDescribe = objectType.getDescribe();
    
            String objeto = objectDescribe.getName();
                
            String consulta = 'SELECT ' + campo + ',' + QuantityField + ' FROM ' + objeto + ' WHERE Id = \'' + id + '\'';
            List<sObject> resultados = Database.query(consulta);

            String BatchHistory= (resultados[0].get(campo) == null ?'': resultados[0].get(campo))+ formatedBatch;

            if (resultados[0].get(campo) != null) {
                String campoValue = (String)resultados[0].get(campo);
                List<String> batchList = campoValue.split('<br>');
                for (String batch : batchList) {
                    if (batch.split(' / ')[0].contains(lote)) {
                        duplicatedBatch = true;
                    }
                    counter += Integer.valueOf(batch.split(' / ')[1]);
                }
            }
			
            counter += +Integer.valueOf(cantidad);
            if (duplicatedBatch) {

                AddBatchSerialNumber__e addEvent = new AddBatchSerialNumber__e();
                addEvent.PT_id__c = recordId;
                addEvent.Status__c = 'Duplicated';
    
                Database.SaveResult results = EventBus.publish(addEvent);
                return;

            }

            system.debug('counter: ' + counter);
            system.debug('cantidad Field: ' + (Integer.valueOf(resultados[0].get(QuantityField)))+Integer.valueOf(cantidad));
            if (counter > Integer.valueOf(resultados[0].get(QuantityField))) {
                AddBatchSerialNumber__e addEvent = new AddBatchSerialNumber__e();
                addEvent.PT_id__c = recordId;
                addEvent.Status__c = 'Quantity exceeded';
    
                Database.SaveResult results = EventBus.publish(addEvent);
                return;
            }

            String jsonDML='{' +
                                '"ObjetoActualizar":"' + objeto + '",' +
                                '"Id":"' + recordId + '",' +
                                '"Campo":"'+ campo +'",' +
                                '"ValorCampo":"' + BatchHistory + '",' +
                                '"ProductField":"'+ productField +'",' +
                                '"BodegaField":"'+ BodegaField +'"' +
                            '}';
                    
            // if (!Test.isRunningTest()) {
            addSerialesLotesLWC_Future.ConsultaLote(lote, cantidad, jsonDML);
            // }
           
        } catch (Exception e) {
            EnviarCorreo.enviar(subject, mail + e.getMessage(), sendToCorreos);
            system.debug(e.getMessage());
            throw newMessageException(e.getMessage());
        }

    }

    @AuraEnabled
    public static void AddSerialNumber(String serie, String recordId, String campoSerie, String productField, String BodegaField, String QuantityField){
        try {
           
            Boolean duplicatedSerial = false;
            Integer counter = 1;
            String formatedSerial = serie + '<br>';
    
            Id id = (Id) recordId;
            SObjectType objectType = id.getSObjectType();
            DescribeSObjectResult objectDescribe = objectType.getDescribe();
    
            String objeto = objectDescribe.getName();
                
            String consulta = 'SELECT ' + campoSerie + ',' + QuantityField + ' FROM ' + objeto + ' WHERE Id = \'' + id + '\'';
            List<sObject> resultados = Database.query(consulta);
            system.debug('Los campos del registro son: ' + resultados[0].get(campoSerie));


            String SerialHistory= (resultados[0].get(campoSerie) == null ?'': resultados[0].get(campoSerie))+ formatedSerial;

            System.debug('SerialHistory: ' + SerialHistory );
            if (resultados[0].get(campoSerie) != null) {
                String campoValue = (String)resultados[0].get(campoSerie);
                List<String> serialList = campoValue.split('<br>');
                for (String serial : serialList) {
                    if (serial.contains(serie)) {
                        duplicatedSerial = true;
                    }
                    counter++;
                    System.debug('counter: ' + counter);
                }
            }

            if (duplicatedSerial) {

                AddBatchSerialNumber__e addEvent = new AddBatchSerialNumber__e();
                addEvent.PT_id__c = recordId;
                addEvent.Status__c = 'Duplicated';
    
                Database.SaveResult results = EventBus.publish(addEvent);
                return;

            }

            if (counter > Integer.valueOf(resultados[0].get(QuantityField))) {
                AddBatchSerialNumber__e addEvent = new AddBatchSerialNumber__e();
                addEvent.PT_id__c = recordId;
                addEvent.Status__c = 'Quantity exceeded';
    
                Database.SaveResult results = EventBus.publish(addEvent);
                return;
            }

            String jsonDML='{' +
                                '"ObjetoActualizar":"' + objeto + '",' +
                                '"Id":"' + recordId + '",' +
                                '"Campo":"'+ campoSerie +'",' +
                                '"ValorCampo":"' + SerialHistory + '",' +
                                '"ProductField":"'+ productField +'",' +
                                '"BodegaField":"'+ BodegaField +'"' +
                            '}';
            // if (!Test.isRunningTest()) {
            addSerialesLotesLWC_Future.ConsultaSerie(serie, jsonDML);
            // }
           
        } catch (Exception e) {
            system.debug(e.getMessage());
            throw newMessageException(e.getMessage());
        }
    }

    private static AuraHandledException newMessageException(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        return e;
    }
}