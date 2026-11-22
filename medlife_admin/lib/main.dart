import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'admin_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The emulator suite is started with --project demo-medlife. The Firebase
  // app must use that same project ID or callable Functions / Firestore will
  // target a different project namespace than the running emulators.
  const useFirebaseEmulators =
      bool.fromEnvironment('USE_FIREBASE_EMULATORS');
  final configuredOptions = DefaultFirebaseOptions.currentPlatform;
  final firebaseOptions = useFirebaseEmulators
      ? FirebaseOptions(
          apiKey: configuredOptions.apiKey,
          appId: configuredOptions.appId,
          messagingSenderId: configuredOptions.messagingSenderId,
          projectId: 'demo-medlife',
          authDomain: configuredOptions.authDomain,
          databaseURL: configuredOptions.databaseURL,
          storageBucket: configuredOptions.storageBucket,
          measurementId: configuredOptions.measurementId,
          trackingId: configuredOptions.trackingId,
          deepLinkURLScheme: configuredOptions.deepLinkURLScheme,
          androidClientId: configuredOptions.androidClientId,
          iosClientId: configuredOptions.iosClientId,
          iosBundleId: configuredOptions.iosBundleId,
          appGroupId: configuredOptions.appGroupId,
        )
      : configuredOptions;

  await Firebase.initializeApp(options: firebaseOptions);

  // Production project configuration remains unchanged when emulator mode is off.
  if (useFirebaseEmulators) {
    FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
    FirebaseFunctions.instance.useFunctionsEmulator('127.0.0.1', 5001);
  }

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
      final user = auth.data;
      if (user == null) return const AdminLoginPage();

      return FutureBuilder<IdTokenResult>(
        future: user.getIdTokenResult(true),
        builder: (context, tokenSnapshot) {
          if (tokenSnapshot.connectionState == ConnectionState.waiting) {
            return const _Loading();
          }
          if (tokenSnapshot.hasError || !tokenSnapshot.hasData) {
            return const _AccessDenied(
              message: 'Unable to verify this account permissions. Please sign in again.',
            );
          }

          final claims = tokenSnapshot.data!.claims ?? const <String, dynamic>{};
          final isSuperAdmin = claims['medlifeSuperAdmin'] == true;
          final isActiveStaff = claims['medlifeRole'] == 'staff' &&
              claims['medlifeStaffActive'] == true;
          final rawPermissions = claims['medlifePermissions'];
          final permissions = rawPermissions is List
              ? rawPermissions.whereType<String>().toSet()
              : <String>{};

          if (!isSuperAdmin && !isActiveStaff) {
            return const _AccessDenied(
              message: 'This account is not an active MedLife administrator.',
            );
          }

          return AdminShell(
            onThemeToggle: onThemeToggle,
            isSuperAdmin: isSuperAdmin,
            permissions: permissions,
          );
        },
      );
    },
  );
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 44, color: Colors.redAccent),
                const SizedBox(height: 14),
                const Text(
                  'Administrator access required',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
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
  const AdminShell({
    super.key,
    required this.onThemeToggle,
    required this.isSuperAdmin,
    required this.permissions,
  });

  final VoidCallback onThemeToggle;
  final bool isSuperAdmin;
  final Set<String> permissions;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int selected = 0;

  static const _requiredPermission = <int, String>{
    0: 'dashboard.view',
    1: 'orders.view',
    2: 'products.view',
    3: 'inventory.view',
    4: 'customers.view',
    5: 'categories.manage',
    6: 'marketing.manage',
    7: 'reports_finance.view',
    8: 'reports_finance.view',
    9: 'staff.manage',
    10: 'notifications.manage',
    12: 'settings.manage',
    13: 'activity_log.view',
    14: 'backup.manage',
  };

  List<int> get _visibleSections => List<int>.generate(_nav.length, (i) => i)
      .where((i) => widget.isSuperAdmin ||
          widget.permissions.contains(_requiredPermission[i]))
      .toList();

  @override
  Widget build(BuildContext context) {
    final visibleSections = _visibleSections;
    final activeSection = visibleSections.contains(selected)
        ? selected
        : (visibleSections.isEmpty ? -1 : visibleSections.first);
    final wide = MediaQuery.sizeOf(context).width >= 1000;

    return Scaffold(
      drawer: wide ? null : Drawer(child: _sidebar(visibleSections, activeSection, closeDrawer: true)),
      body: Row(children: [
        if (wide) SizedBox(width: 248, child: _sidebar(visibleSections, activeSection, closeDrawer: false)),
        Expanded(child: Column(children: [
          _topbar(wide, visibleSections),
          Expanded(
            child: activeSection == -1
                ? const _NoSectionAccess()
                : activeSection == 0
                    ? DashboardPage(
                        isSuperAdmin: widget.isSuperAdmin,
                        permissions: widget.permissions,
                      )
                    : AdminModulePage(index: activeSection),
          ),
        ])),
      ]),
    );
  }

  Widget _sidebar(List<int> visibleSections, int activeSection, {required bool closeDrawer}) => Container(
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
        for (final i in visibleSections)
          Padding(padding: const EdgeInsets.only(bottom: 4), child: ListTile(
            selected: activeSection == i,
            selectedTileColor: const Color(0xFF1769E0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: Icon(_nav[i].$2, color: Colors.white),
            title: Text(_nav[i].$1, style: const TextStyle(color: Colors.white, fontSize: 13)),
            onTap: () {
              setState(() => selected = i);
              if (closeDrawer) Navigator.pop(context);
            },
          )),
      ])),
      ListTile(
        leading: const Icon(Icons.logout, color: Colors.white70),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        onTap: () => FirebaseAuth.instance.signOut(),
      ),
      const SizedBox(height: 10),
    ])),
  );

  Widget _topbar(bool wide, List<int> visibleSections) => Container(
    height: 76,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: .2))),
    ),
    child: Row(children: [
      if (!wide) Builder(builder: (context) => IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => Scaffold.of(context).openDrawer(),
      )),
      Expanded(child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search anything…  (Ctrl + K)',
          prefixIcon: Icon(Icons.search),
          isDense: true,
        ),
      )),
      const SizedBox(width: 14),
      IconButton(onPressed: widget.onThemeToggle, icon: const Icon(Icons.dark_mode_outlined)),
      if (visibleSections.contains(10))
        IconButton(onPressed: () => setState(() => selected = 10), icon: const Icon(Icons.notifications_none)),
      const SizedBox(width: 8),
      const CircleAvatar(backgroundColor: Color(0xFF1769E0), child: Icon(Icons.person, color: Colors.white)),
      if (wide) Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.isSuperAdmin ? 'Administrator' : 'Staff Member', style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(widget.isSuperAdmin ? 'Super Admin' : 'Staff', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
      ),
    ]),
  );
}

