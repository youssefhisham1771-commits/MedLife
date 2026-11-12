import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'legacy_admin_dashboard.dart' as legacy;
import 'admin_extra_pages.dart';

const _nav = <(String,IconData)>[
 ('Overview',Icons.grid_view_rounded),('Orders',Icons.shopping_bag_outlined),
 ('Products & Stock',Icons.inventory_2_outlined),('Customers',Icons.people_alt_outlined),
 ('Finance & Reports',Icons.query_stats_rounded),('Staff',Icons.badge_outlined),
 ('AI Assistant',Icons.auto_awesome),('Automation',Icons.account_tree_outlined),
 ('Activity Log',Icons.history_rounded),('Inventory',Icons.warehouse_outlined),
 ('Marketing',Icons.campaign_outlined),('Delivery Settings',Icons.local_shipping_outlined),
 ('Advanced Reports',Icons.analytics_outlined),('Existing Admin Tools',Icons.apps_rounded),
];

class CommandCenter extends StatefulWidget {
 final ValueChanged<bool> onThemeChanged;
 const CommandCenter({super.key,required this.onThemeChanged});
 @override State<CommandCenter> createState()=>_CommandCenterState();
}
class _CommandCenterState extends State<CommandCenter>{
 int index=0; bool dark=true;
 @override Widget build(BuildContext context){
  final wide=MediaQuery.sizeOf(context).width>=1000;
  return Scaffold(
   drawer:wide?null:Drawer(child:_sidebar(true)),
   body:Row(children:[if(wide)_sidebar(false),Expanded(child:Column(children:[
    Container(height:72,padding:const EdgeInsets.symmetric(horizontal:20),decoration:BoxDecoration(border:Border(bottom:BorderSide(color:Theme.of(context).dividerColor))),
     child:Row(children:[
      if(!wide)Builder(builder:(c)=>IconButton(onPressed:()=>Scaffold.of(c).openDrawer(),icon:const Icon(Icons.menu))),
      Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[
       Text(_nav[index].$1,style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
       const Text('MedLife business control center',style:TextStyle(color:Colors.grey,fontSize:11))
      ])),
      IconButton(tooltip:'Toggle theme',onPressed:(){setState(()=>dark=!dark);widget.onThemeChanged(dark);},icon:Icon(dark?Icons.light_mode:Icons.dark_mode)),
      const CircleAvatar(child:Icon(Icons.person_outline))
     ])),
    Expanded(child:_content())
   ]))]),
   bottomNavigationBar:wide?null:NavigationBar(selectedIndex:index<5?index:4,onDestinationSelected:(v)=>setState(()=>index=v),destinations:const[
    NavigationDestination(icon:Icon(Icons.grid_view),label:'Home'),NavigationDestination(icon:Icon(Icons.shopping_bag),label:'Orders'),
    NavigationDestination(icon:Icon(Icons.inventory_2),label:'Products'),NavigationDestination(icon:Icon(Icons.people),label:'Customers'),
    NavigationDestination(icon:Icon(Icons.more_horiz),label:'More')
   ]),
  );
 }
 Widget _sidebar(bool drawer)=>Container(width:drawer?null:250,color:Theme.of(context).brightness==Brightness.dark?const Color(0xff0d1729):Colors.white,padding:const EdgeInsets.all(15),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
  const SizedBox(height:10),const Row(children:[CircleAvatar(backgroundColor:Color(0xff3478f6),child:Icon(Icons.medical_services,color:Colors.white)),SizedBox(width:10),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('MEDLIFE',style:TextStyle(fontWeight:FontWeight.w900,letterSpacing:1.4)),Text('COMMAND CENTER',style:TextStyle(fontSize:9,color:Colors.grey,letterSpacing:1.5))])]),
  const SizedBox(height:25),const Padding(padding:EdgeInsets.all(10),child:Text('WORKSPACE',style:TextStyle(color:Colors.grey,fontSize:10,letterSpacing:2))),
  Expanded(child:ListView.builder(itemCount:_nav.length,itemBuilder:(c,i)=>ListTile(dense:true,selected:index==i,selectedTileColor:const Color(0xff3478f6).withValues(alpha:.15),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)),leading:Icon(_nav[i].$2,color:index==i?const Color(0xff4c8cff):null),title:Text(_nav[i].$1,style:const TextStyle(fontSize:12)),onTap:(){setState(()=>index=i);if(drawer)Navigator.pop(context);}))),
  const Divider(),ListTile(leading:const Icon(Icons.logout,color:Colors.redAccent),title:const Text('Sign out',style:TextStyle(color:Colors.redAccent)),onTap:()=>FirebaseAuth.instance.signOut())
 ]));
 }
 Widget _content()=>switch(index){
  0=>const OverviewPage(),1=>const OrdersPage(),2=>const ProductsPage(),3=>const CustomersPage(),
  4=>const FinancePage(),5=>const StaffPage(),6=>const AssistantPage(),7=>const AutomationPage(),
  8=>const ActivityPage(),9=>const InventoryPage(),10=>const MarketingPage(),
  11=>const DeliverySettingsPage(),12=>const ReportsPage(),_=>const legacy.DashboardScreen()
 };
}

