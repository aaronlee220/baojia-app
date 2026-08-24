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
  List<Product> products = [];
  Product? selectedProduct;
  bool isLoading = true;
  String goodsType = 'normal';
  final postcodeCtrl = TextEditingController();
  final boxesCtrl = TextEditingController(text: '1');
  final itemsPerBoxCtrl = TextEditingController(text: '1');
  final inlandFeeCtrl = TextEditingController(text: '0');
  final profitRateCtrl = TextEditingController(text: '25');
  final exchangeRateCtrl = TextEditingController(text: '1.64');
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
      itemsPerBoxCtrl.text = p.box.toString();
      inlandFeeCtrl.text = p.inland.toString();
      profitRateCtrl.text = p.profit.toString();
    });
  }

  void calculate() {
    if (selectedProduct == null || postcodeCtrl.text.isEmpty) return;
    final p = selectedProduct!;
    final postcode = int.tryParse(postcodeCtrl.text) ?? 0;
    final boxes = int.tryParse(boxesCtrl.text) ?? 1;
    final itemsPerBox = int.tryParse(itemsPerBoxCtrl.text) ?? 1;
    final inlandFee = double.tryParse(inlandFeeCtrl.text) ?? 0;
    final profitRate = double.tryParse(profitRateCtrl.text) ?? 25;
    final exchangeRate = double.tryParse(exchangeRateCtrl.text) ?? 1.64;
    final totalItems = boxes * itemsPerBox;
    final inlandPerItem = inlandFee / itemsPerBox;

    final air = ShippingCalculator.calculateAir(length: p.length, width: p.width, height: p.height, weight: p.weight, boxes: boxes, postcode: postcode, goodsType: goodsType);
    final seaBulk = ShippingCalculator.calculateSeaBulk(length: p.length, width: p.width, height: p.height, weight: p.weight, boxes: boxes, postcode: postcode, goodsType: goodsType);
    final seaParcel = ShippingCalculator.calculateSeaParcel(length: p.length, width: p.width, height: p.height, weight: p.weight, boxes: boxes, postcode: postcode, goodsType: goodsType);

    final pm = 1 + (profitRate / 100);
    final airPerItem = double.parse(air['totalCost']) / totalItems;
    final seaBulkPerItem = (double.parse(seaBulk['totalCost']) + double.parse(seaBulk['deliveryFee'])) / totalItems;
    final seaParcelPerItem = double.parse(seaParcel['finalCost']) / totalItems;

    setState(() {
      airResult = {...air, 'perItem': airPerItem.toStringAsFixed(2), 'quoteMYR': ((p.price + inlandPerItem + airPerItem) * pm / exchangeRate).toStringAsFixed(2), 'quoteRMB': ((p.price + inlandPerItem + airPerItem) * pm).toStringAsFixed(2)};
      seaBulkResult = {...seaBulk, 'perItem': seaBulkPerItem.toStringAsFixed(2), 'quoteMYR': ((p.price + inlandPerItem + seaBulkPerItem) * pm / exchangeRate).toStringAsFixed(2), 'quoteRMB': ((p.price + inlandPerItem + seaBulkPerItem) * pm).toStringAsFixed(2)};
      seaParcelResult = {...seaParcel, 'perItem': seaParcelPerItem.toStringAsFixed(2), 'quoteMYR': ((p.price + inlandPerItem + seaParcelPerItem) * pm / exchangeRate).toStringAsFixed(2), 'quoteRMB': ((p.price + inlandPerItem + seaParcelPerItem) * pm).toStringAsFixed(2)};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('报价工具'), backgroundColor: const Color(0xFF1E40AF)),
      body: Row(children: [
        SizedBox(width: 280, child: Column(children: [
          Padding(padding: const EdgeInsets.all(8), child: TextField(decoration: const InputDecoration(hintText: '搜索...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()), onChanged: (v) => setState(() {}))),
          Expanded(child: isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(itemCount: products.length, itemBuilder: (ctx, i) {
            final p = products[i];
            return ListTile(selected: selectedProduct?.code == p.code, leading: const Icon(Icons.inventory_2), title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis), subtitle: Text('${p.code} | ¥${p.price}'), onTap: () => selectProduct(p));
          })),
        ])),
        const VerticalDivider(),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (selectedProduct != null) Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('📦 ${selectedProduct!.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('编号: ${selectedProduct!.code}'),
            Text('尺寸: ${selectedProduct!.length}×${selectedProduct!.width}×${selectedProduct!.height}cm'),
          ]))),
          const SizedBox(height: 16),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('⚙️ 计算参数', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: postcodeCtrl, decoration: const InputDecoration(labelText: '邮编', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: DropdownButtonFormField<String>(value: goodsType, decoration: const InputDecoration(labelText: '货物类型', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: 'normal', child: Text('普货')), DropdownMenuItem(value: 'battery', child: Text('带电')), DropdownMenuItem(value: 'sensitive', child: Text('敏感'))], onChanged: (v) => setState(() => goodsType = v!))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: boxesCtrl, decoration: const InputDecoration(labelText: '箱数', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: itemsPerBoxCtrl, decoration: const InputDecoration(labelText: '个/箱', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: inlandFeeCtrl, decoration: const InputDecoration(labelText: '内陆费', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: profitRateCtrl, decoration: const InputDecoration(labelText: '利润率(%)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: exchangeRateCtrl, decoration: const InputDecoration(labelText: '汇率', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: calculate, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E40AF), padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('计算运费', style: TextStyle(fontSize: 16, color: Colors.white)))),
          ]))),
          const SizedBox(height: 16),
          if (airResult != null) Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('📊 运费计算结果', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildResult('✈️ 空运DDP', airResult!),
            _buildResult('🚢 海运大货', seaBulkResult!),
            _buildResult('📦 海运小包', seaParcelResult!),
          ]))),
        ]))),
      ]),
    );
  }

  Widget _buildResult(String title, Map<String, dynamic> r) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      const Divider(),
      Text('计费重/体积: ${r['chargeWeight'] ?? r['finalVolume'] ?? '-'}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      Text('单价: ¥${r['unitPrice']}/KG', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      if (r['deliveryFee'] != '0') Text('派件费: ¥${r['deliveryFee']}', style: const TextStyle(fontSize: 12, color: Color(0xFFD97706))),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('RM${r['quoteMYR']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
        Text('¥${r['quoteRMB']}', style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
      ]),
    ])));
  }
}
