import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context)=>_UtilityPage(title:'Notifications center',subtitle:'Review notification records already stored in Firebase.',child:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
    stream:FirebaseFirestore.instance.collection('notifications').orderBy('createdAt',descending:true).limit(100).snapshots(),
    builder:(context,s){
      if(s.hasError)return SelectableText('Notifications unavailable: '+s.error.toString());
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      if(s.data!.docs.isEmpty)return const Center(child:Padding(padding:EdgeInsets.all(24),child:Text('No notifications yet.')));
      return Card(child:Column(children:s.data!.docs.map((d){final x=d.data();final stamp=x['createdAt'];final when=stamp is Timestamp?stamp.toDate().toLocal().toString().split('.').first:'Date unavailable';return ListTile(
        leading:const CircleAvatar(child:Icon(Icons.notifications_outlined)),
        title:Text((x['title']??'Notification').toString()),
        subtitle:Text((x['body']??'').toString()+'\n'+when),
        isThreeLine:true,
      );}).toList()));
    },
  ));
}

class SystemSettingsPage extends StatelessWidget {
  const SystemSettingsPage({super.key});
  @override
  Widget build(BuildContext context){
    final user=FirebaseAuth.instance.currentUser;
    return _UtilityPage(title:'System settings',subtitle:'Account and environment information. App-wide configuration is intentionally not written to an unknown collection.',child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('Administrator account',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
        const SizedBox(height:12),
        ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.person_outline),title:Text(user?.displayName??'Administrator'),subtitle:Text(user?.email??'No email available')),
        ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.verified_user_outlined),title:const Text('Access control'),subtitle:const Text('Admin access is validated against users/{uid}.role == admin')),
        ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.cloud_outlined),title:const Text('Data source'),subtitle:const Text('Firebase Authentication + Cloud Firestore')),
      ]))),
      const SizedBox(height:14),
      const Card(child:Padding(padding:EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('Configuration safety',style:TextStyle(fontWeight:FontWeight.bold)),
        SizedBox(height:8),
        Text('Payment credentials, shipping integrations, Cloudinary secrets, and staff permissions must be configured through secure backend settings. They are not editable from this client-side screen.'),
      ]))),
    ]));
  }
}

class _UtilityPage extends StatelessWidget {
  final String title,subtitle;final Widget child;
  const _UtilityPage({required this.title,required this.subtitle,required this.child});
  @override
  Widget build(BuildContext context)=>SingleChildScrollView(padding:const EdgeInsets.all(22),child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:1450),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(title,style:const TextStyle(fontSize:25,fontWeight:FontWeight.w900)),
    const SizedBox(height:4),Text(subtitle,style:const TextStyle(color:Colors.grey)),
    const SizedBox(height:20),child,
  ]))));
}
