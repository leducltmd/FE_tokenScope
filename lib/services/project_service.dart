import '../models/project_connection.dart';
import 'api_client.dart';

/// Nguồn dữ liệu dự án — mặc định gọi backend thật (`GET /api/projects`).
abstract class ProjectService {
  /// Lấy danh sách dự án kèm số liệu usage & ngân sách thật.
  Future<ProjectsOverview> getProjects();
}

/// Triển khai gọi backend thật.
class ApiProjectService implements ProjectService {
  ApiProjectService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  @override
  Future<ProjectsOverview> getProjects() async {
    final data = await _client.get('/projects');
    return ProjectsOverview.fromJson(data);
  }
}
