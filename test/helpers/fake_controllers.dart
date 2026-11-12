import 'package:tokenscope/models/budget_overview.dart';
import 'package:tokenscope/models/project_connection.dart';
import 'package:tokenscope/models/usage_analysis.dart';
import 'package:tokenscope/providers/analysis_controller.dart';
import 'package:tokenscope/providers/budget_controller.dart';
import 'package:tokenscope/providers/projects_controller.dart';
import 'package:tokenscope/services/analysis_service.dart';
import 'package:tokenscope/services/budget_service.dart';
import 'package:tokenscope/services/project_service.dart';

/// ── Ngân sách ─────────────────────────────────────────────────────────

/// Service ngân sách giả lập — trả về dữ liệu có cùng hình dạng với
/// `GET /api/budgets`.
class FakeBudgetService implements BudgetService {
  @override
  Future<BudgetOverview> getOverview() async {
    return const BudgetOverview(
      periodLabel: '01/10 - 31/10',
      totalLimit: 40.0,
      threshold: 32.0,
      spent: 34.80,
      percent: 87.0,
      thresholdPercent: 108.75,
      forecast: 41.20,
      providers: [
        BudgetProviderUsage(
          providerType: 'openai',
          name: 'OpenAI API',
          models: 'GPT-4o, o1-mini',
          spent: 19.20,
          limit: 22.0,
        ),
        BudgetProviderUsage(
          providerType: 'anthropic',
          name: 'Anthropic Claude',
          models: 'Claude 3.5 Sonnet',
          spent: 8.20,
          limit: 10.0,
        ),
        BudgetProviderUsage(
          providerType: 'google',
          name: 'Google Gemini',
          models: 'Gemini 1.5 Pro',
          spent: 7.40,
          limit: 8.0,
        ),
      ],
      projects: [
        BudgetProjectUsage(
          id: 'p1',
          name: 'Copilot Backend',
          models: 'gpt-4o, claude-3-5-sonnet',
          spent: 14.20,
          limit: 16.0,
        ),
        BudgetProjectUsage(
          id: 'p2',
          name: 'Marketing Agent',
          models: 'gpt-4o-mini',
          spent: 9.60,
          limit: 12.0,
        ),
        BudgetProjectUsage(
          id: 'p3',
          name: 'RAG Search',
          models: 'gemini-1.5-pro',
          spent: 11.00,
          limit: 12.0,
        ),
      ],
    );
  }

  @override
  Future<BudgetOverview> updateBudget({
    required double totalLimit,
    double warningPercent = 80,
  }) async {
    return getOverview();
  }
}

/// Controller ngân sách dùng service giả lập.
BudgetController buildFakeBudgetController() {
  return BudgetController(service: FakeBudgetService());
}

// ── Dự án ──────────────────────────────────────────────────────────────

/// Service dự án giả lập — trả về dữ liệu có cùng hình dạng với
/// `GET /api/projects`.
class FakeProjectService implements ProjectService {
  @override
  Future<ProjectsOverview> getProjects() async {
    return const ProjectsOverview(
      projects: [
        ProjectConnection(
          id: 'p1',
          name: 'Chatbot Support',
          description: 'Hỗ trợ khách hàng tự động 24/7',
          color: '#6366F1',
          environment: 'Production',
          totalTokens: 1350000,
          totalCost: 21.50,
          requestCount: 40,
          monthlyLimit: 25.0,
          budgetPercent: 86,
          systemSharePercent: 55,
          models: [
            ProjectModelUsage(
              provider: 'OpenAI',
              model: 'gpt-4o',
              totalTokens: 900000,
            ),
          ],
        ),
        ProjectConnection(
          id: 'p2',
          name: 'Content Generator',
          description: 'Tạo bài viết SEO & mạng xã hội',
          color: '#38BDF8',
          environment: 'Staging',
          totalTokens: 720000,
          totalCost: 8.90,
          requestCount: 25,
          monthlyLimit: 10.0,
          budgetPercent: 89,
          systemSharePercent: 28,
          models: [
            ProjectModelUsage(
              provider: 'Google',
              model: 'Gemini 1.5 Pro',
              totalTokens: 500000,
            ),
          ],
        ),
        ProjectConnection(
          id: 'p3',
          name: 'Developer Assistant',
          description: 'Giải thích code & phân tích lỗi',
          color: '#8B5CF6',
          environment: 'Internal',
          totalTokens: 380000,
          totalCost: 4.40,
          requestCount: 18,
          monthlyLimit: 12.0,
          budgetPercent: 37,
          systemSharePercent: 16,
          models: [
            ProjectModelUsage(
              provider: 'Anthropic',
              model: 'Claude 3.5 Sonnet',
              totalTokens: 220000,
            ),
          ],
        ),
      ],
      totalTokens: 2450000,
      totalCost: 34.80,
      requestCount: 83,
      projectCount: 3,
    );
  }
}

