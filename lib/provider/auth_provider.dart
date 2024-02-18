
import 'package:flutter/material.dart';


class AuthenticationProvider extends ChangeNotifier{


    List<String> onlineUserEmails =[];


    Future<void> addUserToOnlineList (String email) async{
        if(email.isEmpty){
            return ;
        }

        if(!onlineUserEmails.contains(email)){
            onlineUserEmails.add(email);
        }
        
        notifyListeners();
    }

    Future<void> removeUserFromOnlineList(String email) async{
        if(email.isEmpty){
            return ;
        }

        if(onlineUserEmails.contains(email)){
            onlineUserEmails.remove(email);
        }else{
            return ;
        }

        notifyListeners();
    }


}
