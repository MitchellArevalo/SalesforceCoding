//Clases que lo usan: ProductosDeInspeccion, Transferencia_de_stock_Future, EntradasSalidasFuture, ReclasificacionInventario
public with sharing class ManipularHTML {
    public static string eliminarHTML(string text){
        String regExp = '(?s)<[^>]*>(\\s*<[^>]*>)*';
        Pattern tagPattern = Pattern.compile(regExp);
        String plainTextBody = tagPattern.matcher(text).replaceAll('');
        return plainTextBody;
    }
}