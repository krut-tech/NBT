import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../constants/app_constants.dart';
import 'currency_formatter.dart';
import 'date_formatter.dart';

class PdfGenerator {
  static Future<Uint8List> generateInvoicePdf({
    required String invoiceNumber,
    required String customerName,
    required String customerPhone,
    required String? customerGst,
    required String? customerAddress,
    required String tyreDetails,
    required int quantity,
    required double rate,
    required double subtotal,
    required double discount,
    required double taxAmount,
    required double grandTotal,
    required DateTime invoiceDate,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          AppConstants.appName,
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          AppConstants.companyTagline,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          'Cold Process Tyre Remoulding Factory',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'TAX INVOICE',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.Text('Invoice #: $invoiceNumber'),
                        pw.Text('Date: ${DateFormatter.formatDate(invoiceDate)}'),
                      ],
                    ),
                  ],
                ),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 12),

                // Customer Info Box
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BILLED TO:',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        customerName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text('Phone: $customerPhone'),
                      if (customerGst != null) pw.Text('GSTIN: $customerGst'),
                      if (customerAddress != null) pw.Text('Address: $customerAddress'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Items Table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Sr', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Item Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Rate (₹)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Total (₹)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('1')),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Tyre Remoulding (Cold Process) - $tyreDetails'),
                        ),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('$quantity')),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(CurrencyFormatter.format(rate))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(CurrencyFormatter.format(subtotal))),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Calculation Summary
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 200,
                      child: pw.Column(
                        children: [
                          _pdfSummaryRow('Subtotal:', CurrencyFormatter.format(subtotal)),
                          _pdfSummaryRow('Discount:', '- ${CurrencyFormatter.format(discount)}'),
                          _pdfSummaryRow('GST Tax:', '+ ${CurrencyFormatter.format(taxAmount)}'),
                          pw.Divider(),
                          _pdfSummaryRow('Grand Total:', CurrencyFormatter.format(grandTotal), isBold: true),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.Spacer(),

                // Signatures
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.SizedBox(height: 40),
                        pw.Text('Customer Signature'),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.SizedBox(height: 40),
                        pw.Text('For New Bharat Tyre Remould'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _pdfSummaryRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
