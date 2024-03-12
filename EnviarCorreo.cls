// Test: TestEnviarCorreo
public with sharing class EnviarCorreo implements Callable{

    public Object call(String action, Map<String, Object> args){
        switch on action {
            when 'enviar' {
                String ValuesAsString = (String)args.get('values');
                List<String> correos = new List<String>();
                for (String correo : ValuesAsString.split('<=>')[2].split('=>')) {
                    correos.add(correo);
                }
                return this.called(action, ValuesAsString.split('<=>')[0], ValuesAsString.split('<=>')[1], correos, '');
            }
            when 'enviarFromOrg' {
                String ValuesAsString = (String)args.get('values');
                List<String> correos = new List<String>();
                for (String correo : ValuesAsString.split('<=>')[2].split('=>')) {
                    correos.add(correo);
                }
                return this.called(action, ValuesAsString.split('<=>')[0], ValuesAsString.split('<=>')[1], correos,  ValuesAsString.split('<=>')[3]);
            }
            when else {
                return null;
            }
        }
    }
    
    public String called(String action, String asunto, String body, List<String> sentToCorreos, String idEmailOrg){  
        String retorno;
        switch on action {
            when 'enviar' {
                EnviarCorreo.enviar(asunto, body, sentToCorreos);
                retorno = 'Método: ' + action + ' ASUNTO: ' + asunto + ' BODY: ' + body + ' CORREOS: ' + sentToCorreos;
            }
            when  'enviarFromOrg' {
                EnviarCorreo.enviarFromOrg(asunto, body, sentToCorreos, idEmailOrg);
                retorno = 'Método: ' + action + ' ASUNTO: ' + asunto + ' BODY: ' + body + ' CORREOS: ' + sentToCorreos + ' idEmailOrg: ' +  idEmailOrg;
            }
        }
        return  retorno;
    }

    public static void enviarFromOrg(String asunto, string body, List<String> sendToCorreos, String IdEmailOrg) {     
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();    
        mail.setToAddresses(sendToCorreos);  
        mail.setSubject(asunto);  
        mail.setOrgWideEmailAddressId(IdEmailOrg);
        mail.setHtmlBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail}); 
    }

    public static void enviar(String asunto, string body, List<String> sendToCorreos) {     
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();    
        mail.setToAddresses(sendToCorreos);  
        mail.setSubject(asunto);  
        mail.setHtmlBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail}); 
    }
}