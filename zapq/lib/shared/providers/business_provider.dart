import 'package:flutter/material.dart';
import '../models/business_model.dart';
import '../models/booking_model.dart';

class BusinessProvider extends ChangeNotifier {
  
  List<BusinessModel> _businesses = [];
  final List<BusinessModel> _userBusinesses = [];
  final List<BookingModel> _businessBookings = [];
  BusinessModel? _selectedBusiness;
  bool _isLoading = false;
  String? _errorMessage;

  List<BusinessModel> get businesses => _businesses;
  List<BusinessModel> get userBusinesses => _userBusinesses;
  List<BookingModel> get businessBookings => _businessBookings;
  BusinessModel? get selectedBusiness => _selectedBusiness;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setBusinesses(List<BusinessModel> businesses) {
    _businesses = businesses;
    notifyListeners();
  }

  void addBusiness(BusinessModel business) {
    _businesses.add(business);
    notifyListeners();
  }

  void updateBusiness(BusinessModel business) {
    final index = _businesses.indexWhere((b) => b.id == business.id);
    if (index != -1) {
      _businesses[index] = business;
      notifyListeners();
    }
  }

  void removeBusiness(String businessId) {
    _businesses.removeWhere((b) => b.id == businessId);
    notifyListeners();
  }

  void setSelectedBusiness(BusinessModel? business) {
    _selectedBusiness = business;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  List<BusinessModel> filterByCategory(String category) {
    if (category.isEmpty) return _businesses;
    return _businesses.where((b) => b.category == category).toList();
  }

  List<BusinessModel> searchBusinesses(String query) {
    if (query.isEmpty) return _businesses;
    return _businesses.where((b) => 
      b.name.toLowerCase().contains(query.toLowerCase()) ||
      b.category.toLowerCase().contains(query.toLowerCase()) ||
      b.address.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}
