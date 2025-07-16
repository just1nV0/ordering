import '../api_helpers/sqlite/read_sqlite.dart';
import '../models/menu_item.dart';

class MenuService {
  final DBReader _dbReader = DBReader();

  Future<List<MenuItem>> loadMenuItems() async {
    try {
      final List<Map<String, dynamic>> items = await _dbReader.readTable(
        tableName: 'itemnames',
        columns: ['ctr', 'itemname', 'uom', 'sold_count'],
        orderBy: 'sold_count DESC',
      );
      
      final List<Map<String, dynamic>> priceList = await _dbReader.readTable(
        tableName: 'item_price',
        columns: ['ctr', 'prev_price', 'curr_price'],
      );
      
      final Map<String, double> priceMap = {
        for (var item in priceList)
          item['ctr'].toString(): item['curr_price'] != 'TBA'
              ? double.tryParse(item['curr_price'].toString()) ?? 
                double.tryParse(item['prev_price'].toString()) ?? 0.00
              : double.tryParse(item['prev_price'].toString()) ?? 0.00
      };

      return items.map((item) {
        final String ctr = item['ctr']?.toString() ?? '';
        return MenuItem.fromMap(item, priceMap[ctr] ?? 0.00);
      }).toList();
    } catch (e) {
      throw Exception('Error loading menu items: $e');
    }
  }
}