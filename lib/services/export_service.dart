import 'dart:io';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/image_details.dart';

class ExportService {
  /// Export image details to Excel format
  static Future<String> exportToExcel(List<ImageDetails> images) async {
    final excel = Excel.createExcel();
    final sheet = excel['Image Details'];

    // Header style
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: '#E0E0E0',
      horizontalAlign: HorizontalAlign.Center,
    );

    final headers = [
      'Image Name',
      'Date',
      'Time',
      'Location',
      'Coordinates',
      'File Size',
      'File Path'
    ];

    // Add headers
    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
        ..value = headers[i]
        ..cellStyle = headerStyle;
    }

    // Add rows
    var row = 1;
    for (var image in images) {
      final file = File(image.path);
      final fileSize = _formatFileSize(file.lengthSync());
      final date = DateFormat('dd/MM/yyyy').format(image.timestamp);
      final time = DateFormat('hh:mm a').format(image.timestamp);
      final location = image.locationString ?? 'No location';
      final coordinates = image.latitude != null && image.longitude != null
          ? '${image.latitude!.toStringAsFixed(6)}°, ${image.longitude!.toStringAsFixed(6)}°'
          : 'No coordinates';
      final name =
          'IMG_${DateFormat('yyyyMMdd_HHmmss').format(image.timestamp)}';

      final rowData = [
        name,
        date,
        time,
        location,
        coordinates,
        fileSize,
        image.path,
      ];

      for (var i = 0; i < rowData.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          ..value = rowData[i];
      }
      row++;
    }

    // Auto-fit columns
    for (var i = 0; i < headers.length; i++) {
      sheet.setColAutoFit(i);
    }

    // Add summary row
    final summaryStyle = CellStyle(
      bold: true,
      backgroundColorHex: '#F5F5F5',
    );

    row++;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = 'Total Images:'
      ..cellStyle = summaryStyle;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
      ..value = images.length
      ..cellStyle = summaryStyle;

    // Save file
    final directory = await _getExportDirectory();
    final fileName =
        'image_details_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);

    return filePath;
  }

  /// Export image details to PDF format
  static Future<String> exportToPDF(List<ImageDetails> images) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Image Details Report',
                      style: pw.TextStyle(
                          fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Total Images: ${images.length}',
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              context: context,
              headerDecoration: pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              headerHeight: 25,
              cellHeight: 40,
              headerStyle: pw.TextStyle(
                color: PdfColors.black,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(
                fontSize: 10,
              ),
              headers: [
                'Image Name',
                'Date',
                'Time',
                'Location',
                'Coordinates',
                'File Size',
                'File Path'
              ],
              data: images.map((image) {
                final file = File(image.path);
                final fileSize = _formatFileSize(file.lengthSync());
                final date = DateFormat('dd/MM/yyyy').format(image.timestamp);
                final time = DateFormat('hh:mm a').format(image.timestamp);
                final location = image.locationString ?? 'No location';
                final coordinates = image.latitude != null &&
                        image.longitude != null
                    ? '${image.latitude!.toStringAsFixed(6)}°, ${image.longitude!.toStringAsFixed(6)}°'
                    : 'No coordinates';
                final name =
                    'IMG_${DateFormat('yyyyMMdd_HHmmss').format(image.timestamp)}';

                return [
                  name,
                  date,
                  time,
                  location,
                  coordinates,
                  fileSize,
                  image.path,
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    // Save file
    final directory = await _getExportDirectory();
    final fileName =
        'image_details_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    return filePath;
  }

  /// Format file size from bytes to KB/MB
  static String _formatFileSize(int sizeInBytes) {
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Determine export directory (Downloads on Android, Documents elsewhere)
  static Future<Directory> _getExportDirectory() async {
    // Use app's internal directory that doesn't require permissions
    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${directory.path}/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }
}