/// Controller dự án dùng service giả lập.
ProjectsController buildFakeProjectsController() {
  return ProjectsController(service: FakeProjectService());
}

// ── Phân tích ──────────────────────────────────────────────────────────

/// Service phân tích giả lập — trả về dữ liệu có cùng hình dạng với
/// `GET /api/usage/analysis`.
class FakeAnalysisService implements AnalysisService {
  @override
  Future<UsageAnalysis> getAnalysis({int days = 7}) async {
    return UsageAnalysis(
      totalTokens: 1970000,
      totalCost: 34.80,
      requestCount: 56,
      inputTokens: 1800000,
      outputTokens: 650000,
      inputRatio: 0.735,
      outputRatio: 0.265,
      dailyAverage: 281429,
      weekly: const [
        DailyAnalysisPoint(
          date: '2026-10-05',
          totalTokens: 180000,
          totalCost: 2.50,
        ),
        DailyAnalysisPoint(
          date: '2026-10-06',
          totalTokens: 240000,
          totalCost: 3.50,
        ),
        DailyAnalysisPoint(
          date: '2026-10-07',
          totalTokens: 205000,
          totalCost: 3.50,
        ),
        DailyAnalysisPoint(
          date: '2026-10-08',
          totalTokens: 450000,
          totalCost: 6.40,
        ),
        DailyAnalysisPoint(
          date: '2026-10-09',
          totalTokens: 320000,
          totalCost: 5.50,
        ),
        DailyAnalysisPoint(
          date: '2026-10-10',
          totalTokens: 285000,
          totalCost: 5.50,
        ),
        DailyAnalysisPoint(
          date: '2026-10-11',
          totalTokens: 290000,
          totalCost: 7.40,
        ),
      ],
      peak: const DailyAnalysisPoint(
        date: '2026-10-08',
        totalTokens: 450000,
        totalCost: 6.40,
      ),
      byProvider: const [
        ProviderAnalysis(
          providerType: 'openai',
          provider: 'OpenAI',
          totalTokens: 1300000,
          totalCost: 19.20,
          requestCount: 30,
        ),
        ProviderAnalysis(
          providerType: 'anthropic',
          provider: 'Anthropic Claude',
          totalTokens: 450000,
          totalCost: 8.20,
          requestCount: 15,
        ),
        ProviderAnalysis(
          providerType: 'google',
          provider: 'Google Gemini',
          totalTokens: 220000,
          totalCost: 7.40,
          requestCount: 11,
        ),
      ],
      byModel: const [
        ModelAnalysis(
          model: 'gpt-4o',
          provider: 'OpenAI',
          providerType: 'openai',
          totalTokens: 1300000,
          totalCost: 12.60,
          requestCount: 30,
        ),
        ModelAnalysis(
          model: 'gemini-1.5-pro',
          provider: 'Google Gemini',
          providerType: 'google',
          totalTokens: 850000,
          totalCost: 6.10,
          requestCount: 20,
        ),
        ModelAnalysis(
          model: 'claude-3-5-sonnet',
          provider: 'Anthropic Claude',
          providerType: 'anthropic',
          totalTokens: 450000,
          totalCost: 8.20,
          requestCount: 15,
        ),
        ModelAnalysis(
          model: 'gemini-1.5-flash',
          provider: 'Google Gemini',
          providerType: 'google',
          totalTokens: 150000,
          totalCost: 1.90,
          requestCount: 8,
        ),
        ModelAnalysis(
          model: 'gpt-4o-mini',
          provider: 'OpenAI',
          providerType: 'openai',
          totalTokens: 100000,
          totalCost: 1.60,
          requestCount: 6,
        ),
      ],
    );
  }
}

/// Controller phân tích dùng service giả lập.
AnalysisController buildFakeAnalysisController() {
  return AnalysisController(service: FakeAnalysisService());
}
