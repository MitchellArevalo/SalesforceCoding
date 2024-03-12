@IsTest
public class SplitFlowTest {

    @IsTest
    static void testSepararValoresSaltoDeLinea() {
        // Input data
        List<String> inputList = new List<String>{'1\n2\n3', '4\n5\n6'};

        // Expected output data
        List<List<String>> expectedOutputList = new List<List<String>>();
        expectedOutputList.add(new List<String>{'1', '2', '3'});
        expectedOutputList.add(new List<String>{'4', '5', '6'});

        // Call the method to test
        List<List<String>> outputList = SplitFlow.separarValoresSaltoDeLinea(inputList);

        // Compare the actual and expected outputs
        System.assertEquals(expectedOutputList.size(), outputList.size());
        for (Integer i = 0; i < expectedOutputList.size(); i++) {
            System.assertEquals(expectedOutputList[i], outputList[i]);
        }
    }
}