class _Page extends StatelessWidget{
 final Widget child;const _Page(this.child);
 @override Widget build(BuildContext c)=>SingleChildScrollView(padding:const EdgeInsets.all(22),child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:1450),child:child)));
}
double _n(dynamic x)=>x is num?x.toDouble():double.tryParse('$x')??0;
Future<void> _log(String action,String id)async{
 final u=FirebaseAuth.instance.currentUser;
 await FirebaseFirestore.instance.collection('adminAuditLogs').add({'action':action,'targetId':id,'actorUid':u?.uid,'actorEmail':u?.email,'createdAt':FieldValue.serverTimestamp()});
}
Widget _metric(String title,String value,IconData icon,Color color)=>SizedBox(width:205,child:Card(child:Padding(padding:const EdgeInsets.all(17),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
 Container(padding:const EdgeInsets.all(9),decoration:BoxDecoration(color:color.withValues(alpha:.13),borderRadius:BorderRadius.circular(10)),child:Icon(icon,color:color)),
 const SizedBox(height:18),Text(value,style:const TextStyle(fontSize:23,fontWeight:FontWeight.w900)),Text(title,style:const TextStyle(color:Colors.grey,fontSize:12))
]))));
Widget _panel(String title,Widget child)=>Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:12),child])));
class OverviewPage extends StatelessWidget{const OverviewPage({super.key});
 @override Widget build(BuildContext c)=>_Page(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
 const Text('Business overview',style:TextStyle(fontSize:25,fontWeight:FontWeight.w900)),const Text('Live metrics from your current Firestore data.',style:TextStyle(color:Colors.grey)),const SizedBox(height:18),
 StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('orders').snapshots(),builder:(c,o){
  if(!o.hasData)return const Center(child:CircularProgressIndicator());
  return StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('Products').snapshots(),builder:(c,p){
   if(!p.hasData)return const Center(child:CircularProgressIndicator());
   return StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('users').snapshots(),builder:(c,u){
    if(!u.hasData)return const Center(child:CircularProgressIndicator());
    final orders=o.data!.docs;final delivered=orders.where((d)=>d.data()['status']=='delivered').toList();
    final revenue=delivered.fold<double>(0,(s,d)=>s+_n(d.data()['total']));
    final pending=orders.where((d)=>d.data()['status']=='pending').length;
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Wrap(spacing:12,runSpacing:12,children:[
      _metric('Products',p.data!.size.toString(),Icons.inventory_2,Colors.blue),
      _metric('Orders',orders.length.toString(),Icons.shopping_bag,Colors.orange),
      _metric('Customers',u.data!.docs.where((d)=>d.data()['role']!='admin').length.toString(),Icons.people,Colors.green),
      _metric('Delivered revenue',revenue.toStringAsFixed(0)+' EGP',Icons.payments,Colors.purple),
      _metric('Pending orders',pending.toString(),Icons.schedule,Colors.amber),
     ]),
     const SizedBox(height:18),
     _panel('Order status',Column(children:[for(final s in ['pending','processing','shipped','delivered','cancelled'])ListTile(dense:true,title:Text(s),trailing:Text(orders.where((d)=>d.data()['status']==s).length.toString()))])),
     const SizedBox(height:15),_panel('Latest orders',Column(children:orders.take(6).map((d)=>ListTile(title:Text('Order '+d.id),subtitle:Text((d.data()['status']??'unknown').toString()),trailing:Text(_n(d.data()['total']).toStringAsFixed(0)+' EGP'))).toList()))
    ]);
   });
  });
 })
 ]));
}
class OrdersPage extends StatefulWidget {
 const OrdersPage({super.key});
 @override State<OrdersPage> createState()=>_OrdersPageState();
}
class _OrdersPageState extends State<OrdersPage>{
 final search=TextEditingController(); String status='All'; String sort='Newest first';
 @override void dispose(){search.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>_Page(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
  const Text('Orders management',style:TextStyle(fontSize:24,fontWeight:FontWeight.w900)),
  const SizedBox(height:14),
  Wrap(spacing:12,runSpacing:10,children:[
   SizedBox(width:340,child:TextField(controller:search,onChanged:(_)=>setState((){}),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Search order, customer or phone',border:OutlineInputBorder()))),
   SizedBox(width:180,child:DropdownButtonFormField<String>(value:status,decoration:const InputDecoration(labelText:'Status',border:OutlineInputBorder()),items:['All','pending','processing','shipped','delivered','cancelled'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>setState(()=>status=v??'All'))),
   SizedBox(width:180,child:DropdownButtonFormField<String>(value:sort,decoration:const InputDecoration(labelText:'Sort by',border:OutlineInputBorder()),items:['Newest first','Oldest first','Highest value','Lowest value'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>setState(()=>sort=v??'Newest first'))),
  ]),
  const SizedBox(height:15),
  StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('orders').snapshots(),builder:(context,s){
   if(s.hasError)return Text('Orders error: '+s.error.toString());
   if(!s.hasData)return const Center(child:CircularProgressIndicator());
   final docs=s.data!.docs.toList(); final q=search.text.trim().toLowerCase();
   docs.removeWhere((d){final x=d.data();final st=(x['status']??'pending').toString().toLowerCase();final matchStatus=status=='All'||st==status;final matchQuery=q.isEmpty||d.id.toLowerCase().contains(q)||(x['name']??'').toString().toLowerCase().contains(q)||(x['phone']??'').toString().toLowerCase().contains(q);return !matchStatus||!matchQuery;});
   docs.sort((a,b){if(sort=='Highest value')return _n(b.data()['total']).compareTo(_n(a.data()['total']));if(sort=='Lowest value')return _n(a.data()['total']).compareTo(_n(b.data()['total']));final av=a.data()['orderedAt'],bv=b.data()['orderedAt'];final ad=av is Timestamp?av.toDate():DateTime.fromMillisecondsSinceEpoch(0);final bd=bv is Timestamp?bv.toDate():DateTime.fromMillisecondsSinceEpoch(0);return sort=='Oldest first'?ad.compareTo(bd):bd.compareTo(ad);});
   if(docs.isEmpty)return const Center(child:Padding(padding:EdgeInsets.all(30),child:Text('No matching orders')));
   return Card(child:Column(children:docs.map((d){final x=d.data();final items=x['items'] is List?x['items'] as List:[];final t=x['orderedAt'];final date=t is Timestamp?t.toDate().toLocal().toString().split('.').first:'Date unavailable';final current=(x['status']??'pending').toString();const choices=['pending','processing','shipped','delivered','cancelled'];return Column(children:[
    ListTile(leading:const CircleAvatar(child:Icon(Icons.receipt_long)),title:Text('Order '+(d.id.length>8?d.id.substring(0,8):d.id)+' · '+(x['name']??'Customer').toString()),subtitle:Text((x['phone']??'No phone').toString()+' · '+date+' · '+items.length.toString()+' item(s)'),trailing:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.end,children:[Text(_n(x['total']).toStringAsFixed(2)+' EGP',style:const TextStyle(fontWeight:FontWeight.bold)),Text(current,style:const TextStyle(color:Colors.grey,fontSize:11))]),onTap:()=>_details(context,d)),
    Padding(padding:const EdgeInsets.fromLTRB(16,0,16,10),child:Row(children:[const Text('Update status',style:TextStyle(color:Colors.grey,fontSize:11)),const Spacer(),SizedBox(width:170,child:DropdownButtonFormField<String>(value:choices.contains(current)?current:'pending',isDense:true,items:choices.map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)async{if(v!=null){await d.reference.update({'status':v,'updatedAt':FieldValue.serverTimestamp()});await _log('order_status_updated',d.id);}}))])),
    const Divider(height:1),
   ]);}).toList()));
  }),
 ]));
 Future<void> _details(BuildContext context,QueryDocumentSnapshot<Map<String,dynamic>> doc)async{
  final x=doc.data();final items=x['items'] is List?x['items'] as List:[];
  await showDialog<void>(context:context,builder:(ctx)=>AlertDialog(title:Text('Order '+doc.id),content:SizedBox(width:480,child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
   Text('Customer: '+(x['name']??'—').toString()),Text('Phone: '+(x['phone']??'—').toString()),Text('Address: '+(x['address']??'—').toString()),Text('Status: '+(x['status']??'pending').toString()),Text('Total: '+_n(x['total']).toStringAsFixed(2)+' EGP'),const Divider(),const Text('Items',style:TextStyle(fontWeight:FontWeight.bold)),
   ...items.map((item){final m=item is Map?item:<dynamic,dynamic>{};return ListTile(contentPadding:EdgeInsets.zero,title:Text((m['name']??'Product').toString()),subtitle:Text('Qty: '+(m['quantity']??1).toString()+' · Size: '+(m['size']??'—').toString()),trailing:Text(_n(m['price']).toStringAsFixed(2)+' EGP'));}),
  ]))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Close'))]));
 }
}
class ProductsPage extends StatelessWidget{const ProductsPage({super.key});
 Future<void> _edit(BuildContext c,[QueryDocumentSnapshot<Map<String,dynamic>>? doc])async{
  final d=doc?.data()??{};final name=TextEditingController(text:(d['name']??'').toString());final price=TextEditingController(text:(d['price']??'').toString());final image=TextEditingController(text:(d['image']??'').toString());final category=TextEditingController(text:(d['category']??'').toString());final sizes=TextEditingController(text:d['sizes'] is List?(d['sizes'] as List).join(', '):'');
  final key=GlobalKey<FormState>();final ok=await showDialog<bool>(context:c,builder:(x)=>AlertDialog(title:Text(doc==null?'Add product':'Edit product'),content:Form(key:key,child:SizedBox(width:430,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
   TextFormField(controller:name,decoration:const InputDecoration(labelText:'Name'),validator:(v)=>v==null||v.trim().isEmpty?'Required':null),
   TextFormField(controller:price,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Price EGP'),validator:(v)=>double.tryParse(v??'')==null?'Enter a valid price':null),
   TextFormField(controller:image,decoration:const InputDecoration(labelText:'Image URL')),TextFormField(controller:category,decoration:const InputDecoration(labelText:'Category')),TextFormField(controller:sizes,decoration:const InputDecoration(labelText:'Sizes, comma separated'))
  ])))),actions:[TextButton(onPressed:()=>Navigator.pop(x,false),child:const Text('Cancel')),FilledButton(onPressed:(){if(key.currentState!.validate())Navigator.pop(x,true);},child:const Text('Save'))]));
  if(ok!=true)return;final data=<String,dynamic>{'name':name.text.trim(),'price':double.parse(price.text),'image':image.text.trim(),'category':category.text.trim(),'sizes':sizes.text.split(',').map((e)=>e.trim()).where((e)=>e.isNotEmpty).toList(),'updatedAt':FieldValue.serverTimestamp()};
  if(doc==null){data['createdAt']=FieldValue.serverTimestamp();final r=await FirebaseFirestore.instance.collection('Products').add(data);await _log('product_created',r.id);}else{await doc.reference.update(data);await _log('product_updated',doc.id);}
 }
 @override Widget build(BuildContext c)=>_Page(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
 Row(children:[const Expanded(child:Text('Products & stock',style:TextStyle(fontSize:24,fontWeight:FontWeight.w900))),FilledButton.icon(onPressed:()=>_edit(c),icon:const Icon(Icons.add),label:const Text('Add product'))]),const SizedBox(height:15),
 StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('Products').snapshots(),builder:(c,s){
  if(s.hasError)return Text('Product error: '+s.error.toString());if(!s.hasData)return const Center(child:CircularProgressIndicator());
  return Card(child:Column(children:s.data!.docs.map((d)=>ListTile(leading:const CircleAvatar(child:Icon(Icons.inventory_2)),title:Text((d.data()['name']??'Unnamed').toString()),subtitle:Text(_n(d.data()['price']).toStringAsFixed(2)+' EGP · '+(d.data()['category']??'').toString()),trailing:Wrap(children:[
   IconButton(onPressed:()=>_edit(c,d),icon:const Icon(Icons.edit_outlined)),IconButton(onPressed:()async{final yes=await showDialog<bool>(context:c,builder:(x)=>AlertDialog(title:const Text('Delete product?'),actions:[TextButton(onPressed:()=>Navigator.pop(x,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(x,true),child:const Text('Delete'))]));if(yes==true){await d.reference.delete();await _log('product_deleted',d.id);}},icon:const Icon(Icons.delete_outline,color:Colors.red))
  ]) )).toList()));
 })
 ]));
}
class CustomersPage extends StatelessWidget{const CustomersPage({super.key});
 @override Widget build(BuildContext c)=>_Page(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Customers',style:TextStyle(fontSize:24,fontWeight:FontWeight.w900)),const SizedBox(height:15),
 StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('users').snapshots(),builder:(c,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());final docs=s.data!.docs.where((d)=>d.data()['role']!='admin');return Card(child:Column(children:docs.map((d)=>ListTile(leading:const CircleAvatar(child:Icon(Icons.person_outline)),title:Text((d.data()['name']??'Customer').toString()),subtitle:Text((d.data()['email']??'').toString()),trailing:Text((d.data()['phone']??'').toString()))).toList()));})
 ]));
}
class FinancePage extends StatelessWidget{const FinancePage({super.key});
 @override Widget build(BuildContext c)=>_Page(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Finance & reports',style:TextStyle(fontSize:24,fontWeight:FontWeight.w900)),const Text('Revenue uses delivered orders and their existing total field; it is not net profit.',style:TextStyle(color:Colors.grey)),const SizedBox(height:15),
 StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('orders').snapshots(),builder:(c,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());final docs=s.data!.docs;final done=docs.where((d)=>d.data()['status']=='delivered');final sum=done.fold<double>(0,(v,d)=>v+_n(d.data()['total']));return Wrap(spacing:12,runSpacing:12,children:[_metric('Delivered sales',sum.toStringAsFixed(2)+' EGP',Icons.payments,Colors.green),_metric('Delivered orders',done.length.toString(),Icons.task_alt,Colors.blue),_metric('Average order', (done.isEmpty?0:sum/done.length).toStringAsFixed(2)+' EGP',Icons.calculate,Colors.purple)]);})
 ]));
}
class StaffPage extends StatelessWidget{const StaffPage({super.key});
 @override Widget build(BuildContext c)=>_Page(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Staff & permissions',style:TextStyle(fontSize:24,fontWeight:FontWeight.w900)),const Card(child:Padding(padding:EdgeInsets.all(16),child:Text('Security note: the current application and Firestore rules authorize administrators using users/{uid}.role == admin. This page is read-only until a server-enforced staff role system is migrated, to avoid accidentally granting unsafe access.'))),
 StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('users').where('role',isEqualTo:'admin').snapshots(),builder:(c,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());return Card(child:Column(children:s.data!.docs.map((d)=>ListTile(leading:const Icon(Icons.admin_panel_settings),title:Text((d.data()['name']??'Admin').toString()),subtitle:Text((d.data()['email']??d.id).toString()),trailing:const Chip(label:Text('Admin')))).toList()));})
 ]));
}
class AssistantPage extends StatefulWidget{const AssistantPage({super.key});@override State<AssistantPage> createState()=>_AssistantPageState();}
class _AssistantPageState extends State<AssistantPage>{
 final q=TextEditingController();String answer='Ask about sales, pending orders, stock, or customers. This version calculates answers from live Firestore data; it is not connected to an external generative AI model.';bool loading=false;
 Future<void> ask()async{setState(()=>loading=true);try{final r=await Future.wait([FirebaseFirestore.instance.collection('orders').get(),FirebaseFirestore.instance.collection('Products').get(),FirebaseFirestore.instance.collection('users').get()]);final orders=r[0].docs;final revenue=orders.where((d)=>d.data()['status']=='delivered').fold<double>(0,(v,d)=>v+_n(d.data()['total']));final pending=orders.where((d)=>d.data()['status']=='pending').length;final text=q.text.toLowerCase();String a;if(text.contains('sales')||text.contains('revenue')||text.contains('مبيعات')){a='Delivered sales: '+revenue.toStringAsFixed(2)+' EGP. This is gross sales, not profit.';}else if(text.contains('pending')||text.contains('طلبات')){a='Pending orders: '+pending.toString()+' from '+orders.length.toString()+' total orders.';}else if(text.contains('stock')||text.contains('مخزون')){final low=r[1].docs.where((d)=>d.data()['quantity'] is num&&(d.data()['quantity'] as num)<=5).length;a='Low-stock products with a numeric quantity of 5 or less: '+low.toString()+'. Products without quantity are excluded.';}else{a='Live snapshot: '+orders.length.toString()+' orders, '+r[1].size.toString()+' products, '+r[2].size.toString()+' user accounts, '+revenue.toStringAsFixed(2)+' EGP delivered sales.';}setState(()=>answer=a);}catch(e){setState(()=>answer='Could not read the current data: '+e.toString());}finally{setState(()=>loading=false);}}
 @override Widget build(BuildContext c)=>_Page(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('AI assistant',style:TextStyle(fontSize:24,fontWeight:FontWeight.w900)),const Text('Live-data assistant preview. Secure AI provider integration is a separate backend step.',style:TextStyle(color:Colors.grey)),const SizedBox(height:15),Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(children:[TextField(controller:q,onSubmitted:(_)=>ask(),decoration:InputDecoration(hintText:'Ask a question about MedLife',suffixIcon:IconButton(onPressed:loading?null:ask,icon:const Icon(Icons.send)))),const SizedBox(height:15),if(loading)const LinearProgressIndicator(),SelectableText(answer)]))) ]));
}
class AutomationPage extends StatelessWidget{const AutomationPage({super.key});
 Future<void> add(BuildContext c)async{final name=TextEditingController(text:'Notify admins about new orders');String trigger='order_created';final ok=await showDialog<bool>(context:c,builder:(x)=>StatefulBuilder(builder:(x,set)=>AlertDialog(title:const Text('New automation'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:name,decoration:const InputDecoration(labelText:'Rule name')),DropdownButtonFormField<String>(value:trigger,items:const[DropdownMenuItem(value:'order_created',child:Text('When an order is created')),DropdownMenuItem(value:'order_status_changed',child:Text('When order status changes'))],onChanged:(v)=>set(()=>trigger=v??'order_created'))]),actions:[TextButton(onPressed:()=>Navigator.pop(x,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(x,true),child:const Text('Save'))])));if(ok==true&&name.text.trim().isNotEmpty){final r=await FirebaseFirestore.instance.collection('automationRules').add({'name':name.text.trim(),'trigger':trigger,'action':'admin_notification','enabled':true,'createdAt':FieldValue.serverTimestamp()});await _log('automation_created',r.id);}}
 @override Widget build(BuildContext c)=>_Page(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[const Expanded(child:Text('Automation center',style:TextStyle(fontSize:24,fontWeight:FontWeight.w900))),FilledButton.icon(onPressed:()=>add(c),icon:const Icon(Icons.add),label:const Text('New rule'))]),const Text('Rules are stored in Firestore. Event execution requires deployment of the matching Cloud Functions.',style:TextStyle(color:Colors.grey)),const SizedBox(height:15),
 StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('automationRules').snapshots(),builder:(c,s){if(s.hasError)return Text('Automation rules unavailable: '+s.error.toString());if(!s.hasData)return const Center(child:CircularProgressIndicator());return Card(child:Column(children:s.data!.docs.map((d)=>SwitchListTile(title:Text((d.data()['name']??'Rule').toString()),subtitle:Text((d.data()['trigger']??'').toString()),value:d.data()['enabled']==true,onChanged:(v)async{await d.reference.update({'enabled':v});await _log('automation_toggled',d.id);},secondary:IconButton(onPressed:()async{await d.reference.delete();await _log('automation_deleted',d.id);},icon:const Icon(Icons.delete_outline)))).toList()));})
 ]));
}
class ActivityPage extends StatelessWidget{const ActivityPage({super.key});
 @override Widget build(BuildContext c)=>_Page(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Activity log',style:TextStyle(fontSize:24,fontWeight:FontWeight.w900)),const SizedBox(height:15),
 StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('adminAuditLogs').orderBy('createdAt',descending:true).limit(100).snapshots(),builder:(c,s){if(s.hasError)return Text('Activity log unavailable: '+s.error.toString());if(!s.hasData)return const Center(child:CircularProgressIndicator());return Card(child:Column(children:s.data!.docs.map((d)=>ListTile(leading:const Icon(Icons.history),title:Text((d.data()['action']??'Action').toString()),subtitle:Text((d.data()['targetId']??'').toString()+' · '+(d.data()['actorEmail']??'').toString()))).toList()));})
 ]));
}
