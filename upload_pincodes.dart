import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:logger/logger.dart';

final Logger _logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    colors: true,
    printEmojis: true,
  ),
);

Future<void> uploadPincodes() async {
  final firestore = FirebaseFirestore.instance;
  _logger.i('Starting pincode upload process');

  try {
    // 1. Load and parse CSV
    _logger.d('Loading CSV file');
    final csvData = await rootBundle.loadString('assets/pincodes.csv');
    final List<List<dynamic>> rows =
        const CsvToListConverter().convert(csvData);
    _logger.i('Found ${rows.length - 1} pincodes to process');

    if (rows.length <= 1) {
      throw Exception('CSV file is empty or only contains headers');
    }

    // 2. Batch processing configuration
    const batchSize = 500;
    WriteBatch batch = firestore.batch();
    int successCount = 0;
    int batchCount = 0;

    // 3. Process each record
    for (int i = 1; i < rows.length; i++) {
      try {
        final pincode = rows[i][0].toString().padLeft(6, '0');
        final district = rows[i][1].toString().trim().toUpperCase();
        final state = rows[i][2].toString().trim().toUpperCase();

        if (pincode.length != 6) {
          _logger.w('Invalid pincode length at row $i: $pincode');
          continue;
        }

        final docRef = firestore.collection('pincodes').doc(pincode);
        batch.set(docRef, {
          'district': district,
          'state': state,
          'uploadedAt': FieldValue.serverTimestamp(),
        });

        batchCount++;
        successCount++;

        // Commit batch when size reaches the limit or at the end
        if (batchCount % batchSize == 0 || i == rows.length - 1) {
          _logger.d('Committing batch of $batchCount records');
          await batch.commit();
          batch = firestore.batch();
          batchCount = 0;
        }
      } catch (e) {
        _logger.e('Error processing row $i', error: e);
      }
    }

    _logger.i(
        '✅ Upload completed. Successfully uploaded $successCount/${rows.length - 1} records');
  } on PlatformException catch (e) {
    _logger.e('File access error', error: e);
    rethrow;
  } on FirebaseException catch (e) {
    _logger.e('Firestore error', error: e);
    rethrow;
  } catch (e, stackTrace) {
    _logger.e('Unexpected error', error: e, stackTrace: stackTrace);
    rethrow;
  }
}
