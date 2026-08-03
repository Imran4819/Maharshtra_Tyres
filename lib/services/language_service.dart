import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _prefKey = 'selected_language_code';

  /// ValueNotifier holding current language code ('en' or 'mr')
  static final ValueNotifier<String> currentLanguage = ValueNotifier<String>('en');

  /// Initialize language setting from SharedPreferences
  static Future<void> initLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_prefKey) ?? 'en';
    currentLanguage.value = savedCode;
  }

  /// Change language and persist preference
  static Future<void> setLanguage(String code) async {
    if (code != 'en' && code != 'mr') return;
    currentLanguage.value = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, code);
  }

  /// Translate a string key into selected language
  static String tr(String key) {
    final lang = currentLanguage.value;
    final normalizedKey = key.toLowerCase().trim().replaceAll(' ', '_');
    return _translations[lang]?[normalizedKey] ??
        _translations[lang]?[key] ??
        _translations['en']?[normalizedKey] ??
        _translations['en']?[key] ??
        key;
  }

  static final Map<String, Map<String, String>> _translations = {
    'en': {
      'app_title': 'Maharashtra Tyres',
      'dashboard': 'Dashboard',
      'customers': 'Customers',
      'inventory': 'Inventory',
      'sales': 'Sales',
      'invoices': 'Invoices',
      'reminders': 'Reminders',
      'reports': 'Reports',
      'revenue': 'Revenue',
      'suppliers': 'Suppliers',
      'notifications': 'Notifications',
      'settings': 'Settings',
      'language': 'Language',
      'select_language': 'Select Language',
      'english': 'English',
      'marathi': 'Marathi (मराठी)',
      'good_morning': 'Good Morning',
      'todays_sales': "Today's Sales",
      'todays_orders': "Today's Orders",
      'products': 'Products',
      'recent_sales': 'Recent Sales',
      'low_stock_alert': 'Low Stock Alert',
      'quick_actions': 'Quick Actions',
      'add_customer': 'Add Customer',
      'new_sale': 'New Sale',
      'generate_invoice': 'Generate Invoice',
      'view_all_sales': 'View All Sales',
      'view_inventory': 'View Inventory',
      'left_in_stock': 'Left',
      'logout': 'Logout',
      'profile': 'Profile',
      'dark_mode': 'Dark Mode',
      'app_version': 'App Version',
      'privacy_policy': 'Privacy Policy',
      'help_support': 'Help & Support',

      // Customers
      'customer_list': 'Customer Directory',
      'search_customers': 'Search by name, phone, or email...',
      'phone': 'Phone Number',
      'email': 'Email Address',
      'address': 'Address',
      'vehicle_no': 'Vehicle Number',
      'edit': 'Edit',
      'delete': 'Delete',
      'total_customers': 'Total Customers',
      'no_customers_found': 'No customers found',
      'add_new_customer': 'Add New Customer',
      'edit_customer': 'Edit Customer Details',

      // Inventory
      'inventory_stock': 'Inventory Stock',
      'add_product': 'Add New Product',
      'search_products': 'Search by product name or brand...',
      'product_name': 'Product Name',
      'brand': 'Brand / Company',
      'quantity': 'Quantity',
      'price': 'Price (₹)',
      'stock_status': 'Stock Status',
      'in_stock': 'In Stock',
      'out_of_stock': 'Out of Stock',
      'low_stock': 'Low Stock',

      // Invoices
      'all_invoices': 'All Invoices',
      'create_invoice': 'Create Invoice',
      'search_invoices': 'Search by invoice no or customer...',
      'invoice_number': 'Invoice No.',
      'customer_name': 'Customer Name',
      'amount': 'Amount',
      'date': 'Date',
      'due_date': 'Due Date',
      'status': 'Status',
      'paid': 'Paid',
      'pending': 'Pending',
      'download_pdf': 'Download PDF',
      'share': 'Share',
      'customer_details': 'Customer Details',
      'invoice_details': 'Invoice Details',
      'invoice_items': 'Invoice Items',
      'item_description': 'Item Description',
      'subtotal': 'Subtotal',
      'tax': 'Tax',
      'discount': 'Discount',
      'total': 'Total Amount',
      'notes': 'Notes',
      'save': 'Save',
      'cancel': 'Cancel',
      'select_product': 'Select Product',

      // Sales
      'sales_dashboard': 'Sales Dashboard',
      'total_revenue': 'Total Revenue',
      'completed_sales': 'Completed Sales',
      'monthly_overview': 'Monthly Sales Overview',

      // Auth
      'login': 'Login',
      'welcome_back': 'Welcome Back!',
      'email_or_phone': 'Email or Mobile Number',
      'password': 'Password',
      'remember_me': 'Remember Me',
      'login_with_otp': 'Login with OTP',
      'send_otp': 'Send OTP',
      'verify_otp': 'Verify OTP',
      'enter_otp': 'Enter 6-digit OTP',
    },
    'mr': {
      'app_title': 'महाराष्ट्र टायर्स',
      'dashboard': 'डॅशबोर्ड',
      'customers': 'ग्राहक',
      'inventory': 'इन्व्हेंटरी',
      'sales': 'विक्री',
      'invoices': 'पावत्या',
      'reminders': 'स्मरणपत्रे',
      'reports': 'अहवाल',
      'revenue': 'महसूल',
      'suppliers': 'पुरवठादार',
      'notifications': 'सूचना',
      'settings': 'सेटिंग्ज',
      'language': 'भाषा',
      'select_language': 'भाषा निवडा',
      'english': 'English (इंग्रजी)',
      'marathi': 'मराठी (Marathi)',
      'good_morning': 'शुभ सकाळ',
      'todays_sales': 'आजची विक्री',
      'todays_orders': 'आजच्या ऑर्डर्स',
      'products': 'उत्पादने',
      'recent_sales': 'अलीकडील विक्री',
      'low_stock_alert': 'कमी स्टॉक इशारे',
      'quick_actions': 'जलद कृती',
      'add_customer': 'ग्राहक जोडा',
      'new_sale': 'नवीन विक्री',
      'generate_invoice': 'पावती तयार करा',
      'view_all_sales': 'सर्व विक्री पहा',
      'view_inventory': 'इन्व्हेंटरी पहा',
      'left_in_stock': 'शिल्लक',
      'logout': 'लॉग आउट',
      'profile': 'प्रोफाइल',
      'dark_mode': 'डार्क मोड',
      'app_version': 'ॲप आवृत्ती',
      'privacy_policy': 'गोपनीयता धोरण',
      'help_support': 'मदत केंद्र',

      // Customers
      'customer_list': 'ग्राहक यादी',
      'search_customers': 'नाव, फोन किंवा ईमेलद्वारे शोधा...',
      'phone': 'मोबाईल नंबर',
      'email': 'ईमेल पत्ता',
      'address': 'पत्ता',
      'vehicle_no': 'गाडी क्रमांक',
      'edit': 'संपादन करा',
      'delete': 'हटवा',
      'total_customers': 'एकूण ग्राहक',
      'no_customers_found': 'कोणतेही ग्राहक सापडले नाहीत',
      'add_new_customer': 'नवीन ग्राहक जोडा',
      'edit_customer': 'ग्राहक माहिती संपादित करा',

      // Inventory
      'inventory_stock': 'इन्व्हेंटरी स्टॉक',
      'add_product': 'नवीन उत्पादन जोडा',
      'search_products': 'उत्पादन किंवा ब्रँडनुसार शोधा...',
      'product_name': 'उत्पादनाचे नाव',
      'brand': 'ब्रँड / कंपनी',
      'quantity': 'प्रमाण (नग)',
      'price': 'किंमत (₹)',
      'stock_status': 'स्टॉक स्थिती',
      'in_stock': 'उपलब्ध स्टॉक',
      'out_of_stock': 'स्टॉक संपला',
      'low_stock': 'कमी स्टॉक',

      // Invoices
      'all_invoices': 'सर्व पावत्या',
      'create_invoice': 'नवीन पावती तयार करा',
      'search_invoices': 'पावती क्रमांक किंवा ग्राहकाद्वारे शोधा...',
      'invoice_number': 'पावती क्रमांक',
      'customer_name': 'ग्राहकाचे नाव',
      'amount': 'रक्कम',
      'date': 'दिनांक',
      'due_date': 'देय दिनांक',
      'status': 'स्थिती',
      'paid': 'भरले',
      'pending': 'बाकी',
      'download_pdf': 'PDF डाउनलोड',
      'share': 'शेअर करा',
      'customer_details': 'ग्राहकाची माहिती',
      'invoice_details': 'पावतीची माहिती',
      'invoice_items': 'पावती वस्तू',
      'item_description': 'वस्तूचे वर्णन',
      'subtotal': 'उप-एकूण रक्कम',
      'tax': 'कर (Tax)',
      'discount': 'सवलत (Discount)',
      'total': 'एकूण रक्कम',
      'notes': 'टीप',
      'save': 'जतन करा',
      'cancel': 'रद्द करा',
      'select_product': 'उत्पादन निवडा',

      // Sales
      'sales_dashboard': 'विक्री डॅशबोर्ड',
      'total_revenue': 'एकूण महसूल',
      'completed_sales': 'पूर्ण झालेली विक्री',
      'monthly_overview': 'मासिक विक्री आढावा',

      // Auth
      'login': 'लॉगिन करा',
      'welcome_back': 'सुस्वागतम!',
      'email_or_phone': 'ईमेल किंवा मोबाईल नंबर',
      'password': 'पासवर्ड',
      'remember_me': 'माझी माहिती आठवणीत ठेवा',
      'login_with_otp': 'OTP द्वारे लॉगिन करा',
      'send_otp': 'OTP पाठवा',
      'verify_otp': 'OTP सत्यापित करा',
      'enter_otp': '६-अंकी OTP प्रविष्ट करा',
    },
  };
}
