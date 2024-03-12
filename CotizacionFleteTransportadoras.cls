//Test:CotizacionFleteTransportadorasTest
@RestResource(urlMapping='/CotizacionFlete/*')
global class CotizacionFleteTransportadoras {
    @HttpPost
    global static void postFlete() {

      RestResponse response = RestContext.response;
      String requestBody = System.RestContext.request.requestBody.toString();
      
      Decimal resultadoPost = 0.0;
      String solicitudPost = RestContext.request.requestURI.substringAfterLast('/');
      Map<String, Object> requestBodyMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
      
      String dane = (String) requestBodyMap.get('codDane');
      Integer totalPiezas = (Integer) requestBodyMap.get('totalPiezas');
      Decimal KV = (Decimal) requestBodyMap.get('KV');

      JSONGenerator gen = JSON.createGenerator(true);
      gen.writeStartObject();

      
      switch on (solicitudPost.toUpperCase()) {

        when ('SOLISTICA') {
          if (dane != null && totalPiezas != null) {
            resultadoPost = doSolisticaFlete(dane, totalPiezas);
            gen.writeNumberField('ValorFlete', resultadoPost);
            
          }else {
            response.statusCode = 400;
            gen.writeStringField('ERROR', 'No se pueden enviar campos vacíos, la transportadora SOLISTICA necesita el código dane y la cantidad de piezas');
            
          }
        }
        when ('TRANSPRENSA') {
          if (dane != null && totalPiezas != null && KV != null) {
            resultadoPost = doTransprensaFlete(dane, totalPiezas, KV);
            if (resultadoPost == null) {
              response.statusCode = 400;
              gen.writeStringField('ERROR', 'Hubo un error con el tipo de destino');
            }else {
              gen.writeNumberField('ValorFlete', resultadoPost);
            }
          }else {
            response.statusCode = 400;
            gen.writeStringField('ERROR', 'No se pueden enviar campos vacíos, la transportadora TRANSPRENSA necesita el código dane, la cantidad de piezas y el total del kilovolumen');
          }
        }
        when else{
          response.statusCode = 400;
          gen.writeStringField('ERROR', 'No se encontró ninguna transportadora que coincida con la solicitud');
        }
      }

      gen.writeEndObject();
      
      response.responseBody = Blob.valueOf(gen.getAsString());

    }

    private static Decimal doSolisticaFlete(String dane, Integer totalPiezas) {
      // Lógica para manejar una solicitud POST para cotizar el flete de solistica
      Decimal kiloVolumen;
      Map<String,Decimal>danePrecios = ListaDanePreciosSolistica.listaCodigoDaneTiempo();
      Decimal valorKiloDane = danePrecios.containsKey(dane) ? danePrecios.get(dane) : 1807.47352428224;
      kiloVolumen = totalPiezas > 1 ? ((totalPiezas - 1) * 20) + 30: 30;
      Decimal flete = valorKiloDane * kiloVolumen;
      Decimal cargoManejoTotal = totalPiezas * 2853;
      Decimal fleteTotal = cargoManejoTotal + flete;
      return fleteTotal.setScale(2, RoundingMode.HALF_UP);
    
    }

    private static Decimal doTransprensaFlete(String dane, integer totalPiezas, Decimal KV) {
      // Lógica para manejar una solicitud POST para cotizar el flete de transprensa

      Decimal totalKVdescuento = Math.round(KV - (KV * 0.3));
      Map<String,Decimal>danePrecios = ListaDanePreciosTransprensa.listaCodigoDaneTiempo();
      Decimal valorPorKiloVolumen = danePrecios.containsKey(dane) ? danePrecios.get(dane) : 0.0;
      if (valorPorKiloVolumen == 0.0) {
        return null;
      }
      System.debug('Este es el costo por kiloVolumen que maneja según la ciudad: ' + valorPorKiloVolumen);
      Decimal valorPorKiloVolumenDescuento = valorPorKiloVolumen - (valorPorKiloVolumen * 0.27);
      System.debug('Este es el costo por kiloVolumen Descuento que maneja según la ciudad: ' + valorPorKiloVolumenDescuento);
      Decimal valorDeclaradoUnitario = 2100.0 * totalPiezas;
      System.debug('Este es el declarado unitario: ' + valorDeclaradoUnitario);
      Decimal kiloVolumenXPieza = KV / totalPiezas;
      System.debug('Este es el Kilo volumen por pieza: ' + kiloVolumenXPieza);
      Decimal kiloVolumenXPiezaDescuento = totalKVdescuento / totalPiezas;
      System.debug('Este es el Kilo volumen por pieza Descuento: ' + kiloVolumenXPiezaDescuento);
      Map<String,String>daneDestino = ListaDanePreciosTransprensa.listaDaneDestino();
      String tipoDestino = daneDestino.get(dane);
      Decimal valorFlete = kiloVolumenXPiezaDescuento < 30 ? (valorPorKiloVolumen * 30) * totalPiezas: (kiloVolumenXPiezaDescuento * valorPorKiloVolumen) * totalPiezas;
      System.debug('Este es el valor del flete sin descuento: ' + valorFlete);
      Decimal valorFleteConDescuento = (valorFlete - (valorFlete * 0.27));
      System.debug('Este es el valor del flete con descuento: ' + valorFleteConDescuento);

      Decimal totalFlete = 0.0;
      System.debug('El tipo de destino del flete es: ' + tipoDestino);
      if (tipoDestino == 'N') {
          if (valorFleteConDescuento < 15000) {
              return (15000 + valorDeclaradoUnitario).setScale(2, RoundingMode.HALF_UP);
          } else {
              return (valorFleteConDescuento + valorDeclaradoUnitario).setScale(2, RoundingMode.HALF_UP);
          }
      } else if (tipoDestino == 'R') {
          if (valorFleteConDescuento < 10000) {
              return (10000 + valorDeclaradoUnitario).setScale(2, RoundingMode.HALF_UP);
          } else {
              return (valorFleteConDescuento + valorDeclaradoUnitario).setScale(2, RoundingMode.HALF_UP);
          }
      } else if (tipoDestino == 'U') {
          if (valorFleteConDescuento < 8000) {
              return (8000 + valorDeclaradoUnitario).setScale(2, RoundingMode.HALF_UP);
          } else {
              return (valorFleteConDescuento + valorDeclaradoUnitario).setScale(2, RoundingMode.HALF_UP);
          }
      }else{
          return null;
      }

    }

}