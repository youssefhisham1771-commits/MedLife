import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'admin_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MedLifeAdminApp());
}

class MedLifeAdminApp extends StatefulWidget {
  const MedLifeAdminApp({super.key});
  @override
  State<MedLifeAdminApp> createState() => _MedLifeAdminAppState();
}

class _MedLifeAdminAppState extends State<MedLifeAdminApp> {
  ThemeMode mode = ThemeMode.light;
  void toggleTheme() => setState(() => mode = mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MedLife Admin',
    debugShowCheckedModeBanner: false,
    themeMode: mode,
    theme: _theme(Brightness.light),
    darkTheme: _theme(Brightness.dark),
    home: AuthGate(onThemeToggle: toggleTheme),
  );
}

ThemeData _theme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  const blue = Color(0xFF1769E0);
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(seedColor: blue, brightness: brightness),
    scaffoldBackgroundColor: dark ? const Color(0xFF0B1430) : const Color(0xFFF3F6FC),
    cardTheme: CardThemeData(
      elevation: 0,
      color: dark ? const Color(0xFF172342) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: dark ? Colors.white10 : const Color(0xFFE5EAF4))),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF172342) : const Color(0xFFF5F7FC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    ),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.onThemeToggle});
  final VoidCallback onThemeToggle;
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, auth) {
      if (auth.connectionState == ConnectionState.waiting) return const _Loading();
      if (auth.data == null) return const AdminLoginPage();
      return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance.collection('users').doc(auth.data!.uid).get(),
        builder: (context, profile) {
          if (profile.connectionState == ConnectionState.waiting) return const _Loading();
          if (!profile.hasData || profile.data?.data()?['role'] != 'admin') {
            FirebaseAuth.instance.signOut();
            return const AdminLoginPage(message: 'This account does not have administrator access.');
          }
          return AdminShell(onThemeToggle: onThemeToggle);
        },
      );
    },
  );
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key, this.message});
  final String? message;
  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  String? error;
  Future<void> login() async {
    setState(() { busy = true; error = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email.text.trim(), password: password.text);
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message ?? 'Unable to sign in.');
    } catch (_) {
      setState(() => error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
  @override
  void dispose() { email.dispose(); password.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430),
      child: Card(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Icon(Icons.medical_services_rounded, size: 52, color: Color(0xFF1769E0)),
          const SizedBox(height: 12),
          Text('MedLife Admin', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Sign in to manage your store', textAlign: TextAlign.center),
          const SizedBox(height: 26),
          TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline))),
          const SizedBox(height: 14),
          TextField(controller: password, obscureText: true, onSubmitted: (_) => login(), decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline))),
          if (widget.message != null || error != null) ...[
            const SizedBox(height: 12),
            Text(error ?? widget.message!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 20),
          FilledButton(onPressed: busy ? null : login, child: Padding(padding: const EdgeInsets.all(13), child: Text(busy ? 'Signing in…' : 'Sign In'))),
        ]),
      )),
    )),
  );
}

const _nav = [
  ('Dashboard', Icons.dashboard_rounded),
  ('Orders', Icons.shopping_bag_outlined),
  ('Products', Icons.inventory_2_outlined),
  ('Inventory', Icons.warehouse_outlined),
  ('Customers', Icons.people_outline),
  ('Categories', Icons.category_outlined),
  ('Marketing', Icons.campaign_outlined),
  ('Analytics', Icons.query_stats),
  ('Reports', Icons.assessment_outlined),
  ('Staff & Permissions', Icons.admin_panel_settings_outlined),
  ('Notifications', Icons.notifications_none),
  ('AI Assistant', Icons.auto_awesome),
  ('System Settings', Icons.settings_outlined),
  ('Activity Log', Icons.history),
  ('Backup & Restore', Icons.backup_outlined),
];

