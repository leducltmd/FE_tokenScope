import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Kết quả tải tệp lên Firebase Cloud Storage.
class StorageUploadResult {
  const StorageUploadResult.success({
    required this.downloadUrl,
    required this.storagePath,
    required this.fileSizeBytes,
  }) : isSuccess = true,
       errorMessage = null;

  const StorageUploadResult.failure(this.errorMessage)
    : isSuccess = false,
      downloadUrl = null,
      storagePath = null,
      fileSizeBytes = 0;

  final bool isSuccess;
  final String? downloadUrl;
  final String? storagePath;
  final int fileSizeBytes;
  final String? errorMessage;
}

/// Dịch vụ tạo báo cáo PDF và lưu trữ đám mây qua Firebase Cloud Storage.
///
/// Tuân thủ Slide 8–10 của Lab 3:
/// - Tạo tệp PDF báo cáo thống kê sử dụng AI.
/// - Tải lên thư mục `reports/{uid}/tokenscope_report_{timestamp}.pdf`.
/// - Theo dõi tiến độ upload qua Stream (0.0 → 1.0).
/// - Lấy URL tải xuống và xử lý lỗi mạng / phân quyền.
class FirebaseStorageService {
  FirebaseStorageService({FirebaseStorage? storage, FirebaseAuth? auth})
    : _storage = storage,
      _auth = auth;

  final FirebaseStorage? _storage;
  final FirebaseAuth? _auth;

  static final FirebaseStorageService instance = FirebaseStorageService();

  bool get _hasFirebase => !kIsWeb && Firebase.apps.isNotEmpty;

  FirebaseStorage get _instance => _storage ?? FirebaseStorage.instance;
  FirebaseAuth get _authInstance => _auth ?? FirebaseAuth.instance;

  /// Tạo tệp PDF báo cáo thống kê sử dụng AI bằng thư viện `pdf`.
  Future<Uint8List> generatePdfReport({
    required String userName,
    required String userEmail,
    required int totalTokens,
    required double totalCost,
    required int requestCount,
    required List<Map<String, dynamic>> providers,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'TokenScope AI Monitoring Report',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        DateTime.now().toString().split('.')[0],
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  'User: $userName ($userEmail)',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.indigo300),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(8),
                    ),
                    color: PdfColors.indigo50,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricColumn(
                        'Total Tokens',
                        totalTokens.toString(),
                      ),
                      _buildMetricColumn(
                        'Total Cost',
                        '\$${totalCost.toStringAsFixed(4)} USD',
                      ),
                      _buildMetricColumn(
                        'Total Calls',
                        requestCount.toString(),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 24),
                pw.Text(
                  'Connected Providers Breakdown',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.TableHelper.fromTextArray(
                  headers: ['Provider', 'Models', 'Tokens Used', 'Cost (USD)'],
                  data: providers
                      .map(
                        (p) => [
                          p['name']?.toString() ?? 'Unknown',
                          p['model']?.toString() ?? 'Default',
                          p['tokens']?.toString() ?? '0',
                          '\$${(p['cost'] ?? 0.0).toString()}',
                        ],
                      )
                      .toList(),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.indigo,
                  ),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellPadding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
                pw.Spacer(),
                pw.Divider(),
                pw.Center(
                  child: pw.Text(
                    'Generated securely by TokenScope - PRM393 Cloud Platform',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildMetricColumn(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.indigo900,
          ),
        ),
      ],
    );
  }

  /// Tải tệp PDF lên Cloud Storage theo đúng cấu trúc bảo mật `reports/{uid}/...`.
  ///
  /// Cung cấp hàm callback [onProgress] (0.0 → 1.0) để giao diện hiển thị thanh tiến độ.
  Future<StorageUploadResult> uploadReportPdf({
    required Uint8List pdfBytes,
    void Function(double progress)? onProgress,
  }) async {
    if (!_hasFirebase) {
      return const StorageUploadResult.failure(
        'Firebase chưa được khởi tạo trên thiết bị này.',
      );
    }

    final user = _authInstance.currentUser;
    if (user == null) {
      return const StorageUploadResult.failure(
        'Bạn cần đăng nhập Firebase trước khi tải báo cáo lên.',
      );
    }

    final uid = user.uid;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'tokenscope_report_$timestamp.pdf';
    final storagePath = 'reports/$uid/$fileName';

    try {
      onProgress?.call(0);
      final ref = _instance.ref().child(storagePath);
      final metadata = SettableMetadata(
        contentType: 'application/pdf',
        customMetadata: {
          'uploaded_by': uid,
          'timestamp': timestamp.toString(),
          'app': 'TokenScope',
        },
      );

      final uploadTask = ref.putData(pdfBytes, metadata);
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (snapshot.totalBytes > 0) {
          onProgress?.call(snapshot.bytesTransferred / snapshot.totalBytes);
        }
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      onProgress?.call(1);

      return StorageUploadResult.success(
        downloadUrl: downloadUrl,
        storagePath: storagePath,
        fileSizeBytes: snapshot.totalBytes,
      );
    } on FirebaseException catch (error) {
      debugPrint('[Storage] Upload failed: ${error.code}: ${error.message}');
      return StorageUploadResult.failure(
        error.message ??
            'Không thể tải tệp lên Firebase Storage (${error.code}).',
      );
    } catch (error) {
      debugPrint('[Storage] Upload failed: $error');
      return StorageUploadResult.failure(
        'Không thể tải tệp lên Firebase Storage: $error',
      );
    }
  }
}
