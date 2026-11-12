import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

double _value(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
Future<void> _record(String action, String id) async { await FirebaseFirestore.instance.collection('adminAuditLogs').add({'action': action, 'targetId': id, 'createdAt': FieldValue.serverTimestamp()}); }

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});
  @override
  Widget build(BuildContext context) => _Page(title: 'Inventory & stock', subtitle: 'Track product quantities in the existing Products collection.', child: StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
    stream: FirebaseFirestore.instance.collection('Products').snapshots(),
    builder: (context, s) {
      if (s.hasError) return Text(s.error.toString());
      if (!s.hasData) return const Center(child: CircularProgressIndicator());
      final docs = s.data!.docs;
      final tracked = docs.where((d) => d.data()['quantity'] is num).toList();
      final low = tracked.where((d) => (d.data()['quantity'] as num) <= 5).length;
      return Column(children: [
        Wrap(spacing: 12, children: [
          _stat('Products', docs.length.toString(), Icons.inventory_2),
          _stat('Tracked', tracked.length.toString(), Icons.fact_check),
          _stat('Low stock', low.toString(), Icons.warning_amber),
        ]),
        const SizedBox(height: 14),
        Card(child: Column(children: docs.map((d) {
          final data = d.data();
          final qty = data['quantity'];
          return ListTile(
            title: Text((data['name'] ?? 'Unnamed product').toString()),
            subtitle: Text(qty is num ? 'Quantity: ' + qty.toString() : 'Quantity not set'),
            trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () async {
              final c = TextEditingController(text: qty is num ? qty.toInt().toString() : '0');
              final form = GlobalKey<FormState>();
              final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                title: const Text('Update stock'),
                content: Form(key: form, child: TextFormField(controller: c, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Available quantity'), validator: (v) { final n = int.tryParse(v ?? ''); return n == null || n < 0 ? 'Enter a valid quantity' : null; })),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () { if (form.currentState!.validate()) Navigator.pop(ctx, true); }, child: const Text('Save'))],
              ));
              if (ok == true) { await d.reference.update({'quantity': int.parse(c.text), 'updatedAt': FieldValue.serverTimestamp()}); await _record('inventory_updated', d.id); }
            }),
          );
        }).toList())),
      ]);
    },
  ));
}

class MarketingPage extends StatelessWidget {
  const MarketingPage({super.key});
  @override
  Widget build(BuildContext context) => _Page(title: 'Marketing & promotions', subtitle: 'Manage promo codes and homepage banners.', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [const Expanded(child: Text('Promo codes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))), FilledButton.icon(onPressed: () => _coupon(context), icon: const Icon(Icons.add), label: const Text('New code'))]),
    const SizedBox(height: 10),
    StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream: FirebaseFirestore.instance.collection('promoCodes').snapshots(), builder: (context,s) {
      if (s.hasError) return Text(s.error.toString());
      if (!s.hasData) return const CircularProgressIndicator();
      return Card(child: Column(children: s.data!.docs.map((d) => ListTile(
        title: Text(d.id),
        subtitle: Text('Discount: ' + (d.data()['discount'] ?? '—').toString() + '%'),
        trailing: Switch(value: d.data()['active'] == true, onChanged: (v) async { await d.reference.update({'active':v}); await _record('promo_toggled',d.id); }),
      )).toList()));
    }),
    const SizedBox(height: 20),
    Row(children: [const Expanded(child: Text('Homepage banners', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))), TextButton.icon(onPressed: () => _banner(context), icon: const Icon(Icons.add), label: const Text('Add banner'))]),
    StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream: FirebaseFirestore.instance.collection('banners').snapshots(), builder: (context,s) {
      if (s.hasError) return Text(s.error.toString());
      if (!s.hasData) return const CircularProgressIndicator();
      return Card(child: Column(children: s.data!.docs.map((d) => ListTile(
        leading: const Icon(Icons.image_outlined), title: Text('Banner ' + d.id),
        subtitle: Text((d.data()['image'] ?? '').toString(), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async { await d.reference.delete(); await _record('banner_deleted',d.id); }),
      )).toList()));
    }),
  ]));
  Future<void> _coupon(BuildContext context) async {
    final code = TextEditingController(); final discount = TextEditingController(); final form = GlobalKey<FormState>();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('New promo code'), content: Form(key:form, child: Column(mainAxisSize:MainAxisSize.min, children:[
      TextFormField(controller:code, decoration:const InputDecoration(labelText:'Code'), validator:(v)=>v==null||v.trim().isEmpty?'Required':null),
      TextFormField(controller:discount, keyboardType:TextInputType.number, decoration:const InputDecoration(labelText:'Discount %'), validator:(v){final n=int.tryParse(v??'');return n==null||n<1||n>100?'Enter 1–100':null;}),
    ])), actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:(){if(form.currentState!.validate())Navigator.pop(ctx,true);},child:const Text('Create'))]));
    if(ok==true){final id=code.text.trim().toUpperCase();await FirebaseFirestore.instance.collection('promoCodes').doc(id).set({'discount':int.parse(discount.text),'active':true,'createdAt':FieldValue.serverTimestamp()});await _record('promo_created',id);}
  }
  Future<void> _banner(BuildContext context) async {
    final url=TextEditingController(); final form=GlobalKey<FormState>();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Add banner'),content:Form(key:form,child:TextFormField(controller:url,decoration:const InputDecoration(labelText:'Image URL'),validator:(v)=>v==null||Uri.tryParse(v)?.hasAbsolutePath!=true?'Enter a valid URL':null)),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:(){if(form.currentState!.validate())Navigator.pop(ctx,true);},child:const Text('Save'))]));
    if(ok==true){final r=await FirebaseFirestore.instance.collection('banners').add({'image':url.text.trim()});await _record('banner_created',r.id);}
  }
}

