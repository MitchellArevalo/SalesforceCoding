// Test: TestPostToChatter 
public class PostToChatter {
    
    public static void postChatterInactivacion(id parentID, id mention, string body){
        
        List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();

            ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
            ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
            ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
            ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();

            messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
            //Mention user here
            mentionSegmentInput.id = mention;
            messageBodyInput.messageSegments.add(mentionSegmentInput);

            textSegmentInput.text = '\n' + body;
            messageBodyInput.messageSegments.add(textSegmentInput);

            feedItemInput.body = messageBodyInput;
            feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
            feedItemInput.subjectId = parentID;

            ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(feedItemInput);
            batchInputs.add(batchInput);

        ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), batchinputs);
        
    }

    public static void postChatterObjectMention(String mensaje, String asunto, List<Id> userIds, Id parentId, Boolean html) {

        Set<string> notifyUsers = new Set<string>();
        List<User> usuarios = [SELECT id, Name FROM User WHERE id in: userIds];
        try {
            // Unir los IDs de usuario con la etiqueta de mención "@" y un espacio
            String usuariosMencionados = '';
            for (User user : usuarios) {
                usuariosMencionados += '<a href="https://impormedical.lightning.force.com/lightning/r/User/' + user.id + '/view" alt="usuarioname" target="_blank">' + user.Name + '</a> ';
                notifyUsers.add(String.valueOf(user.id));
            }
            
            // Crear el comentario en Chatter con la etiqueta de mención
            FeedItem comentario = new FeedItem();
            comentario.IsRichText = html;
            comentario.ParentId = parentId;
            comentario.Body = mensaje + '&nbsp' + usuariosMencionados;
            insert comentario;

          
            notifyUsers(notifyUsers, String.valueOf(parentId), asunto, 'Te han mencionado en un comentario del chatter');
          

        } catch (DmlException e) {
            // Manejar la excepción de permisos
            System.debug('Error al crear el comentario: ' + e.getMessage());
        }
       
    }

    public static void postChatterGroupMention(String mensaje, String asunto, List<Id> userIds, Id parentId, Boolean html, String groupName) {

        Set<string> notifyUsers = new Set<string>();
        List<User> usuarios = [SELECT id, Name FROM User WHERE id in: userIds];
        try {
            // Unir los IDs de usuario con la etiqueta de mención "@" y un espacio
            for (User user : usuarios) {
                notifyUsers.add(String.valueOf(user.id));
            }
            
            // Crear el comentario en Chatter con la etiqueta de mención
            FeedItem comentario = new FeedItem();
            comentario.IsRichText = html;
            comentario.ParentId = parentId;
            comentario.Body = mensaje + '&nbsp';
            insert comentario;

          
            notifyUsers(notifyUsers, String.valueOf(parentId), asunto, UserInfo.getName() +' Ha publicado en el grupo ' + groupName);
          

        } catch (DmlException e) {
            // Manejar la excepción de permisos
            System.debug('Error al crear el comentario: ' + e.getMessage());
        }
       
    }

    public static void notifyUsers(Set<String> recipientsIds, String targetId, String asunto, String title) {

        // Get the Id for our custom notification type
        CustomNotificationType notificationType = 
            [SELECT Id, DeveloperName 
             FROM CustomNotificationType 
             WHERE DeveloperName='NotificationApex'];
        
        // Create a new custom notification
        Messaging.CustomNotification notification = new Messaging.CustomNotification();

        // Set the contents for the notification
        notification.setTitle(title);
        notification.setBody(asunto);

        // Set the notification type and target
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(targetId);
        
        // Actually send the notification
        notification.send(recipientsIds);
        
        
    }
    
    
}