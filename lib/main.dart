import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CKPool Stats',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.orange,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      home: const HomePage(),
    );
  }
}

/// ---------- 本地存储配置 ----------
class BtcConfigStore {
  static const _key = 'btc_addresses';

  static Future<List<String>> load() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getStringList(_key) ?? [];
  }

  static Future<List<String>> add(String address) async {
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_key) ?? [];
    list.remove(address);
    list.insert(0, address);
    await sp.setStringList(_key, list);
    return list;
  }

  static Future<List<String>> remove(String address) async {
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_key) ?? [];
    list.remove(address);
    await sp.setStringList(_key, list);
    return list;
  }

  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_key);
  }
}

/// ---------- 首页（输入与保存） ----------
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  List<String> _saved = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final list = await BtcConfigStore.load();
    if (!mounted) return;
    setState(() {
      _saved = list;
      if (_controller.text.isEmpty && list.isNotEmpty) {
        _controller.text = list.first;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isValidBtcAddress(String addr) {
    if (addr.isEmpty) return false;
    final bech32 = RegExp(r'^bc1[a-z0-9]{25,62}$');
    final legacy = RegExp(r'^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$');
    return bech32.hasMatch(addr) || legacy.hasMatch(addr);
  }

  Future<void> _saveCurrent() async {
    final addr = _controller.text.trim();
    if (!_isValidBtcAddress(addr)) {
      setState(() => _error = '请输入有效的比特币主网地址');
      return;
    }
    final list = await BtcConfigStore.add(addr);
    setState(() {
      _saved = list;
      _error = null;
    });
    _toast('已保存：${_short(addr)}');
  }

  Future<void> _deleteAddress(String addr) async {
    final list = await BtcConfigStore.remove(addr);
    setState(() {
      _saved = list;
      if (_controller.text.trim() == addr) {
        _controller.clear();
      }
    });
    _toast('已删除：${_short(addr)}');
  }

  void _search([String? addrOverride]) {
    final addr = (addrOverride ?? _controller.text).trim();
    if (!_isValidBtcAddress(addr)) {
      setState(() => _error = '请输入有效的比特币主网地址');
      return;
    }
    setState(() {
      _error = null;
      _controller.text = addr;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StatsPage(address: addr)),
    );
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );
  }

  String _short(String addr) {
    if (addr.length <= 16) return addr;
    return '${addr.substring(0, 8)}...${addr.substring(addr.length - 6)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CKPool 查询'),
        actions: [
          if (_saved.isNotEmpty)
            IconButton(
              tooltip: '清空保存',
              icon: const Icon(Icons.delete_sweep),
              onPressed: () async {
                await BtcConfigStore.clear();
                setState(() => _saved = []);
                _toast('已清空保存的地址');
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '输入 BTC 地址',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            minLines: 1,
            maxLines: 2,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: 'bc1q...',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.currency_bitcoin),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _controller.clear(),
              ),
              errorText: _error,
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _search(),
                  icon: const Icon(Icons.search),
                  label: const Text('查询'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saveCurrent,
                  icon: const Icon(Icons.save),
                  label: const Text('保存'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_saved.isNotEmpty) ...[
            Row(
              children: [
                const Text(
                  '已保存的地址',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text('${_saved.length} 个',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            ..._saved.map(
              (addr) => Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orangeAccent,
                    child: Icon(Icons.account_balance_wallet,
                        color: Colors.white),
                  ),
                  title: Text(_short(addr),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(addr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12)),
                  onTap: () => _search(addr),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.orange),
                        onPressed: () => _search(addr),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                        onPressed: () => _deleteAddress(addr),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('暂无保存的地址，输入后点击"保存"即可。',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey)),
            ),
        ],
      ),
    );
  }
}

/// ---------- 统计页面（原生 API，美化版） ----------
class StatsPage extends StatefulWidget {
  final String address;

  const StatsPage({super.key, required this.address});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchStats();
  }

  Future<Map<String, dynamic>> _fetchStats() async {
    final url =
        Uri.parse('https://raw.stats.ckpool.org/users/${widget.address}');

    final res = await http.get(
      url,
      headers: {
        'User-Agent': 'Flutter-CKPool-Stats/1.0',
        'Accept': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}\n${res.body}');
    }

    final decoded = jsonDecode(res.body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw Exception('返回格式不是 JSON 对象：${res.body}');
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _fetchStats();
    });
    await _future;
  }

  /// 将 Unix 时间戳转为可读格式
  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '-';
    if (ts is int) {
      final date = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return ts.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CKPool 统计'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      '加载失败：\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _refresh,
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!;
          final workers = data['worker'] as List<dynamic>? ?? [];

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ---- 地址卡片 ----
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.currency_bitcoin,
                            color: Theme.of(context).colorScheme.primary,
                            size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('当前查询地址',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 4),
                              SelectableText(
                                widget.address,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ---- 账户总览 ----
                const Text(
                  '账户总览',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _statBox('算力 1m', data['hashrate1m']),
                            _statBox('算力 5m', data['hashrate5m']),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _statBox('算力 1hr', data['hashrate1hr']),
                            _statBox('算力 1d', data['hashrate1d']),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _statBox('算力 7d', data['hashrate7d']),
                            _statBox('Best Share', data['bestshare'],
                                isHighlight: true),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _statBox('Shares', data['shares']),
                            _statBox('Workers', data['workers']),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _statBox('Best Ever', data['bestever']),
                            _statBox('Last Share',
                                _formatTimestamp(data['lastshare'])),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _statBox('Authorised',
                                _formatTimestamp(data['authorised'])),
                            const Spacer(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ---- 矿工列表 ----
                if (workers.isNotEmpty) ...[
                  Row(
                    children: [
                      const Text(
                        '矿工列表',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${workers.length} 台',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...workers.map((w) => _buildWorkerCard(w)),
                ] else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text('没有在线矿工',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 账户总览用的小格子
  Widget _statBox(String label, dynamic value, {bool isHighlight = false}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isHighlight
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4)
              : Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(
              value?.toString() ?? '-',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isHighlight
                    ? Theme.of(context).colorScheme.primary
                    : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// 单个矿工卡片
  Widget _buildWorkerCard(Map<String, dynamic> w) {
    final name = w['workername'] ?? w['name'] ?? '未知矿工';
    final shares = w['shares']?.toString() ?? '0';
    final bestShare = w['bestshare']?.toString() ?? '0';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(Icons.memory,
              color: Theme.of(context).colorScheme.onPrimaryContainer),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              _buildBadge('Shares: $shares', Colors.blueGrey),
              const SizedBox(width: 8),
              _buildBadge('Best: $bestShare', Colors.orange, isBold: true),
            ],
          ),
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _statBox('算力 1m', w['hashrate1m']),
              _statBox('算力 5m', w['hashrate5m']),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _statBox('算力 1hr', w['hashrate1hr']),
              _statBox('算力 1d', w['hashrate1d']),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _statBox('算力 7d', w['hashrate7d']),
              _statBox('Best Share', w['bestshare'], isHighlight: true),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _statBox('Last Share', _formatTimestamp(w['lastshare'])),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  /// 小徽章（Shares / Best Share）
  Widget _buildBadge(String text, Color color, {bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}