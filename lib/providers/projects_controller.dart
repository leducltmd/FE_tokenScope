import 'package:flutter/foundation.dart';

import '../models/project_connection.dart';
import '../services/project_service.dart';

/// ViewModel quản lý danh sách dự án.
///
/// Dữ liệu lấy từ backend thật (`GET /api/projects`) — không có dữ liệu giả lập.
class ProjectsController extends ChangeNotifier {
  ProjectsController({ProjectService? service})
    : _service = service ?? ApiProjectService();

  ProjectService _service;

  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  List<ProjectConnection> _projects = const [];
  int _totalTokens = 0;
  double _totalCost = 0;
  int _requestCount = 0;

  // ── Getters ──────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  List<ProjectConnection> get projects => List.unmodifiable(_projects);
  int get totalTokens => _totalTokens;
  double get totalCost => _totalCost;
  int get requestCount => _requestCount;
  bool get isEmpty => !_isLoading && !_hasError && _projects.isEmpty;

  /// Cho phép thay nguồn dữ liệu.
  void useService(ProjectService service) {
    _service = service;
    loadProjects();
  }

  /// Tải danh sách dự án từ backend.
  Future<void> loadProjects() async {
    if (_isLoading) return;
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final overview = await _service.getProjects();
      _projects = overview.projects;
      _totalTokens = overview.totalTokens;
      _totalCost = overview.totalCost;
      _requestCount = overview.requestCount;
      _hasError = false;
      _errorMessage = null;
    } catch (error) {
      _hasError = true;
      _errorMessage = error.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
