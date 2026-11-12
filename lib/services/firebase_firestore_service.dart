import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Kết quả xuất báo cáo lên Cloud Firestore.
class FirestoreExportResult {
  const FirestoreExportResult.success({
    required this.documentId,
    required this.collectionPath,
    required this.data,
  }) : isSuccess = true,
       errorMessage = null;

  const FirestoreExportResult.failure(this.errorMessage)
    : isSuccess = false,
      documentId = null,
      collectionPath = null,
      data = const {};

  final bool isSuccess;
  final String? documentId;
  final String? collectionPath;
  final Map<String, dynamic> data;
  final String? errorMessage;
}

/// Dịch vụ xuất báo cáo và lưu trữ tài liệu trên Cloud Firestore.
class FirebaseFirestoreService {
  FirebaseFirestoreService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore,
      _auth = auth;

  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;

  static final FirebaseFirestoreService instance = FirebaseFirestoreService();

  bool get _hasFirebase => !kIsWeb && Firebase.apps.isNotEmpty;

  FirebaseFirestore get _instance => _firestore ?? FirebaseFirestore.instance;
  FirebaseAuth get _authInstance => _auth ?? FirebaseAuth.instance;

  /// Xuất báo cáo sử dụng AI và ghi nhận vào Cloud Firestore.
  /// Lưu vào collection `reports` và subcollection `users/{uid}/reports`.
  Future<FirestoreExportResult> exportReport({
    required String userName,
    required String userEmail,
    required int totalTokens,
    required double totalCost,
    required int requestCount,
    required List<Map<String, dynamic>> providers,
    String? customNote,
  }) async {
    final now = DateTime.now();
    final uid = _authInstance.currentUser?.uid ?? 'anonymous';
    final reportData = <String, dynamic>{
      'userId': uid,
      'userName': userName,
      'userEmail': userEmail,
      'title': 'Báo cáo chi phí AI TokenScope',
      'period': '${now.month.toString().padLeft(2, '0')}/${now.year}',
      'totalTokens': totalTokens,
      'totalCost': totalCost,
      'requestCount': requestCount,
      'providers': providers,
      'customNote': customNote ?? '',
      'createdAt': now.toIso8601String(),
      'status': 'completed',
      'source': 'TokenScope App',
    };

    if (!_hasFirebase) {
      // Giả lập khi chạy unit test hoặc không có Firebase.
      final mockId = 'report_${now.millisecondsSinceEpoch}';
      return FirestoreExportResult.success(
        documentId: mockId,
        collectionPath: 'reports',
        data: reportData,
      );
    }

    try {
      final docData = Map<String, dynamic>.from(reportData);
      docData['serverTimestamp'] = FieldValue.serverTimestamp();

      // 1. Lưu vào collection chính `reports`
      final docRef = await _instance.collection('reports').add(docData);

      // 2. Đồng thời lưu vào collection riêng của user `users/{uid}/reports`
      if (uid.isNotEmpty && uid != 'anonymous') {
        try {
          await _instance
              .collection('users')
              .doc(uid)
              .collection('reports')
              .doc(docRef.id)
              .set(docData);
        } catch (_) {}
      }

      return FirestoreExportResult.success(
        documentId: docRef.id,
        collectionPath: 'reports',
        data: reportData,
      );
    } catch (e) {
      return FirestoreExportResult.failure(
        'Không thể lưu báo cáo lên Firestore: $e',
      );
    }
  }

  /// Lấy Stream danh sách các báo cáo đã xuất từ Cloud Firestore.
  Stream<QuerySnapshot<Map<String, dynamic>>> getReportsStream() {
    if (!_hasFirebase) {
      return const Stream.empty();
    }
    final uid = _authInstance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      return _instance
          .collection('users')
          .doc(uid)
          .collection('reports')
          .orderBy('serverTimestamp', descending: true)
          .snapshots();
    }
    return _instance
        .collection('reports')
        .orderBy('serverTimestamp', descending: true)
        .snapshots();
  }
}