class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.onThemeToggle});
  final VoidCallback onThemeToggle;
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int selected = 0;
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    return Scaffold(
      drawer: wide ? null : Drawer(child: _sidebar()),
      body: Row(children: [
        if (wide) SizedBox(width: 248, child: _sidebar()),
        Expanded(child: Column(children: [
          _topbar(wide),
          Expanded(child: selected == 0 ? const DashboardPage() : AdminModulePage(index: selected)),
        ])),
      ]),
    );
  }
  Widget _sidebar() => Container(
    color: const Color(0xFF101B3D),
    child: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(padding: EdgeInsets.fromLTRB(22, 24, 16, 28), child: Row(children: [
        Icon(Icons.favorite, color: Color(0xFF38BDF8), size: 32),
        SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('MedLife', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          Text('ADMIN PANEL', style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 2)),
        ]),
      ])),
      Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 10), children: [
        for (var i = 0; i < _nav.length; i++)
          Padding(padding: const EdgeInsets.only(bottom: 4), child: ListTile(
            selected: selected == i,
            selectedTileColor: const Color(0xFF1769E0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: Icon(_nav[i].$2, color: Colors.white),
            title: Text(_nav[i].$1, style: const TextStyle(color: Colors.white, fontSize: 13)),
            onTap: () => setState(() => selected = i),
          )),
      ])),
      ListTile(leading: const Icon(Icons.logout, color: Colors.white70), title: const Text('Sign Out', style: TextStyle(color: Colors.white)), onTap: () => FirebaseAuth.instance.signOut()),
      const SizedBox(height: 10),
    ])),
  );
  Widget _topbar(bool wide) => Container(
    height: 76, padding: const EdgeInsets.symmetric(horizontal: 24),
    decoration: BoxDecoration(color: Theme.of(context).cardColor, border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: .2)))),
    child: Row(children: [
      if (!wide) Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer())),
      Expanded(child: TextField(decoration: const InputDecoration(hintText: 'Search anything…  (Ctrl + K)', prefixIcon: Icon(Icons.search), isDense: true))),
      const SizedBox(width: 14),
      IconButton(onPressed: widget.onThemeToggle, icon: const Icon(Icons.dark_mode_outlined)),
      IconButton(onPressed: () => setState(() => selected = 10), icon: const Icon(Icons.notifications_none)),
      const SizedBox(width: 8),
      const CircleAvatar(backgroundColor: Color(0xFF1769E0), child: Icon(Icons.person, color: Colors.white)),
      if (wide) const Padding(padding: EdgeInsets.only(left: 10), child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Administrator', style: TextStyle(fontWeight: FontWeight.w700)),
        Text('Super Admin', style: TextStyle(fontSize: 11, color: Colors.grey)),
      ])),
    ]),
  );
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final columns = constraints.maxWidth > 1100 ? 4 : constraints.maxWidth > 650 ? 2 : 1;
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Welcome back!', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      const Text("Here's what's happening with your MedLife store today."),
      const SizedBox(height: 22),
      GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: columns, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 2.5, children: [
        _MetricCard(title: 'Total Orders', collection: 'orders', icon: Icons.shopping_bag, color: const Color(0xFF1687F8)),
        _MetricCard(title: 'Total Products', collection: 'Products', icon: Icons.inventory_2, color: const Color(0xFFF2A51A)),
        _MetricCard(title: 'Total Customers', collection: 'users', icon: Icons.people, color: const Color(0xFF8955E8)),
        _MetricCard(title: 'Categories', collection: 'categories', icon: Icons.category, color: const Color(0xFF16B98A)),
      ]),
      const SizedBox(height: 20),
      if (constraints.maxWidth > 850)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Expanded(flex: 3, child: _SalesCard()),
          SizedBox(width: 16),
          Expanded(flex: 2, child: _RecentOrdersCard()),
        ])
      else ...[
        const _SalesCard(),
        const SizedBox(height: 16),
        const _RecentOrdersCard(),
      ],
      const SizedBox(height: 18),
      const _AssistantTeaser(),
    ]));
  });
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.collection, required this.icon, required this.color});
  final String title, collection;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
    Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color)),
    const SizedBox(width: 13),
    Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 5),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection(collection).snapshots(),
        builder: (context, snapshot) => Text(snapshot.hasError ? '—' : snapshot.hasData ? snapshot.data!.size.toString() : '…', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      ),
    ])),
  ])));
}

class _SalesCard extends StatelessWidget {
  const _SalesCard();
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Revenue Analytics', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
    const SizedBox(height: 18),
    SizedBox(height: 210, child: LineChart(LineChartData(
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [LineChartBarData(isCurved: true, color: const Color(0xFF2589F5), barWidth: 4, belowBarData: BarAreaData(show: true, color: const Color(0xFF2589F5).withValues(alpha: .12)), spots: const [FlSpot(0, 2), FlSpot(1, 4), FlSpot(2, 3), FlSpot(3, 6), FlSpot(4, 5), FlSpot(5, 8), FlSpot(6, 7)])],
    ))),
    const Text('Connect verified order totals and timestamps to enable period-based revenue calculations.', style: TextStyle(fontSize: 12, color: Colors.grey)),
  ])));
}

class _RecentOrdersCard extends StatelessWidget {
  const _RecentOrdersCard();
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Recent Orders', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
    const SizedBox(height: 12),
    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('orders').orderBy('orderedAt', descending: true).limit(5).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('Unable to load orders. Check Firestore access and the createdAt field.');
        if (!snapshot.hasData) return const LinearProgressIndicator();
        if (snapshot.data!.docs.isEmpty) return const Text('No orders found.');
        return Column(children: snapshot.data!.docs.map((doc) {
          final data = doc.data();
          return ListTile(contentPadding: EdgeInsets.zero, leading: const CircleAvatar(child: Icon(Icons.receipt_long)), title: Text('#${doc.id}', maxLines: 1), subtitle: Text('${data['status'] ?? 'Unknown'} • EGP ${data['total'] ?? '—'}'), trailing: const Icon(Icons.chevron_right));
        }).toList());
      },
    ),
  ])));
}

class _AssistantTeaser extends StatelessWidget {
  const _AssistantTeaser();
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [
    const CircleAvatar(backgroundColor: Color(0xFF6C55E8), child: Icon(Icons.auto_awesome, color: Colors.white)),
    const SizedBox(width: 14),
    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('MedLife AI Assistant', style: TextStyle(fontWeight: FontWeight.w800)),
      Text('Ask for store insights from authorized MedLife data. Secure AI integration is being prepared.', style: TextStyle(fontSize: 12, color: Colors.grey)),
    ])),
    OutlinedButton(onPressed: () {}, child: const Text('Open assistant')),
  ])));
}

class ModulePlaceholder extends StatelessWidget {
  const ModulePlaceholder({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Card(child: Padding(padding: const EdgeInsets.all(36), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.construction_outlined, size: 42, color: Color(0xFF1769E0)),
    const SizedBox(height: 12),
    Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
    const SizedBox(height: 8),
    const Text('This module is planned and will be implemented in the next development milestones.', textAlign: TextAlign.center),
  ])))));
}
