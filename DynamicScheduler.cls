global class DynamicScheduler implements Schedulable {
    
    global String className { get; set; }
    global String methodName { get; set; }
    global String methodParams { get; set; }
    global static List<string> correos = new List<string>{'soportedigital2@impormedical.com.co','soportedigital@impormedical.com.co','dirdigital@impormedical.com.co', 'profesionaldigital@impormedical.com.co'};
    
    global DynamicScheduler(String className, String methodName, String methodParams) {
        this.className = className;
        this.methodName = methodName;
        this.methodParams = methodParams;
    }
    
    global void execute(SchedulableContext sc) {
        try {
          Callable extension = (Callable) Type.forName(className).newInstance();

          Object result = extension.call(methodName, new Map<String,Object>{
            'values' => methodParams
          });
          System.debug('Resultado: ' + JSON.serialize(result));
        } catch(Exception e) {
          EnviarCorreo.enviar('Error en el dynamicScheduler con la clase: ' + className, 'Ocurrió un error al intentar hacer el siguiente llamado<br><br> ' + className + 
          '.' + methodName + '();<br><br> los parámetros a enviar son los siguientes: ' + methodParams + '<br><br> el error es el siguiente ' + e.getMessage(), correos);
            System.debug('Error: ' + e.getMessage());
        }
        
        system.abortJob(sc.getTriggerId());
    }
}