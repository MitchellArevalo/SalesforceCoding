@isTest(seeAllData = true)
public with sharing class Test_MetasComerciales_Schedulable {

    @IsTest
    static void testMethodName() {
        
        List<Product2> productList = Product_Utility.createProducts(2);
        Product2 producto = productList[0];
        Product2 producto2 = productList[1];
        PricebookEntry listadeprecios = PricebookEntry_Utility.pricebookEntryStandard(producto.id);       
        PricebookEntry listadeprecios2 = PricebookEntry_Utility.pricebookEntryStandard(producto2.id);
        Account cuenta =  Account_Utility.createCanalDistribucionAccount();
        cuenta.Asesor_de_servicio_al_cliente__c = [SELECT Id, name FROM User WHERE isActive = true AND Name = 'Mitchell Arévalo Henao'][0].id;
        update cuenta;
        Contact contacto = Account_Utility.createAccountContact(cuenta.id);
        Opportunity opp = Opportunity_Utility.createOpportunityVenta(cuenta.id);
        Quote cotizacion = Quote_Utility.cotizacion(opp.id, contacto.id);
        List<QuoteLineItem> productocotizacion = QuoteLineItems_Utility.addQuoteLineItems(cotizacion.id, productList, 'B32 - Bodega 32', listadePrecios.id);
        Plan_comercial__c Plancomercial = PlanComerical_Utility.createPlanComerical ();
        Meta_comercial__c metaComercial = Meta_comercial_Utility.createMetaComercial(Plancomercial.id, cuenta.Asesor_de_servicio_al_cliente__c);


        Test.startTest();
            opp.SyncedQuoteId = cotizacion.id;
            update opp;

            cotizacion.Status= 'Accepted';
            update cotizacion;

            opp.DocEntry__c='123';
            opp.cerrado_ganado__c = true;
            opp.Desconto_del_inventario__c = true;
            opp.Solo_entrega__c = true;
            opp.Pago_verificado__c = true;
            opp.StageName = 'Closed Won';
            update opp;
            Date fechaMinima = System.today();
            Date fechaMaxima = System.today();
            Datetime hoy = system.now().addSeconds(10);
            String fechaEjecucion = hoy.second() + ' ' + hoy.minute() + ' ' + hoy.hour()+ ' ' + hoy.day() + ' '+ hoy.month() + ' ' + '? ' + hoy.year();
            System.schedule('MetasComerciales_Schedulable desde test' + fechaEjecucion + Math.random(), fechaEjecucion, new MetasComerciales_SchedulableOK(false, fechaMinima, fechaMaxima));

        Test.stopTest();

    }

}