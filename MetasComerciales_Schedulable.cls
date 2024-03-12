//TEST: Test_MetasComerciales_Schedulable
global with sharing class MetasComerciales_Schedulable implements Database.Batchable<sObject>, Database.Stateful{
    public Map<String, Decimal> Venta_Contado = new Map<String, Decimal>();
    public Map<String, Decimal> Costo_Venta_Total = new Map<String, Decimal>();
    public Map<Id, Meta_comercial__c> elmapareal = new Map<Id, Meta_comercial__c>();
    public Map<Id, Map<String, Decimal>> mapPlanesTotalPrice = new Map<Id, Map<String, Decimal>>();
    public Map<Id, Map<String, Decimal>> mapPlanesTotalCost = new Map<Id, Map<String, Decimal>>();
    public Set<String> opportunitySet= new Set<String>();
    public List<Plan_comercial__c> planesComercialesList = new List<Plan_comercial__c>();
    public Date fechaMinima;
    public Date fechaMaxima;
    public Boolean fechaManual;

    public MetasComerciales_Schedulable(Boolean manual, Date inicio, Date fin) {
        fechaMinima = inicio;
        fechaMaxima = fin;
        fechaManual = manual;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {

        if(fechaManual){

            for (Plan_comercial__c plan : [SELECT Id, Name, Fecha_fin__c, Fecha_incio__c FROM Plan_comercial__c WHERE Fecha_fin__c <=: fechaMaxima AND Fecha_incio__c >=: fechaMinima]) {
                planesComercialesList.add(plan);
            }

        }
        else{
            
            for (Plan_comercial__c plan : [SELECT Id, Name, Fecha_fin__c, Fecha_incio__c FROM Plan_comercial__c WHERE Fecha_fin__c >= TODAY]) {
                planesComercialesList.add(plan);
                fechaMaxima = plan.Fecha_fin__c >= fechaMaxima ? plan.Fecha_fin__c : fechaMaxima;
                fechaMinima = plan.Fecha_incio__c <= fechaMinima ? plan.Fecha_incio__c : fechaMinima;
            }
        }


        for (OpportunityLineItem item : [SELECT Id, OpportunityId, Opportunity.Account.Asesor_de_servicio_al_cliente__c, 
                                        Opportunity.Account.Condici_n_de_pago__c, PricebookEntry.Product2.L_nea__c, Opportunity.CloseDate,
                                        PricebookEntry.Product2.Family, Opportunity.C_digo_del_SN__c, Product2Id, ProductCode, 
                                        TotalPrice, Quantity, UnitPrice, Bodega__c, Obsequio__c, Costo_por_unidad_OLI__c, Costo_Total__c,Opportunity.Costo_total_oppty__c
										FROM OpportunityLineItem
										WHERE Opportunity.StageName = 'Closed Won' AND Opportunity.CloseDate >= :fechaMinima AND 
                                        Opportunity.CloseDate <= :fechaMaxima 
      									AND Opportunity.RecordTypeId = '0126Q000000M6hbQAC'
                                        AND Referencia__c != 'FLETES' FOR UPDATE]) {

            for (Plan_comercial__c plan : planesComercialesList) {
                if (item.Opportunity.CloseDate >= plan.Fecha_incio__c && item.Opportunity.CloseDate <= plan.Fecha_fin__c) {

                    mapPlanesTotalPrice.put(plan.id, accumulateTotalPriceByAsesor(mapPlanesTotalPrice.get(plan.id) == null? new Map<String, Decimal>() : mapPlanesTotalPrice.get(plan.id), item.Opportunity.Account.Asesor_de_servicio_al_cliente__c, item.TotalPrice ));
                    String opptyPlan = item.OpportunityId+ '' +plan.id;
                    if (!opportunitySet.contains(opptyPlan)) {
                        opportunitySet.add(opptyPlan);
                        mapPlanesTotalCost.put(plan.id, accumulateTotalCostByAsesor(mapPlanesTotalCost.get(plan.id) == null ? new Map<String, Decimal>() : mapPlanesTotalCost.get(plan.id), item.Opportunity.Account.Asesor_de_servicio_al_cliente__c, item.Opportunity.Costo_total_oppty__c));
                    }

                }
            }
           
         } 

    return Database.getQueryLocator([SELECT Id, Name, Asesor__c, Plan_comercial__r.Id 
                                    FROM Meta_comercial__c 
                                    WHERE Plan_comercial__r.Id IN: planesComercialesList]);

    }


    public void execute(Database.BatchableContext context, List<Meta_comercial__c> scope) {
        // Lógica para procesar cada registro de Meta_de_contado
        for (Meta_comercial__c meta : scope) {

            String asesor = meta.Asesor__c;
            Decimal totalPrice = 0;
            Decimal totalCost = 0;
    
            totalPrice = getTotalPriceByAsesor(mapPlanesTotalPrice.get(meta.Plan_comercial__r.Id) == null ? new Map<String, Decimal>() : mapPlanesTotalPrice.get(meta.Plan_comercial__r.Id), asesor);

            totalCost = getTotalCostByAsesor(mapPlanesTotalCost.get(meta.Plan_comercial__r.Id) == null ? new Map<String, Decimal>() : mapPlanesTotalCost.get(meta.Plan_comercial__r.Id), asesor);

            Meta_comercial__c metaComer = new Meta_comercial__c();
            metaComer.id = meta.id;
            metaComer.Venta_en__c = totalPrice;
            metaComer.Contribuci_n_real__c = totalPrice - totalCost;
            elmapareal.put(meta.id, metaComer);
            
        }

    }

    public void finish(Database.BatchableContext context) {
        
        update elmapareal.values();
        
    }

    private Map<String, Decimal> accumulateTotalPriceByAsesor(Map<String, Decimal> totalPriceByAsesorMap, String asesor, Decimal totalPrice) {
        if (!totalPriceByAsesorMap.containsKey(asesor)) {
            totalPriceByAsesorMap.put(asesor, 0);
        }
        totalPriceByAsesorMap.put(asesor, totalPriceByAsesorMap.get(asesor) + totalPrice);
        return totalPriceByAsesorMap;
    }

    private Map<String, Decimal> accumulateTotalCostByAsesor(Map<String, Decimal> totalCostByAsesor, String asesor, Decimal totalPrice) {
        if (!totalCostByAsesor.containsKey(asesor)) {
            totalCostByAsesor.put(asesor, 0);
        }
        Decimal totalCost = totalCostByAsesor.get(asesor) + totalPrice;

        totalCostByAsesor.put(asesor, totalCostByAsesor.get(asesor) + totalPrice);
    
        return totalCostByAsesor;
    }

    private Decimal getTotalPriceByAsesor(Map<String, Decimal> totalPriceByAsesorMap, String asesor) {
        if (totalPriceByAsesorMap.containsKey(asesor)) {
            return totalPriceByAsesorMap.get(asesor);
        }
        return 0;
    }
    
    private Decimal getTotalCostByAsesor(Map<String, Decimal> totalCostByAsesor, String asesor) {
        if (totalCostByAsesor.containsKey(asesor)) {
            return totalCostByAsesor.get(asesor);
        }
        return 0;
    }
}