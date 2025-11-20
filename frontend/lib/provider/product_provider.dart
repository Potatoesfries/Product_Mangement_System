import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import '../model/product.dart';
import '../services/api_services.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ProductProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<Product> _displayedProducts = [];
  
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _searchQuery = '';
  
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  bool _hasMore = true;

  List<Product> get products => _displayedProducts;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String get searchQuery => _searchQuery;

  Future<void> fetchProducts() async {
    _isLoading = true;
    _currentPage = 0;
    _displayedProducts.clear();
    _filteredProducts.clear();
    _hasMore = true;
    notifyListeners();

    try {
      _allProducts = await _apiService.getProducts();
      _applyFilters();
      _loadPage();
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyFilters() {
    if (_searchQuery.isEmpty) {
      _filteredProducts = List.from(_allProducts);
    } else {
      _filteredProducts = _allProducts.where((product) {
        return product.productName.toLowerCase().contains(_searchQuery);
      }).toList();
    }
  }

  void _loadPage() {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    
    if (startIndex >= _filteredProducts.length) {
      _hasMore = false;
      return;
    }
    
    final pageBatch = _filteredProducts.sublist(
      startIndex,
      endIndex > _filteredProducts.length ? _filteredProducts.length : endIndex,
    );
    
    _displayedProducts.addAll(pageBatch);
    
    if (_displayedProducts.length >= _filteredProducts.length) {
      _hasMore = false;
    }
  }

  void loadNextPage() {
    if (!_hasMore || _isLoadingMore) return;
    
    _isLoadingMore = true;
    notifyListeners();
    
    _currentPage++;
    _loadPage();
    
    _isLoadingMore = false;
    notifyListeners();
  }

  void searchProducts(String query) {
    _searchQuery = query.toLowerCase();
    
    _currentPage = 0;
    _displayedProducts.clear();
    _hasMore = true;
    
    _applyFilters();
    _loadPage();
    
    notifyListeners();
  }

  void sortByPrice({bool ascending = true}) {
    _allProducts.sort((a, b) {
      return ascending 
          ? a.price.compareTo(b.price) 
          : b.price.compareTo(a.price);
    });
    
    _currentPage = 0;
    _displayedProducts.clear();
    _hasMore = true;
    
    _applyFilters();
    _loadPage();
    
    notifyListeners();
  }

  void sortByStock({bool ascending = true}) {
    _allProducts.sort((a, b) {
      return ascending 
          ? a.stock.compareTo(b.stock) 
          : b.stock.compareTo(a.stock);
    });
    
    _currentPage = 0;
    _displayedProducts.clear();
    _hasMore = true;
    
    _applyFilters();
    _loadPage();
    
    notifyListeners();
  }

  void sortByName({bool ascending = true}) {
    _allProducts.sort((a, b) {
      return ascending 
          ? a.productName.compareTo(b.productName) 
          : b.productName.compareTo(a.productName);
    });
    
    _currentPage = 0;
    _displayedProducts.clear();
    _hasMore = true;
    
    _applyFilters();
    _loadPage();
    
    notifyListeners();
  }

  Future<bool> addProduct(Product product) async {
    try {
      final success = await _apiService.createProduct(product);
      if (success) {
        await fetchProducts();
        return true;
      }
    } catch (e) {
      // Handle error
    }
    return false;
  }

  Future<bool> updateProduct(int id, Product product) async {
    try {
      final success = await _apiService.updateProduct(id, product);
      if (success) {
        await fetchProducts();
        return true;
      }
    } catch (e) {
      // Handle error
    }
    return false;
  }

  Future<bool> deleteProduct(int id) async {
    try {
      final success = await _apiService.deleteProduct(id);
      if (success) {
        await fetchProducts();
        return true;
      }
    } catch (e) {
      // Handle error
    }
    return false;
  }

  Future<String> _getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      try {
        final List<String> possiblePaths = [
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Downloads',
        ];
        
        for (final path in possiblePaths) {
          final directory = Directory(path);
          if (await directory.exists()) {
            return path;
          }
        }
        
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final downloadsPath = Directory('${externalDir.path}/Downloads');
          if (!await downloadsPath.exists()) {
            await downloadsPath.create(recursive: true);
          }
          return downloadsPath.path;
        }
      } catch (e) {
        // Handle error
      }
    }
    
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      
      if (sdkInt >= 33) {
        return true;
      }
      
      if (sdkInt >= 29) {
        var status = await Permission.storage.status;
        
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        
        return status.isGranted;
      }
      
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      
      return status.isGranted;
    } catch (e) {
      return true;
    }
  }

  Future<String> exportToCSV() async {
    try {
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }
      
      String csv = 'Product Name,Price,Stock\n';
      
      for (var product in _allProducts) {
        final name = product.productName.replaceAll(',', ';');
        csv += '$name,${product.price},${product.stock}\n';
      }
      
      final directoryPath = await _getDownloadsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '$directoryPath/products_$timestamp.csv';
      
      final file = File(path);
      await file.writeAsString(csv);
      
      return path;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> exportToPDF() async {
    try {
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }
      
      final PdfDocument document = PdfDocument();
      final PdfPage page = document.pages.add();
      final Size pageSize = page.getClientSize();
      
      page.graphics.drawString(
        'Product Report',
        PdfStandardFont(PdfFontFamily.helvetica, 24, style: PdfFontStyle.bold),
        brush: PdfBrushes.black,
        bounds: Rect.fromLTWH(0, 0, pageSize.width, 50),
      );
      
      final dateText = 'Generated: ${DateTime.now().toString().substring(0, 16)}';
      page.graphics.drawString(
        dateText,
        PdfStandardFont(PdfFontFamily.helvetica, 10),
        brush: PdfBrushes.gray,
        bounds: Rect.fromLTWH(0, 30, pageSize.width, 20),
      );
      
      final PdfGrid grid = PdfGrid();
      grid.columns.add(count: 3);
      grid.headers.add(1);
      
      grid.columns[0].width = pageSize.width * 0.5;
      grid.columns[1].width = pageSize.width * 0.25;
      grid.columns[2].width = pageSize.width * 0.25;
      
      PdfGridRow header = grid.headers[0];
      header.cells[0].value = 'Product Name';
      header.cells[1].value = 'Price';
      header.cells[2].value = 'Stock';
      
      final headerStyle = PdfGridCellStyle(
        backgroundBrush: PdfBrushes.lightBlue,
        textBrush: PdfBrushes.black,
        font: PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
        format: PdfStringFormat(alignment: PdfTextAlignment.left),
      );
      
      for (int i = 0; i < 3; i++) {
        header.cells[i].style = headerStyle;
      }
      
      for (var product in _allProducts) {
        PdfGridRow row = grid.rows.add();
        row.cells[0].value = product.productName;
        row.cells[1].value = '\$${product.price.toStringAsFixed(2)}';
        row.cells[2].value = '${product.stock}';
        
        for (int i = 0; i < 3; i++) {
          row.cells[i].style = PdfGridCellStyle(
            font: PdfStandardFont(PdfFontFamily.helvetica, 10),
            format: PdfStringFormat(alignment: PdfTextAlignment.left),
          );
        }
      }
      
      grid.style = PdfGridStyle(
        cellPadding: PdfPaddings(left: 5, right: 5, top: 5, bottom: 5),
        font: PdfStandardFont(PdfFontFamily.helvetica, 10),
      );
      
      grid.draw(
        page: page,
        bounds: Rect.fromLTWH(0, 60, pageSize.width, pageSize.height - 60),
      );
      
      final directoryPath = await _getDownloadsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '$directoryPath/products_$timestamp.pdf';
      
      final List<int> bytes = await document.save();
      final file = File(path);
      await file.writeAsBytes(bytes);
      
      document.dispose();
      
      return path;
    } catch (e, stackTrace) {
      rethrow;
    }
  }
}