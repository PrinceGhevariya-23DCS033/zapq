import 'package:flutter/material.dart';
import '../models/queue_model.dart';

class QueueProvider extends ChangeNotifier {
  List<QueueModel> _queues = [];
  QueueModel? _currentQueue;
  bool _isLoading = false;
  String? _errorMessage;

  List<QueueModel> get queues => _queues;
  QueueModel? get currentQueue => _currentQueue;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setQueues(List<QueueModel> queues) {
    _queues = queues;
    notifyListeners();
  }

  void addQueue(QueueModel queue) {
    _queues.add(queue);
    notifyListeners();
  }

  void updateQueue(QueueModel queue) {
    final index = _queues.indexWhere((q) => q.id == queue.id);
    if (index != -1) {
      _queues[index] = queue;
      notifyListeners();
    }
  }

  void removeQueue(String queueId) {
    _queues.removeWhere((q) => q.id == queueId);
    notifyListeners();
  }

  void setCurrentQueue(QueueModel? queue) {
    _currentQueue = queue;
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

  List<QueueModel> getQueuesByBusiness(String businessId) {
    return _queues.where((q) => q.businessId == businessId).toList();
  }

  List<QueueModel> getQueuesByCustomer(String customerId) {
    return _queues.where((q) => q.customerId == customerId).toList();
  }

  List<QueueModel> getActiveQueues() {
    return _queues.where((q) => q.isWaiting || q.isActive).toList();
  }

  int getQueuePosition(String businessId, String customerId) {
    final businessQueues = getQueuesByBusiness(businessId)
        .where((q) => q.isWaiting)
        .toList();
    
    businessQueues.sort((a, b) => a.bookedAt.compareTo(b.bookedAt));
    
    for (int i = 0; i < businessQueues.length; i++) {
      if (businessQueues[i].customerId == customerId) {
        return i + 1;
      }
    }
    
    return -1;
  }
}
