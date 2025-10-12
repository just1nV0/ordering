import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/menu_item.dart';
import '../models/cart_item.dart';
import '../theme/app_color_palette.dart';
import '../api_helpers/google_sheets/crud/read_sheets.dart';

class OrderItem {
  final String id;
  final List<CartItem> items;
  final DateTime orderDate;
  final double total;
  final OrderStatus status;
  final double due;
  final String? notes;

  OrderItem({
    required this.id,
    required this.items,
    required this.orderDate,
    required this.total,
    required this.status,
    required this.due,
    this.notes,
  });
}

enum OrderStatus { pending, confirmed, preparing, ready, completed, cancelled }

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready for Pickup';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color getColor(AppColorPalette theme) {
    switch (this) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return theme.primary;
      case OrderStatus.ready:
        return theme.success;
      case OrderStatus.completed:
        return theme.success;
      case OrderStatus.cancelled:
        return theme.error;
    }
  }
}

class OrderHistoryScreen extends StatefulWidget {
  final AppColorPalette theme;

  const OrderHistoryScreen({Key? key, required this.theme}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _userName = '';
  String _userPhone = '';
  String _customerId = '';

  final Map<String, List<OrderStatus>> _categories = {
    'Pending': [OrderStatus.pending],
    'Confirmed': [
      OrderStatus.confirmed,
      OrderStatus.preparing,
      OrderStatus.ready,
    ],
    'Recent': [OrderStatus.completed, OrderStatus.cancelled],
  };

  List<OrderItem> orders = [];
  bool isLoading = true;
  final SheetsReader _sheetsReader = SheetsReader();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadUserInfo();
    _loadOrderHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userInfoString = prefs.getString('user_info');
    if (userInfoString != null) {
      final userInfo = jsonDecode(userInfoString);
      setState(() {
        _userName = userInfo['username'] ?? '';
        _userPhone = userInfo['phone'] ?? '';
        if (userInfo.containsKey('ctr') && userInfo['ctr'] != null) {
          _customerId = userInfo['ctr'].toString();
        }
      });
    }
  }

  Future<void> _loadOrderHistory() async {
    setState(() => isLoading = true);

    try {
      // Fetch orders from Google Sheets
      final fetchedOrders = await _fetchOrdersFromSheet();
      
      setState(() {
        orders = fetchedOrders
          ..sort((a, b) => b.orderDate.compareTo(a.orderDate));
        isLoading = false;
      });
    } catch (e) {
      print('Error loading orders: $e');
      // Fallback to mock data if fetch fails
      setState(() {
        orders = _generateMockOrders()
          ..sort((a, b) => b.orderDate.compareTo(a.orderDate));
        isLoading = false;
      });
    }
  }