class _NoSectionAccess extends StatelessWidget {
  const _NoSectionAccess();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'Your account is active, but no dashboard sections have been assigned yet. Contact the Super Admin.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.isSuperAdmin,
    required this.permissions,
  });

  final bool isSuperAdmin;
  final Set<String> permissions;

  bool _can(String permission) =>
      isSuperAdmin || permissions.contains(permission);

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final columns = constraints.maxWidth > 1100 ? 4 : constraints.maxWidth > 650 ? 2 : 1;
    final metrics = <Widget>[
      if (_can('orders.view'))
        const _MetricCard(title: 'Total Orders', collection: 'orders', icon: Icons.shopping_bag, color: Color(0xFF1687F8)),
      if (_can('products.view'))
        const _MetricCard(title: 'Total Products', collection: 'Products', icon: Icons.inventory_2, color: Color(0xFFF2A51A)),
      if (_can('customers.view'))
        const _MetricCard(title: 'Total Customers', collection: 'users', icon: Icons.people, color: Color(0xFF8955E8)),
      if (_can('categories.manage'))
        const _MetricCard(title: 'Categories', collection: 'categories', icon: Icons.category, color: Color(0xFF16B98A)),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome back!', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text("Here's what's happening with your MedLife store today."),
          const SizedBox(height: 22),
          if (metrics.isNotEmpty)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 2.5,
              children: metrics,
            ),
          if (metrics.isEmpty)
            const Text('Your dashboard access is active. Additional data cards appear when the Super Admin grants the relevant module permissions.'),
          if (_can('reports_finance.view') || _can('orders.view')) ...[
            const SizedBox(height: 20),
            if (constraints.maxWidth > 850)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_can('reports_finance.view'))
                    const Expanded(flex: 3, child: _SalesCard()),
                  if (_can('reports_finance.view') && _can('orders.view'))
                    const SizedBox(width: 16),
                  if (_can('orders.view'))
                    const Expanded(flex: 2, child: _RecentOrdersCard()),
                ],
              )
            else ...[
              if (_can('reports_finance.view')) const _SalesCard(),
              if (_can('reports_finance.view') && _can('orders.view'))
                const SizedBox(height: 16),
              if (_can('orders.view')) const _RecentOrdersCard(),
            ],
          ],
          if (isSuperAdmin) ...[
            const SizedBox(height: 18),
            const _AssistantTeaser(),
          ],
        ],
      ),
    );
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
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Analytics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          const SizedBox(
            height: 210,
            child: Center(
              child: Text(
                'Revenue analytics will be available after verified order totals and timestamps are connected.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    ),
  );
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
        if (snapshot.hasError) {
          debugPrint('RECENT ORDERS FIRESTORE ERROR: ${snapshot.error}');
          return Text('Unable to load orders: ${snapshot.error}');
        }
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
