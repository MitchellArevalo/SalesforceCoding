public with sharing class SplitFlow {
    @InvocableMethod
    public static List<List<String>> separarValoresSaltoDeLinea(List<String> inputList) {
        List<List<String>> outputList = new List<List<String>>();
        for(String inputString : inputList) {
            List<String> values = inputString.split('\\n');
            outputList.add(values);
        }
        return outputList;
    }
}