  Future<List<OrderItem>> _fetchOrdersFromSheet() async {
    if (_customerId.isEmpty) {
      print('No customer ID available');
      return [];
    }

    try {
      // Get today's date in the format used in the sheet (MM/dd/yyyy)
      final today = DateTime.now();
      final dateFormatter = DateFormat('M/d/yyyy');
      final todayDateString = dateFormatter.format(today);

      // Fetch all data from the orders sheet
      final ordersData = await _sheetsReader.readSheetAsMapList(
        sheetName: 'orders',
        range: 'A:I',
        firstRowIsHeader: true,
      );

      if (ordersData == null || ordersData.isEmpty) {
        print('No orders data found in sheet');
        return [];
      }
      // Filter orders by customer_id and today's date
      final filteredOrders = ordersData.where((order) {
        final orderCustomerId = order['customer_id']?.toString() ?? '';
        if (orderCustomerId != _customerId) return false;

        final orderDateString = order['date']?.toString() ?? '';
        if (orderDateString.isEmpty) return false;

        try {
          final datePart = orderDateString.split(' ').first;
          final orderDate = DateFormat('M/d/yyyy').parse(datePart);
          final orderDateFormatted = dateFormatter.format(orderDate);
          return orderDateFormatted == todayDateString;
        } catch (e) {
          return false;
        }
      }).toList();

      // Group orders by order ID (ctr)
      Map<String, List<Map<String, dynamic>>> groupedOrders = {};
      for (var order in filteredOrders) {
        final orderId = order['ctr']?.toString() ?? '';
        if (!groupedOrders.containsKey(orderId)) {
          groupedOrders[orderId] = [];
        }
        groupedOrders[orderId]!.add(order);
      }

      // Convert to OrderItem objects
      List<OrderItem> orderItems = [];
      for (var entry in groupedOrders.entries) {
        final orderId = entry.key;
        final orderLines = entry.value;

        if (orderLines.isEmpty) continue;

        // Parse order date with time
        DateTime orderDate;
        try {
          final dateTimeString = orderLines.first['date']?.toString() ?? '';
          orderDate = DateFormat('M/d/yyyy HH:mm').parse(dateTimeString);
        } catch (e) {
          orderDate = DateTime.now();
        }

        // Parse order status
        final statusString = orderLines.first['order_status']?.toString().toLowerCase() ?? 'pending';
        OrderStatus status = OrderStatus.pending;
        if (statusString.contains('confirm')) {
          status = OrderStatus.confirmed;
        } else if (statusString.contains('prepar')) {
          status = OrderStatus.preparing;
        } else if (statusString.contains('ready')) {
          status = OrderStatus.ready;
        } else if (statusString.contains('complet')) {
          status = OrderStatus.completed;
        } else if (statusString.contains('cancel')) {
          status = OrderStatus.cancelled;
        }

        // Create CartItems from order lines
        List<CartItem> items = [];
        double total = 0.0;

        for (var line in orderLines) {
          final itemName = line['itemname']?.toString() ?? 'Unknown Item';
          final qty = _parseDouble(line['qty']);
          final price = _parseDouble(line['price']);
          final totalPrice = _parseDouble(line['total_price']);

          final menuItem = MenuItem(
            id: line['item_ctr']?.toString() ?? '',
            name: itemName,
            price: price,
            uom: 'serving',
            image: '',
          );

          items.add(CartItem(menuItem: menuItem, quantity: qty.toInt()));
          total += totalPrice;
        }

        // Calculate due amount (pending/confirmed orders have due amount)
        double due = 0.0;
        if (status == OrderStatus.pending || 
            status == OrderStatus.confirmed || 
            status == OrderStatus.preparing || 
            status == OrderStatus.ready) {
          due = total;
        }

        orderItems.add(OrderItem(
          id: orderId,
          items: items,
          orderDate: orderDate,
          total: total,
          status: status,
          due: due,
        ));
      }

      print('Fetched ${orderItems.length} orders for customer $_customerId');
      return orderItems;

    } catch (e) {
      print('Error fetching orders from sheet: $e');
      return [];
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  List<OrderItem> _generateMockOrders() {
    final m1 = MenuItem(
      id: '1',
      name: 'Chicken Adobo',
      price: 150,
      uom: 'serving',
      image: '',
    );
    final m2 = MenuItem(
      id: '2',
      name: 'Pork Sisig',
      price: 180,
      uom: 'serving',
      image: '',
    );
    final m3 = MenuItem(
      id: '3',
      name: 'Iced Tea',
      price: 50,
      uom: 'glass',
      image: '',
    );

    return [
      OrderItem(
        id: 'ORD-001',
        items: [
          CartItem(menuItem: m1, quantity: 2),
          CartItem(menuItem: m3, quantity: 1),
        ],
        orderDate: DateTime.now().subtract(const Duration(hours: 2)),
        total: 350,
        status: OrderStatus.completed,
        due: 0,
      ),
      OrderItem(
        id: 'ORD-002',
        items: [
          CartItem(menuItem: m2, quantity: 1),
          CartItem(menuItem: m3, quantity: 2),
        ],
        orderDate: DateTime.now().subtract(const Duration(days: 1)),
        total: 280,
        status: OrderStatus.completed,
        due: 0,
      ),
      OrderItem(
        id: 'ORD-003',
        items: [
          CartItem(menuItem: m1, quantity: 1),
          CartItem(menuItem: m2, quantity: 1),
        ],
        orderDate: DateTime.now().subtract(const Duration(minutes: 30)),
        total: 330,
        status: OrderStatus.ready,
        due: 330,
      ),
      OrderItem(
        id: 'ORD-005',
        items: [CartItem(menuItem: m1, quantity: 4)],
        orderDate: DateTime.now().subtract(const Duration(minutes: 10)),
        total: 600,
        status: OrderStatus.pending,
        due: 600,
      ),
    ];
  }

  String _formatDate(DateTime date) {
    final d = DateTime.now().difference(date);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays == 1) return 'Yesterday';
    return '${d.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final totalDue = orders.fold<double>(0, (sum, order) => sum + order.due);

    return Scaffold(
      backgroundColor: widget.theme.background,
      body: RefreshIndicator(
        onRefresh: _loadOrderHistory,
        color: widget.theme.primary,
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(color: widget.theme.primary),
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: widget.theme.primary,
                          child: Text(
                            _userName.isNotEmpty
                                ? _userName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: widget.theme.surface,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userName.isNotEmpty ? _userName : 'User',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: widget.theme.textPrimary,
                              ),
                            ),
                            Text(
                              _userPhone.isNotEmpty ? _userPhone : '',
                              style: TextStyle(
                                fontSize: 14,
                                color: widget.theme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  if (totalDue > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: widget.theme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Due',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: widget.theme.textPrimary,
                              ),
                            ),
                            Text(
                              '₱${totalDue.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: widget.theme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),
                  TabBar(
                    controller: _tabController,
                    labelColor: widget.theme.textPrimary,
                    unselectedLabelColor: widget.theme.textSecondary,
                    indicatorColor: widget.theme.primary,
                    tabs: _categories.entries.map((entry) {
                      IconData icon;
                      switch (entry.key) {
                        case 'Pending':
                          icon = Icons.hourglass_empty;
                          break;
                        case 'Confirmed':
                          icon = Icons.check_circle_outline;
                          break;
                        default:
                          icon = Icons.history;
                      }
                      return Tab(icon: Icon(icon), text: entry.key);
                    }).toList(),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.65,
                    child: TabBarView(
                      controller: _tabController,
                      children: _categories.entries.map((entry) {
                        final filtered = orders
                            .where((o) => entry.value.contains(o.status))
                            .toList();
                        if (filtered.isEmpty) {
                          return Center(
                            child: Text(
                              'No ${entry.key.toLowerCase()} orders',
                              style: TextStyle(
                                color: widget.theme.textSecondary,
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => _buildOrderCard(filtered[i]),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildOrderCard(OrderItem order) {
    final c = widget.theme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order ${order.id}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: order.status.getColor(c).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: order.status.getColor(c)),
                    ),
                    child: Text(
                      order.status.displayName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: order.status.getColor(c),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: c.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(order.orderDate),
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 14,
                    color: c.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Text(
                order.items
                    .map((it) => '${it.quantity}x ${it.menuItem.name}')
                    .join(', '),
                style: TextStyle(fontSize: 14, color: c.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total: ₱${order.total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: c.primary,
                        ),
                      ),
                      if (order.due > 0)
                        Text(
                          'Due: ₱${order.due.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: c.error,
                          ),
                        ),
                    ],
                  ),
                  const Icon(Icons.chevron_right, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}