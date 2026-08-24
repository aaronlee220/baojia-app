import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/shipping_calculator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  List<Product> products = [];
  Product? selectedProduct;
  bool isLoading = true;
  String goodsType = 'normal';
  bool showSettings = false;
  
  final postcodeCtrl = TextEditingController();
  final boxesCtrl = TextEditingController();
  final itemsPerBoxCtrl = TextEditingController();
  final inlandFeeCtrl = TextEditingController();
  final profitRateCtrl = TextEditingController();
  final exchangeRateCtrl = TextEditingController(text: '1.64');
  final purchasePriceCtrl = TextEditingController();
  final lengthCtrl = TextEditingController();
  final widthCtrl = TextEditingController();
  final heightCtrl = TextEditingController();
  final weightCtrl = TextEditingController();

  Map<String, dynamic>? airResult, seaBulkResult, seaParcelResult;

  @override
  void initState() { super.initState(); loadProducts(); }

  Future<void> loadProducts() async {
    setState(() => isLoading = true);
    products = await ApiService.getProducts();
    setState(() => isLoading = false);
  }

  void selectProduct(Product p) {
    setState(() {
      selectedProduct = p;
      purchasePriceCtrl.text = p.price.toString();
      itemsPerBoxCtrl.text = p.box.toString();
      inlandFeeCtrl.text = p.inland.toString();
      profitRateCtrl.text = p.profit.toString();
      lengthCtrl.text = p.length.toString();
      widthCtrl.text = p.width.toString();
      heightCtrl.text = p.height.toString();
      weightCtrl.text = p.weight.toString();
      _currentTab = 0;
    });
  }

  void calculate() {
    final l = double.tryParse(lengthCtrl.text) ?? 0;
    final w = double.tryParse(widthCtrl.text) ?? 0;
    final h = double.tryParse(heightCtrl.text) ?? 0;
    final weight = double.tryParse(weightCtrl.text) ?? 0;
    final boxes = int.tryParse(boxesCtrl.text) ?? 1;
    final postcode = int.tryParse(postcodeCtrl.text) ?? 0;
    final itemsPerBox = int.tryParse(itemsPerBoxCtrl.text) ?? 1;
    final inlandFee = double.tryParse(inlandFeeCtrl.text) ?? 0;
    final profitRate = double.tryParse(profitRateCtrl.text) ?? 25;
    final exchangeRate = double.tryParse(exchangeRateCtrl.text) ?? 1.64;
    final purchasePrice = double.tryParse(purchasePriceCtrl.text) ?? 0;
    final totalItems = boxes * itemsPerBox;
    final inlandPerItem = inlandFee / itemsPerBox;

    if (l <= 0 || w <= 0 || h <= 0 || weight <= 0 || postcode <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写完整尺寸、重量和邮编')));
      return;
    }

    final air = ShippingCalculator.calculateAir(length: l, width: w, height: h, weight: weight, boxes: boxes, postcode: postcode, goodsType: goodsType);
    final seaBulk = ShippingCalculator.calculateSeaBulk(length: l, width: w, height: h, weight: weight, boxes: boxes, postcode: postcode, goodsType: goodsType);
    final seaParcel = ShippingCalculator.calculateSeaParcel(length: l, width: w, height: h, weight: weight, boxes: boxes, postcode: postcode, goodsType: goodsType);

    final airPerItem = double.parse(air['totalCost']) / totalItems;
    final seaBulkPerItem = (double.parse(seaBulk['totalCost']) + double.parse(seaBulk['deliveryFee'])) / totalItems;
    final seaParcelPerItem = double.parse(seaParcel['finalCost']) / totalItems;

    final pm = 1 + (profitRate / 100);
    final airQ = (purchasePrice + inlandPerItem + airPerItem) * pm;
    final seaBulkQ = (purchasePrice + inlandPerItem + seaBulkPerItem) * pm;
    final seaParcelQ = (purchasePrice + inlandPerItem + seaParcelPerItem) * pm;

    setState(() {
      airResult = {...air, 'quoteRMB': airQ.toStringAsFixed(2), 'quoteMYR': (airQ / exchangeRate).toStringAsFixed(2), 'perItem': airPerItem.toStringAsFixed(2)};
      seaBulkResult = {...seaBulk, 'quoteRMB': seaBulkQ.toStringAsFixed(2), 'quoteMYR': (seaBulkQ / exchangeRate).toStringAsFixed(2), 'perItem': seaBulkPerItem.toStringAsFixed(2)};
      seaParcelResult = {...seaParcel, 'quoteRMB': seaParcelQ.toStringAsFixed(2), 'quoteMYR': (seaParcelQ / exchangeRate).toStringAsFixed(2), 'perItem': seaParcelPerItem.toStringAsFixed(2)};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentTab, children: [_buildQuotationPage(), _buildBulkPage(), _buildProductPage()]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (i) => setState(() => _currentTab = i),
        selectedItemColor: const Color(0xFF007AFF),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: '报价'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: '大货'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: '产品'),
        ],
      ),
    );
  }

  Widget _buildQuotationPage() {
    return Scaffold(
      appBar: AppBar(title: const Text('运费精算专家'), backgroundColor: const Color(0xFF007AFF), foregroundColor: Colors.white, centerTitle: true),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        _card(Column(children: [
          GestureDetector(onTap: () => setState(() => showSettings = !showSettings), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('⚙️ 运费单价设置', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)), Icon(showSettings ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down)])),
          if (showSettings) ...[const Divider(), _rateGrid()],
        ])),
        const SizedBox(height: 12),
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('📦 产品信息', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const Divider(),
          _formGrid(),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: calculate, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007AFF), padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('计算运费', style: TextStyle(fontSize: 16, color: Colors.white)))),
        ])),
        if (airResult != null) ...[
          const SizedBox(height: 12),
          _resultCard('🔥 商品报价（含利润）', true),
          const SizedBox(height: 12),
          _resultCard('📦 最低报价（不含利润）', false),
          const SizedBox(height: 12),
          _perItemCard(),
          const SizedBox(height: 12),
          _freightDetailCard(),
        ],
        const SizedBox(height: 12),
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('📋 计费规则', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const Divider(),
          _rule('空运DDP：', '体积重=长×宽×高/6000，分半抛规则，最低11kg'),
          _rule('海运大货：', '体积=长×宽×高/1,000,000，重货按500kg/CBM'),
          _rule('海运小包：', '体积重=长×宽×高/6000，取实重与体积重最大值'),
          _rule('偏远派送费：', '西马东海岸+80/CBM，东马各城市有附加费'),
        ])),
      ])),
    );
  }

  Widget _buildBulkPage() => Scaffold(appBar: AppBar(title: const Text('大货报价'), backgroundColor: const Color(0xFF007AFF), foregroundColor: Colors.white, centerTitle: true), body: const Center(child: Text('大货报价功能开发中...')));

  Widget _buildProductPage() {
    return Scaffold(
      appBar: AppBar(title: const Text('产品管理'), backgroundColor: const Color(0xFF007AFF), foregroundColor: Colors.white, centerTitle: true, actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: loadProducts)]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(decoration: InputDecoration(hintText: '搜索产品名称/编号...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.grey[100]))),
        Expanded(child: isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: products.length, itemBuilder: (ctx, i) {
          final p = products[i];
          return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
            leading: p.image.isNotEmpty ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(p.image, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image))) : Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.inventory_2)),
            title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${p.code} · ¥${p.price} · ${p.box}个/箱'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => selectProduct(p),
          ));
        })),
      ]),
    );
  }

  Widget _card(Widget child) => Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: child);

  Widget _rateGrid() => Wrap(spacing: 8, runSpacing: 8, children: [
    _rateItem('空运普货', '20.5'), _rateItem('空运带电', '29'), _rateItem('空运敏感', '30'),
    _rateItem('西马内坡普货', '650'), _rateItem('西马内坡敏感', '670'),
    _rateItem('西马外坡普货', '670'), _rateItem('西马外坡敏感', '690'),
    _rateItem('东马普货', '980'), _rateItem('东马敏感', '1080'),
    _rateItem('小包西马', '5.5'), _rateItem('小包东马', '10'), _rateItem('汇率', '1.64'),
  ]);

  Widget _rateItem(String label, String val) => SizedBox(width: 150, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)), const SizedBox(height: 2), TextField(controller: TextEditingController(text: val), decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), isDense: true), keyboardType: TextInputType.number, style: const TextStyle(fontSize: 13))]));

  Widget _formGrid() => Wrap(spacing: 8, runSpacing: 8, children: [
    _formItem('产品编号', selectedProduct?.code ?? '', null),
    _formItem('产品名称', selectedProduct?.name ?? '', null),
    _formItem('采购价格(RMB/件)', '', purchasePriceCtrl),
    _formItem('内陆费(RMB/箱)', '', inlandFeeCtrl),
    _formItem('装箱数(个/箱)', '', itemsPerBoxCtrl),
    _formItem('利润率(%)', '', profitRateCtrl),
    _formItem('长(cm)', '', lengthCtrl), _formItem('宽(cm)', '', widthCtrl), _formItem('高(cm)', '', heightCtrl),
    _formItem('单件重量(kg)', '', weightCtrl), _formItem('箱数', '', boxesCtrl), _formItem('目的地邮编', '', postcodeCtrl),
    SizedBox(width: double.infinity, child: DropdownButtonFormField<String>(value: goodsType, decoration: const InputDecoration(labelText: '货物类型', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: 'normal', child: Text('普货')), DropdownMenuItem(value: 'battery', child: Text('带电')), DropdownMenuItem(value: 'sensitive', child: Text('敏感货'))], onChanged: (v) => setState(() => goodsType = v!))),
  ]);

  Widget _formItem(String label, String value, TextEditingController? ctrl) => SizedBox(width: 160, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)), const SizedBox(height: 2), ctrl != null ? TextField(controller: ctrl, decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), isDense: true), keyboardType: TextInputType.number, style: const TextStyle(fontSize: 13)) : Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10), decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(4)), child: Text(value.isEmpty ? '-' : value, style: const TextStyle(fontSize: 13)))]));

  Widget _resultCard(String title, bool isQuote) {
    final er = double.tryParse(exchangeRateCtrl.text) ?? 1.64;
    final boxes = int.tryParse(boxesCtrl.text) ?? 1;
    final ipb = int.tryParse(itemsPerBoxCtrl.text) ?? 1;
    final pp = double.tryParse(purchasePriceCtrl.text) ?? 0;
    final inland = double.tryParse(inlandFeeCtrl.text) ?? 0;
    final pr = double.tryParse(profitRateCtrl.text) ?? 25;
    final pm = 1 + pr / 100;
    final ipi = inland / ipb;

    String getQuote(Map<String, dynamic> r, String perItemKey) {
      final pi = double.parse(r[perItemKey]);
      final q = (pp + ipi + pi) * pm;
      return isQuote ? q.toStringAsFixed(2) : (pp + ipi + pi).toStringAsFixed(2);
    }

    final airQ = getQuote(airResult!, 'perItem');
    final seaQ = getQuote(seaBulkResult!, 'perItem');
    final parcelQ = getQuote(seaParcelResult!, 'perItem');

    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)), TextButton.icon(onPressed: () {}, icon: const Icon(Icons.copy, size: 16), label: const Text('复制'))]),
      const Divider(),
      _priceRow('✈️ 空运DDP', (double.parse(airQ) / er).toStringAsFixed(2), airQ),
      const SizedBox(height: 8),
      _priceRow('🚢 海运大货', (double.parse(seaQ) / er).toStringAsFixed(2), seaQ),
      const SizedBox(height: 8),
      _priceRow('📦 海运小包', (double.parse(parcelQ) / er).toStringAsFixed(2), parcelQ),
    ]));
  }

  Widget _perItemCard() => _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('🎯 单件商品运费', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
    const Divider(),
    _priceRow('✈️ 空运DDP', '', '¥${airResult!['perItem']}'),
    const SizedBox(height: 8),
    _priceRow('🚢 海运大货', '', '¥${seaBulkResult!['perItem']}'),
    const SizedBox(height: 8),
    _priceRow('📦 海运小包', '', '¥${seaParcelResult!['perItem']}'),
  ]));

  Widget _freightDetailCard() => _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('📊 运费计算结果', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
    const Divider(),
    _detail('✈️ 空运DDP', airResult!),
    const Divider(),
    _detail('🚢 海运大货', seaBulkResult!),
    const Divider(),
    _detail('📦 海运小包', seaParcelResult!),
  ]));

  Widget _priceRow(String label, String myr, String rmb) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(label, style: const TextStyle(fontSize: 14)),
    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      if (myr.isNotEmpty) Text('RM$myr', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
      Text('¥$rmb', style: TextStyle(fontSize: myr.isNotEmpty ? 13 : 18, fontWeight: myr.isEmpty ? FontWeight.bold : FontWeight.normal, color: myr.isEmpty ? const Color(0xFFDC2626) : Colors.grey)),
    ]),
  ]);

  Widget _detail(String label, Map<String, dynamic> r) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    const SizedBox(height: 4),
    if (r.containsKey('chargeWeight')) Text('计费重: ${r['chargeWeight']}KG', style: const TextStyle(fontSize: 12, color: Colors.grey)),
    if (r.containsKey('finalVolume')) Text('计费体积: ${r['finalVolume']}CBM', style: const TextStyle(fontSize: 12, color: Colors.grey)),
    if (r.containsKey('unitPrice')) Text('单价: ¥${r['unitPrice']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
    if (r['isHeavy'] == true) const Text('⚠️ 重货', style: TextStyle(fontSize: 12, color: Color(0xFFD97706))),
    if (r['note'] != null && r['note'].toString().isNotEmpty) Text(r['note'], style: const TextStyle(fontSize: 12, color: Color(0xFFD97706))),
    const SizedBox(height: 4),
    Text('整批: RM${r['quoteMYR']} / ¥${r['quoteRMB']}', style: const TextStyle(fontWeight: FontWeight.w600)),
  ]);

  Widget _rule(String title, String desc) => Padding(padding: const EdgeInsets.only(bottom: 4), child: RichText(text: TextSpan(style: const TextStyle(fontSize: 12, color: Colors.black87), children: [TextSpan(text: title, style: const TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: desc)])));
}
