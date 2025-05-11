import 'package:flutter/material.dart';
import 'package:hms_pro/home_page.dart';
import 'package:hms_pro/widgets/custom_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class Transaction {
  final String id;
  final String date;
  final double credit;
  final double paid;
  final double balance;
  final String modeOfPayment;

  Transaction({
    required this.id,
    required this.date,
    required this.credit,
    required this.paid,
    required this.balance,
    required this.modeOfPayment,
  });
}

class FirstPage extends StatefulWidget {
  const FirstPage({super.key});

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  double eggRate = 1.0;
  double targetRate = 4.7;
  double neccEggRate = 4.7; // New variable for necc_eggrate
  String? _profileImageUrl;
  bool _isLoadingProfileImage = true;
  DateTime? _lastUpdated;
  double creditBalance = 0.0;
  double crateQuantity = 0.0;
  List<Transaction> transactions = [];
  String? _userRole;
  final List<String> images = [
    'assets/eggs1.png',
    'assets/eggs2.png',
    'assets/eggs3.png',
  ];
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
    _loadUserRoleAndData();
    _setupRealtimeSubscription();
  }

  Future<void> _loadUserRoleAndData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('No authenticated user found');
        return;
      }

      var userResponse = await _supabase
          .from('users')
          .select('role, profile_image')
          .eq('id', userId)
          .maybeSingle();

      if (userResponse == null || userResponse['role'] == null) {
        userResponse = await _supabase
            .from('wholesale_users')
            .select('role, profile_image')
            .eq('id', userId)
            .maybeSingle();
      }

      if (userResponse == null || userResponse['role'] == null) {
        throw Exception('User role not found');
      }

      setState(() {
        _userRole = userResponse?['role'] as String?;
        if (userResponse != null && userResponse['profile_image'] != null) {
          final imagePath = userResponse['profile_image'];
          if (imagePath.startsWith('userprofile/')) {
            _profileImageUrl = _supabase.storage
                .from('userprofile')
                .getPublicUrl(imagePath.replaceFirst('userprofile/', ''));
          } else {
            _profileImageUrl = imagePath;
          }
        }
        _isLoadingProfileImage = false;
      });

      await Future.wait([
        _loadEggRate(),
        _loadNeccEggRate(), // Fetch necc_eggrate for small container
        _loadCreditData(),
        if (_userRole == 'customer') _loadCrateQuantity(),
      ]);
    } catch (e) {
      print('Error loading user role or data: $e');
      setState(() {
        _isLoadingProfileImage = false;
        targetRate = 4.7;
        neccEggRate = 4.7; // Default for necc_eggrate
        creditBalance = 0.0;
        crateQuantity = 0.0;
        transactions = [];
      });
    }
  }

  Future<void> _loadCrateQuantity() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('No authenticated user found for crates');
        return;
      }

      final response = await _supabase
          .from('crates')
          .select('quantity')
          .eq('user_id', userId)
          .maybeSingle();

      setState(() {
        crateQuantity = response != null && response['quantity'] != null
            ? response['quantity'].toDouble()
            : 0.0;
      });
    } catch (e) {
      print('Error fetching crate quantity: $e');
      setState(() {
        crateQuantity = 0.0;
      });
    }
  }

  Future<void> _loadCreditData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('No authenticated user found');
        return;
      }

      final transactionsTable =
          _userRole == 'wholesale' ? 'wholesale_transaction' : 'transactions';

      final transactionsResponse = await _supabase
          .from(transactionsTable)
          .select('id, date, credit, paid, balance, mode_of_payment')
          .eq('user_id', userId)
          .order('date', ascending: false);

      setState(() {
        double totalCredit = transactionsResponse.fold(0.0, (sum, t) {
          return sum + (t['credit']?.toDouble() ?? 0.0);
        });
        double totalPaid = transactionsResponse.fold(0.0, (sum, t) {
          return sum + (t['paid']?.toDouble() ?? 0.0);
        });
        creditBalance = totalCredit - totalPaid;

        transactions = transactionsResponse.map<Transaction>((t) {
          String dateStr =
              t['date']?.toString() ?? DateTime.now().toIso8601String();
          DateTime parsedDate;
          try {
            parsedDate = DateTime.parse(dateStr);
          } catch (e) {
            try {
              parsedDate = DateFormat('MMM dd').parse(dateStr);
              parsedDate = DateTime(
                  DateTime.now().year, parsedDate.month, parsedDate.day);
            } catch (e) {
              print('Error parsing date $dateStr: $e');
              parsedDate = DateTime.now();
            }
          }
          return Transaction(
            id: t['id'].toString(),
            date: DateFormat('MMM dd, h:mm a').format(parsedDate),
            credit: t['credit']?.toDouble() ?? 0.0,
            paid: t['paid']?.toDouble() ?? 0.0,
            balance: t['balance']?.toDouble() ?? 0.0,
            modeOfPayment: t['mode_of_payment']?.toString() ?? 'N/A',
          );
        }).toList();
      });
    } catch (e) {
      print('Error fetching credit data: $e');
      setState(() {
        creditBalance = 0.0;
        transactions = [];
      });
    }
  }

  void _setupRealtimeSubscription() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      print('No userId for real-time subscription');
      return;
    }

    final transactionsTable =
        _userRole == 'wholesale' ? 'wholesale_transaction' : 'transactions';

    _supabase
        .channel('transactions_user_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: transactionsTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            print('Real-time transaction update: $payload');
            _loadCreditData();
          },
        )
        .subscribe();
  }

  Future<void> _loadEggRate() async {
    try {
      final eggRateTable =
          _userRole == 'wholesale' ? 'wholesale_eggrate' : 'egg_rates';

      final response = await _supabase
          .from(eggRateTable)
          .select('rate, updated_at')
          .eq('id', 1)
          .maybeSingle();

      if (response != null && response['rate'] != null) {
        setState(() {
          targetRate = response['rate'].toDouble();
          _lastUpdated = response['updated_at'] != null
              ? DateTime.parse(response['updated_at'].toString())
              : null;
        });
      } else {
        setState(() {
          targetRate = 4.7;
          _lastUpdated = null;
        });
      }
    } catch (e) {
      print('Error fetching egg rate: $e');
      setState(() {
        targetRate = 4.7;
        _lastUpdated = null;
      });
    }
    animateRate();
  }

  Future<void> _loadNeccEggRate() async {
    try {
      final response = await _supabase
          .from('necc_eggrate')
          .select('rate')
          .eq('id', 1)
          .maybeSingle();

      if (response != null && response['rate'] != null) {
        setState(() {
          neccEggRate = response['rate'].toDouble();
        });
      } else {
        setState(() {
          neccEggRate = 4.7; // Default fallback rate
        });
      }
    } catch (e) {
      print('Error fetching necc egg rate: $e');
      setState(() {
        neccEggRate = 4.7; // Default fallback rate
      });
    }
  }

  void _startAutoScroll() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 3));
      if (_pageController.hasClients && mounted) {
        setState(() {
          _currentPage = (_currentPage + 1) % images.length;
        });
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
      return true;
    });
  }

  void animateRate() async {
    for (double i = 1.0; i <= targetRate; i += 0.01) {
      await Future.delayed(const Duration(milliseconds: 2));
      if (mounted) {
        setState(() {
          eggRate = double.parse(i.toStringAsFixed(2));
        });
      }
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';
    final formatter = DateFormat('d MMMM, h:mm a');
    return formatter.format(dateTime);
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      _loadEggRate(),
      _loadNeccEggRate(), // Refresh necc_eggrate for small container
      _loadCreditData(),
      if (_userRole == 'customer') _loadCrateQuantity(),
    ]);
  }

  Widget _buildDotsIndicator() {
    final size = MediaQuery.of(context).size;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(images.length, (index) {
        return GestureDetector(
          onTap: () {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
            setState(() => _currentPage = index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.symmetric(horizontal: size.width * 0.01),
            width:
                _currentPage == index ? size.width * 0.03 : size.width * 0.02,
            height: size.height * 0.01,
            decoration: BoxDecoration(
              color: _currentPage == index
                  ? const Color.fromARGB(255, 0, 79, 188)
                  : const Color(0xFF757575),
              borderRadius: BorderRadius.circular(size.width * 0.01),
            ),
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    _supabase.channel('transactions_user_*').unsubscribe();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: CustomBackground(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: const Color.fromARGB(255, 30, 0, 255),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(size.width * 0.04),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) => CreditDetailsPage(
                                creditBalance: creditBalance,
                                transactions: transactions,
                                userRole: _userRole ?? 'customer',
                              ),
                              transitionsBuilder: (_, animation, __, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Card(
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(size.width * 0.03),
                              ),
                              elevation: 6,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: size.width * 0.04,
                                    vertical: size.height * 0.01),
                                child: Text(
                                  'Credit: ₹${creditBalance.toStringAsFixed(2)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF0288D1),
                                        fontSize: size.width * 0.04,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            if (_userRole == 'customer')
                              SizedBox(height: size.height * 0.01),
                            if (_userRole == 'customer')
                              Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(size.width * 0.03),
                                ),
                                elevation: 6,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: size.width * 0.04,
                                      vertical: size.height * 0.01),
                                  child: Text(
                                    'Crates: ${crateQuantity.toStringAsFixed(0)} = ${crateQuantity * 35}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF0288D1),
                                          fontSize: size.width * 0.04,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) =>
                                  const HomePage(initialIndex: 3),
                              transitionsBuilder: (_, animation, __, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: size.width * 0.06,
                          backgroundColor: const Color(0xFFFFFFFF),
                          backgroundImage: _profileImageUrl != null &&
                                  !_isLoadingProfileImage
                              ? NetworkImage(_profileImageUrl!)
                              : null,
                          child:
                              _profileImageUrl == null || _isLoadingProfileImage
                                  ? Icon(
                                      Icons.person,
                                      color: const Color(0xFF757575),
                                      size: size.width * 0.06,
                                    )
                                  : null,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: size.height * 0.25,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: size.width * 0.04),
                        child: Hero(
                          tag: 'carousel-image-$index',
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(size.width * 0.04),
                            child: Image.asset(
                              images[index],
                              fit: BoxFit.cover,
                              width: size.width * 0.9,
                              height: size.height * 0.25,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: size.height * 0.015),
                _buildDotsIndicator(),
                SizedBox(height: size.height * 0.03),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _userRole == 'wholesale'
                            ? 'Wholesale Egg Rate In Bengaluru'
                            : 'NECC Egg Rate In Bengaluru',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.headlineSmall!.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: size.width * 0.08,
                                  color: const Color(0xFF0288D1),
                                ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: size.width * 0.02),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(size.width * 0.02),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.03,
                            vertical: size.height * 0.02),
                        child: Text(
                          '₹${neccEggRate.toStringAsFixed(2)}', // Use neccEggRate
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color.fromARGB(255, 0, 134, 224),
                                fontSize: size.width * 0.04,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: size.height * 0.01),
                AnimatedScale(
                  scale: eggRate > 1.0 ? 1.0 : 0.9,
                  duration: const Duration(milliseconds: 200),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(size.width * 0.03),
                    ),
                    elevation: 6,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.06,
                          vertical: size.height * 0.02),
                      child: Text(
                        '₹${eggRate.toStringAsFixed(2)}',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color.fromARGB(255, 0, 134, 224),
                              fontSize: size.width * 0.12,
                            ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.01),
                Text(
                  'Last updated: ${_formatDateTime(_lastUpdated)}',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: size.width * 0.035,
                        color: const Color(0xFF757575),
                      ),
                ),
                SizedBox(height: size.height * 0.03),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: "At "),
                        TextSpan(
                          text: _userRole == 'wholesale'
                              ? "HMS EGG DISTRIBUTORS - Wholesale"
                              : "HMS EGG DISTRIBUTORS",
                          style: const TextStyle(
                              fontSize: 17,
                              color: Color.fromARGB(255, 255, 12, 12),
                              fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(
                          text:
                              ", we take pride in delivering the finest quality eggs to your shop.....",
                        ),
                      ],
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            fontSize: size.width * 0.05,
                            color: const Color(0xFF757575),
                          ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: size.height * 0.04),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CreditDetailsPage extends StatefulWidget {
  final double creditBalance;
  final List<Transaction> transactions;
  final String userRole;

  const CreditDetailsPage({
    super.key,
    required this.creditBalance,
    required this.transactions,
    required this.userRole,
  });

  @override
  State<CreditDetailsPage> createState() => _CreditDetailsPageState();
}

class _CreditDetailsPageState extends State<CreditDetailsPage> {
  double creditBalance = 0.0;
  List<Transaction> transactions = [];
  final _supabase = Supabase.instance.client;
  bool isLoading = false;
  int currentPage = 1;
  static const int itemsPerPage = 5;
  String sortBy = 'date';
  bool sortAscending = true;
  String? searchQuery;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    creditBalance = widget.creditBalance;
    transactions = widget.transactions;
    _loadCreditData();
    _setupRealtimeSubscription();
  }

  void _setupRealtimeSubscription() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      print('No userId for real-time subscription in CreditDetailsPage');
      return;
    }

    final transactionsTable = widget.userRole == 'wholesale'
        ? 'wholesale_transaction'
        : 'transactions';

    _supabase
        .channel('credit_details_user_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: transactionsTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            print(
                'Real-time transaction update for ${widget.userRole}: $payload');
            _loadCreditData();
          },
        )
        .subscribe();
  }

  Future<void> _loadCreditData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('No authenticated user found');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      final transactionsTable = widget.userRole == 'wholesale'
          ? 'wholesale_transaction'
          : 'transactions';

      final transactionsResponse = await _supabase
          .from(transactionsTable)
          .select('id, date, credit, paid, balance, mode_of_payment')
          .eq('user_id', userId)
          .order('date', ascending: false);

      setState(() {
        double totalCredit = transactionsResponse.fold(0.0, (sum, t) {
          return sum + (t['credit']?.toDouble() ?? 0.0);
        });
        double totalPaid = transactionsResponse.fold(0.0, (sum, t) {
          return sum + (t['paid']?.toDouble() ?? 0.0);
        });
        creditBalance = totalCredit - totalPaid;

        transactions = transactionsResponse.map<Transaction>((t) {
          String dateStr =
              t['date']?.toString() ?? DateTime.now().toIso8601String();
          DateTime parsedDate;
          try {
            parsedDate = DateTime.parse(dateStr);
          } catch (e) {
            try {
              parsedDate = DateFormat('MMM dd').parse(dateStr);
              parsedDate = DateTime(
                  DateTime.now().year, parsedDate.month, parsedDate.day);
            } catch (e) {
              print('Error parsing date $dateStr: $e');
              parsedDate = DateTime.now();
            }
          }
          return Transaction(
            id: t['id'].toString(),
            date: DateFormat('MMM dd, h:mm a').format(parsedDate),
            credit: t['credit']?.toDouble() ?? 0.0,
            paid: t['paid']?.toDouble() ?? 0.0,
            balance: t['balance']?.toDouble() ?? 0.0,
            modeOfPayment: t['mode_of_payment']?.toString() ?? 'N/A',
          );
        }).toList();

        _sortTransactions();
        _filterTransactions();
      });
    } catch (e) {
      print('Error fetching transactions for ${widget.userRole}: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load transactions: $e')),
      );
      setState(() {
        transactions = [];
        creditBalance = 0.0;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _sortTransactions() {
    transactions.sort((a, b) {
      switch (sortBy) {
        case 'date':
          return sortAscending
              ? a.date.compareTo(b.date)
              : b.date.compareTo(a.date);
        case 'credit':
          return sortAscending
              ? a.credit.compareTo(b.credit)
              : b.credit.compareTo(a.credit);
        case 'paid':
          return sortAscending
              ? a.paid.compareTo(b.paid)
              : b.paid.compareTo(a.paid);
        case 'balance':
          return sortAscending
              ? a.balance.compareTo(b.balance)
              : b.balance.compareTo(a.balance);
        case 'modeOfPayment':
          return sortAscending
              ? a.modeOfPayment.compareTo(b.modeOfPayment)
              : b.modeOfPayment.compareTo(a.modeOfPayment);
        default:
          return 0;
      }
    });
  }

  void _filterTransactions() {
    if (searchQuery == null || searchQuery!.isEmpty) return;
    transactions = transactions.where((t) {
      final query = searchQuery!.toLowerCase();
      return t.id.toLowerCase().contains(query) ||
          t.date.toLowerCase().contains(query) ||
          t.modeOfPayment.toLowerCase().contains(query) ||
          t.credit.toString().contains(query) ||
          t.paid.toString().contains(query) ||
          t.balance.toString().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _supabase.channel('credit_details_user_*').unsubscribe();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final paginatedTransactions = transactions
        .skip((currentPage - 1) * itemsPerPage)
        .take(itemsPerPage)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.userRole == 'wholesale'
              ? 'Wholesale Credit Details'
              : 'Credit Details',
          style: TextStyle(
            fontSize: size.width * 0.05,
            color: const Color(0xFFFFFFFF),
          ),
        ),
        backgroundColor: const Color(0xFF0288D1),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              size: size.width * 0.06,
              color: const Color(0xFFFFFFFF),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    'Sort By',
                    style: TextStyle(
                      fontSize: size.width * 0.045,
                      color: const Color(0xFF0288D1),
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButton<String>(
                          value: sortBy,
                          isExpanded: true,
                          items: [
                            'date',
                            'credit',
                            'paid',
                            'balance',
                            'modeOfPayment'
                          ]
                              .map((String value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value.capitalize(),
                                      style: TextStyle(
                                        fontSize: size.width * 0.04,
                                        color: const Color(0xFF757575),
                                      ),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              sortBy = value!;
                              _sortTransactions();
                            });
                            Navigator.pop(context);
                          },
                        ),
                        SwitchListTile(
                          title: Text(
                            'Ascending',
                            style: TextStyle(
                              fontSize: size.width * 0.04,
                              color: const Color(0xFF757575),
                            ),
                          ),
                          value: sortAscending,
                          onChanged: (value) {
                            setState(() {
                              sortAscending = value;
                              _sortTransactions();
                            });
                            Navigator.pop(context);
                          },
                          activeColor: const Color(0xFF0288D1),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: size.width * 0.04,
                          color: const Color(0xFF757575),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Apply',
                        style: TextStyle(
                          fontSize: size.width * 0.04,
                          color: const Color(0xFF0288D1),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCreditData,
        color: const Color(0xFF0288D1),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(size.width * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(size.width * 0.03),
                  ),
                  elevation: 6,
                  child: Padding(
                    padding: EdgeInsets.all(size.width * 0.04),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                widget.userRole == 'wholesale'
                                    ? 'Wholesale Credit Balance:'
                                    : 'Credit Balance:',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge!
                                    .copyWith(
                                      fontSize: size.width * 0.045,
                                      color: const Color(0xFF0288D1),
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '₹${creditBalance.toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge!
                                  .copyWith(
                                    fontSize: size.width * 0.045,
                                    color: creditBalance > 0
                                        ? const Color(0xFFD32F2F)
                                        : const Color(0xFF388E3C),
                                  ),
                            ),
                          ],
                        ),
                        SizedBox(height: size.height * 0.01),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Credit:',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(
                                    fontSize: size.width * 0.04,
                                    color: const Color(0xFF757575),
                                  ),
                            ),
                            Text(
                              '₹${transactions.fold(0.0, (sum, t) => sum + t.credit).toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(
                                    fontSize: size.width * 0.04,
                                    color: const Color(0xFF388E3C),
                                  ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Paid:',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(
                                    fontSize: size.width * 0.04,
                                    color: const Color(0xFF757575),
                                  ),
                            ),
                            Text(
                              '₹${transactions.fold(0.0, (sum, t) => sum + t.paid).toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(
                                    fontSize: size.width * 0.04,
                                    color: const Color(0xFF0288D1),
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.02),
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: 'Search (Date, Mode, Amount)',
                    labelStyle: TextStyle(
                      fontSize: size.width * 0.04,
                      color: const Color(0xFF757575),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(size.width * 0.03),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.clear,
                        size: size.width * 0.06,
                        color: const Color(0xFF757575),
                      ),
                      onPressed: () {
                        setState(() {
                          searchController.clear();
                          searchQuery = null;
                          _loadCreditData();
                        });
                      },
                    ),
                  ),
                  style: TextStyle(
                    fontSize: size.width * 0.04,
                    color: const Color(0xFF757575),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                      _filterTransactions();
                    });
                  },
                ),
                SizedBox(height: size.height * 0.02),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(size.width * 0.03),
                  ),
                  elevation: 6,
                  child: Padding(
                    padding: EdgeInsets.all(size.width * 0.04),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            widget.userRole == 'wholesale'
                                ? 'Make a Wholesale Payment'
                                : 'Make a Payment',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge!
                                .copyWith(
                                  fontSize: size.width * 0.045,
                                  color: const Color(0xFF0288D1),
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: creditBalance > 0
                              ? () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Payment methods are yet to be added'),
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0288D1),
                            foregroundColor: const Color(0xFFFFFFFF),
                            padding: EdgeInsets.symmetric(
                                horizontal: size.width * 0.04,
                                vertical: size.height * 0.015),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(size.width * 0.03),
                            ),
                          ),
                          child: Text(
                            'Pay Now',
                            style: TextStyle(fontSize: size.width * 0.04),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.02),
                Text(
                  widget.userRole == 'wholesale'
                      ? 'Wholesale Transaction History'
                      : 'Customer Transaction History',
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        fontSize: size.width * 0.06,
                        color: const Color(0xFF0288D1),
                      ),
                ),
                SizedBox(height: size.height * 0.01),
                if (isLoading)
                  Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFF0288D1)),
                    ),
                  )
                else
                  Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: paginatedTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = paginatedTransactions[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(size.width * 0.03),
                            ),
                            elevation: 6,
                            child: Padding(
                              padding: EdgeInsets.all(size.width * 0.04),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          transaction.modeOfPayment,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge!
                                              .copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF0288D1),
                                                fontSize: size.width * 0.04,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: size.height * 0.01),
                                  Text(
                                    'Date: ${transaction.date}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          fontSize: size.width * 0.035,
                                          color: const Color(0xFF757575),
                                        ),
                                  ),
                                  Text(
                                    'Credit: ₹${transaction.credit.toStringAsFixed(2)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          fontSize: size.width * 0.035,
                                          color: const Color(0xFF388E3C),
                                        ),
                                  ),
                                  Text(
                                    'Paid: ₹${transaction.paid.toStringAsFixed(2)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          fontSize: size.width * 0.035,
                                          color: const Color(0xFF0288D1),
                                        ),
                                  ),
                                  Text(
                                    'Balance: ₹${transaction.balance.toStringAsFixed(2)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          fontSize: size.width * 0.035,
                                          color: transaction.balance > 0
                                              ? const Color(0xFFD32F2F)
                                              : const Color(0xFF388E3C),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: size.height * 0.02),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.chevron_left,
                              size: size.width * 0.06,
                              color: currentPage > 1
                                  ? const Color(0xFF0288D1)
                                  : const Color(0xFF757575),
                            ),
                            onPressed: currentPage > 1
                                ? () {
                                    setState(() {
                                      currentPage--;
                                    });
                                  }
                                : null,
                          ),
                          Text(
                            'Page $currentPage of ${((transactions.length - 1) ~/ itemsPerPage) + 1}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontSize: size.width * 0.035,
                                  color: const Color(0xFF757575),
                                ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.chevron_right,
                              size: size.width * 0.06,
                              color: currentPage <
                                      ((transactions.length - 1) ~/
                                              itemsPerPage) +
                                          1
                                  ? const Color(0xFF0288D1)
                                  : const Color(0xFF757575),
                            ),
                            onPressed: currentPage <
                                    ((transactions.length - 1) ~/
                                            itemsPerPage) +
                                        1
                                ? () {
                                    setState(() {
                                      currentPage++;
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                SizedBox(height: size.height * 0.04),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
