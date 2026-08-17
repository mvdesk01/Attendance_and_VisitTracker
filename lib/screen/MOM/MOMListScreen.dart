import 'dart:convert';

import 'package:attendance_system_ios/screen/MOM/update_form.dart';
import 'package:flutter/material.dart';

import 'mom_list_model.dart';

class MOMListScreen extends StatefulWidget {
  const MOMListScreen({super.key});

  @override
  State createState() => MOMListScreenState();
}

class MOMListScreenState extends State<MOMListScreen> {

  List<MOMListModel> users = [
    MOMListModel(name: 'manish', email: 'manish@gmail.com'),
    MOMListModel(name: 'naman', email: 'naman@gmail.com'),
    MOMListModel(name: 'rahul', email: 'rahul@gmail.com')
  ];

  late var json = [];
  @override
  initState() {
    initData();
    parseData();
    super.initState();
  }

  void initData() {
     json = [
      {
        'name': 'manish',
        'email': 'manish@gmail.com'
      },
      {
        'name': 5,
        'email': 'naman@gmail.com'
      }
    ];
  }

  void parseData() {
    print("json: $json");
    String data  = jsonEncode(json);
    print( "data: $data");
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mom List'),
      ),
      body: ListView(
        children: [
          Row(
            children: [
              const SizedBox(height: 12, width: 12,),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: ${users[0].name}'),
                  Text('Email: ${users[0].email}')
                ]
              ),
              IconButton(onPressed: () async {
                final result =await Navigator.push(context, MaterialPageRoute(builder: (context) => UpdateForm(name: users[0].name, email: users[0].email)));
                print("return result: $result");
                users[0] = result;
                setState(() {});
              }, icon: Icon(Icons.edit))
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const SizedBox(height: 12, width: 12,),
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name: ${users[1].name}'),
                    Text('Email: ${users[1].email}')
                  ]
              ),
              IconButton(onPressed: () async {
                final result =await Navigator.push(context, MaterialPageRoute(builder: (context) => UpdateForm(name: users[1].name, email: users[1].email)));
                print("return result: $result");
                users[1] = result;
                setState(() {
                });
              }, icon: Icon(Icons.edit))
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              const SizedBox(height: 12, width: 12,),
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name: ${users[2].name}'),
                    Text('Email: ${users[2].email}')
                  ]
              ),
              IconButton(onPressed: () async {
                final result =await Navigator.push(context, MaterialPageRoute(builder: (context) => UpdateForm(name: users[2].name, email: users[2].email)));
                print("return result: $result");
                users[2] = result;
                setState(() {
                });
              }, icon: Icon(Icons.edit))
            ],
          ),


        ],
      )
    );
  }
}