class DeliverySettingsPage extends StatelessWidget {
  const DeliverySettingsPage({super.key});
  @override
  Widget build(BuildContext context) => _Page(title:'Delivery settings', subtitle:'Manage delivery fees by area.', child:Column(children:[
    Align(alignment:Alignment.centerRight,child:FilledButton.icon(onPressed:()=>_edit(context),icon:const Icon(Icons.add),label:const Text('Add area'))),
    StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('deliveryFees').snapshots(),builder:(context,s){
      if(s.hasError)return Text(s.error.toString()); if(!s.hasData)return const CircularProgressIndicator();
      return Card(child:Column(children:s.data!.docs.map((d)=>ListTile(
        title:Text(d.id),subtitle:Text('Fee: ' + _value(d.data()['fee'] ?? d.data()['price'] ?? d.data()['deliveryFee']).toStringAsFixed(2) + ' EGP'),
        trailing:IconButton(icon:const Icon(Icons.edit),onPressed:()=>_edit(context,d)),
      )).toList()));
    }),
  ]));
  Future<void> _edit(BuildContext context,[QueryDocumentSnapshot<Map<String,dynamic>>? doc]) async {
    final area=TextEditingController(text:doc?.id??''); final fee=TextEditingController(text:(doc?.data()['fee']??doc?.data()['price']??'').toString()); final form=GlobalKey<FormState>();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:Text(doc==null?'Add delivery area':'Edit delivery fee'),content:Form(key:form,child:Column(mainAxisSize:MainAxisSize.min,children:[
      TextFormField(controller:area,enabled:doc==null,decoration:const InputDecoration(labelText:'Area'),validator:(v)=>v==null||v.trim().isEmpty?'Required':null),
      TextFormField(controller:fee,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Fee EGP'),validator:(v)=>double.tryParse(v??'')==null?'Enter a valid fee':null),
    ])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:(){if(form.currentState!.validate())Navigator.pop(ctx,true);},child:const Text('Save'))]));
    if(ok==true){final id=area.text.trim();await FirebaseFirestore.instance.collection('deliveryFees').doc(id).set({'fee':double.parse(fee.text)},SetOptions(merge:true));await _record(doc==null?'delivery_area_created':'delivery_fee_updated',id);}
  }
}

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});
  @override
  Widget build(BuildContext context) => _Page(title:'Advanced reports', subtitle:'Operational and financial summaries from live Firestore data.', child:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('orders').snapshots(),builder:(context,s){
    if(s.hasError)return Text(s.error.toString());if(!s.hasData)return const CircularProgressIndicator();
    final docs=s.data!.docs; final delivered=docs.where((d)=>d.data()['status']=='delivered').toList();
    final sales=delivered.fold<double>(0,(sum,d)=>sum+_value(d.data()['total']));
    final cancelled=docs.where((d)=>d.data()['status']=='cancelled').length;
    final statuses=<String,int>{};for(final d in docs){final k=(d.data()['status']??'unknown').toString();statuses[k]=(statuses[k]??0)+1;}
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Wrap(spacing:12,runSpacing:12,children:[
        _stat('Gross delivered sales',sales.toStringAsFixed(2)+' EGP',Icons.payments),
        _stat('Delivered orders',delivered.length.toString(),Icons.task_alt),
        _stat('Average order', (delivered.isEmpty?0:sales/delivered.length).toStringAsFixed(2)+' EGP',Icons.calculate),
        _stat('Cancellation rate',docs.isEmpty?'0%':(cancelled*100/docs.length).toStringAsFixed(1)+'%',Icons.cancel_outlined),
      ]),
      const SizedBox(height:18),
      Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('Orders by status',style:TextStyle(fontWeight:FontWeight.bold,fontSize:18)),
        const SizedBox(height:12),
        ...statuses.entries.map((e)=>Padding(padding:const EdgeInsets.symmetric(vertical:7),child:Row(children:[
          SizedBox(width:110,child:Text(e.key)),Expanded(child:LinearProgressIndicator(value:docs.isEmpty?0:e.value/docs.length,minHeight:8)),const SizedBox(width:10),Text(e.value.toString()),
        ]))),
        const Divider(height:28),
        const Text('These figures show gross delivered order totals, not net profit. Product costs, refunds, shipping costs and payment fees are not deducted.',style:TextStyle(color:Colors.grey)),
      ]))),
    ]);
  }));
}

class _Page extends StatelessWidget {
  final String title,subtitle; final Widget child;
  const _Page({required this.title,required this.subtitle,required this.child});
  @override
  Widget build(BuildContext context)=>SingleChildScrollView(padding:const EdgeInsets.all(22),child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:1450),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(title,style:const TextStyle(fontSize:25,fontWeight:FontWeight.w900)),const SizedBox(height:4),Text(subtitle,style:const TextStyle(color:Colors.grey)),const SizedBox(height:20),child,
  ]))));
}
Widget _stat(String title,String value,IconData icon)=>SizedBox(width:215,child:Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:Colors.blue),const SizedBox(height:12),Text(value,style:const TextStyle(fontSize:21,fontWeight:FontWeight.bold)),Text(title,style:const TextStyle(color:Colors.grey,fontSize:12))]))));
