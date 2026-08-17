import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'mom_list_model.dart';

class UpdateForm extends StatefulWidget {
  String name;
  String email;
   UpdateForm({super.key, required this.name, required this.email});

  @override
  State<UpdateForm> createState() => _UpdateFormState();
}

class _UpdateFormState extends State<UpdateForm> {

  TextEditingController namecontroller = TextEditingController();
  TextEditingController emailController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Form"),
      ),
      body: Center(
        child: Column(
          // crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${widget.name}'),
            Padding(padding: const EdgeInsets.symmetric(vertical: 8,horizontal: 40),
              child: TextField(
                  controller: namecontroller,
                  decoration: const InputDecoration(
                      labelText: 'enter name'
                  )
              ),
            ),

            const SizedBox(height: 10,),
            Text("Email: ${widget.email}"),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 40),
              child:
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                    labelText: 'enter email'
                )
            ),
            ),


            ElevatedButton(onPressed: () {
             final result = MOMListModel(name: namecontroller.text, email: emailController.text);
             Navigator.pop(context, result);
            }, child: const Text('Save'),)
          ]
        )
      )
    );
  }
}
