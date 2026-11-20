import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import '../models/contract_model.dart';
import '../models/work_shift_model.dart';
import '../utils/date_formatter.dart';

class AttendanceExportService {
  const AttendanceExportService();

  /// Converts Czech diacritics to basic ASCII for standard PDF Helvetica font
  static String unaccent(String text) {
    const from = 'áčďéěíňóřšťúůýžÁČĎÉĚÍŇÓŘŠŤÚŮÝŽ';
    const to   = 'acdeeinorstuuyzACDEEINORSTUUYZ';
    var result = text;
    for (var i = 0; i < from.length; i++) {
      result = result.replaceAll(from[i], to[i]);
    }
    return result;
  }

  static String escapePdfText(String text) {
    return unaccent(text)
        .replaceAll(r'\', r'\\')
        .replaceAll('(', r'\(')
        .replaceAll(')', r'\)');
  }

  /// Generates a valid ISO 32000-1 (PDF 1.4) binary document
  List<int> generatePdfBytes(Contract contract, List<WorkShift> shifts) {
    final buffer = StringBuffer();
    final now = DateTime.now();
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(now);
    final currencyFmt = NumberFormat.currency(locale: 'cs_CZ', symbol: 'Kc', decimalDigits: 0);

    final totalHours = shifts.fold<double>(0.0, (sum, s) => sum + s.hours);
    final totalWage = shifts.fold<double>(0.0, (sum, s) => sum + s.wage);

    // Page coordinates: A4 is 595.28 x 841.89 points
    final content = StringBuffer();

    // Blue Header Banner
    content.writeln('q');
    content.writeln('0.06 0.16 0.38 rg'); // Dark Navy #0F2A60
    content.writeln('40 760 515 50 re f');
    content.writeln('Q');

    // Title text inside banner
    content.writeln('BT');
    content.writeln('/F2 16 Tf');
    content.writeln('1 1 1 rg'); // White
    content.writeln('55 788 Td');
    content.writeln('(PREHLED DOCHAZKY A ODPRACOVANE DOBY) Tj');
    content.writeln('/F1 9 Tf');
    content.writeln('0 -16 Td');
    content.writeln('(Prehled odpracovanych smen pro kontrolu | Paragraf v kapse) Tj');
    content.writeln('ET');

    // Contract Info Box (grey background)
    content.writeln('q');
    content.writeln('0.95 0.96 0.98 rg');
    content.writeln('40 655 515 95 re f');
    content.writeln('0.82 0.85 0.90 RG');
    content.writeln('1 w');
    content.writeln('40 655 515 95 re S');
    content.writeln('Q');

    content.writeln('BT');
    content.writeln('0.1 0.1 0.1 rg');
    // Row 1
    content.writeln('/F2 10 Tf');
    content.writeln('55 730 Td (Zamestnavatel:) Tj');
    content.writeln('/F1 10 Tf');
    content.writeln('105 0 Td (${escapePdfText(contract.companyName)}) Tj');
    content.writeln('/F2 10 Tf');
    content.writeln('150 0 Td (Vystaveno:) Tj');
    content.writeln('/F1 10 Tf');
    content.writeln('75 0 Td (${escapePdfText(dateStr)}) Tj');

    // Row 2
    content.writeln('/F2 10 Tf');
    content.writeln('-330 -18 Td (Pracovni pozice:) Tj');
    content.writeln('/F1 10 Tf');
    content.writeln('105 0 Td (${escapePdfText(contract.jobTitle)}) Tj');
    content.writeln('/F2 10 Tf');
    content.writeln('150 0 Td (Typ uvazku:) Tj');
    content.writeln('/F1 10 Tf');
    content.writeln('75 0 Td (${escapePdfText(contract.contractType.label)}) Tj');

    // Row 3
    content.writeln('/F2 10 Tf');
    content.writeln('-330 -18 Td (Misto vykonu:) Tj');
    content.writeln('/F1 10 Tf');
    content.writeln('105 0 Td (${escapePdfText(contract.workLocation.isNotEmpty ? contract.workLocation : "Dle smlouvy")}) Tj');
    content.writeln('/F2 10 Tf');
    content.writeln('150 0 Td (Sazba / mzda:) Tj');
    content.writeln('/F1 10 Tf');
    content.writeln('75 0 Td (${contract.contractType == ContractType.hpp ? "${contract.monthlyGrossWage.toInt()} Kc/mes" : "${contract.hourlyWage.toInt()} Kc/hod"}) Tj');

    // Row 4
    content.writeln('/F2 10 Tf');
    content.writeln('-330 -18 Td (Danove prohlaseni:) Tj');
    content.writeln('/F1 10 Tf');
    content.writeln('105 0 Td (${contract.hasTaxDeclaration ? "Uplatneno (ruzovka)" : "Neuplatneno"}) Tj');
    content.writeln('/F2 10 Tf');
    content.writeln('150 0 Td (Sleva na deti:) Tj');
    content.writeln('/F1 10 Tf');
    content.writeln('75 0 Td (${contract.taxReliefChildrenCount > 0 ? "${contract.taxReliefChildrenCount} deti" : "0 deti"}) Tj');
    content.writeln('ET');

    // Shifts Table Header
    content.writeln('q');
    content.writeln('0.15 0.35 0.65 rg');
    content.writeln('40 620 515 22 re f');
    content.writeln('Q');

    content.writeln('BT');
    content.writeln('/F2 9 Tf');
    content.writeln('1 1 1 rg');
    content.writeln('48 627 Td (#) Tj');
    content.writeln('25 0 Td (Datum smeny) Tj');
    content.writeln('85 0 Td (Odpracovano) Tj');
    content.writeln('75 0 Td (Hodinova sazba) Tj');
    content.writeln('85 0 Td (Narok na odmenu) Tj');
    content.writeln('95 0 Td (Popis prace / Ukon) Tj');
    content.writeln('ET');

    // Shifts Rows
    double y = 600;
    final maxRows = shifts.length > 20 ? 20 : shifts.length;

    for (int i = 0; i < maxRows; i++) {
      final s = shifts[i];
      final isEven = i % 2 == 0;

      // Row background
      if (isEven) {
        content.writeln('q');
        content.writeln('0.97 0.98 0.99 rg');
        content.writeln('40 ${y - 4} 515 18 re f');
        content.writeln('Q');
      }

      // Border line
      content.writeln('q');
      content.writeln('0.88 0.90 0.94 RG');
      content.writeln('0.5 w');
      content.writeln('40 ${y - 4} 515 0 re S');
      content.writeln('Q');

      content.writeln('BT');
      content.writeln('0.15 0.15 0.15 rg');
      content.writeln('/F1 9 Tf');
      content.writeln('48 $y Td (${i + 1}.) Tj');
      content.writeln('25 0 Td (${escapePdfText(CzechDateFormatter.formatShort(s.date))}) Tj');
      content.writeln('85 0 Td (${s.hours.toStringAsFixed(1)} h) Tj');
      content.writeln('75 0 Td (${s.hourlyRate.toInt()} Kc/h) Tj');
      content.writeln('/F2 9 Tf');
      content.writeln('85 0 Td (${currencyFmt.format(s.wage)}) Tj');
      content.writeln('/F1 9 Tf');
      final desc = s.description.isNotEmpty ? s.description : 'Standardni smena';
      final safeDesc = desc.length > 32 ? '${desc.substring(0, 30)}...' : desc;
      content.writeln('95 0 Td (${escapePdfText(safeDesc)}) Tj');
      content.writeln('ET');

      y -= 18;
    }

    if (shifts.isEmpty) {
      content.writeln('BT');
      content.writeln('/F1 10 Tf');
      content.writeln('0.4 0.4 0.4 rg');
      content.writeln('220 580 Td (Zadne zapsane smeny v tomto obdobi.) Tj');
      content.writeln('ET');
      y = 560;
    }

    // Summary Box
    y -= 10;
    content.writeln('q');
    content.writeln('0.92 0.96 0.94 rg'); // Light mint green
    content.writeln('40 ${y - 35} 515 40 re f');
    content.writeln('0.20 0.60 0.35 RG'); // Green border
    content.writeln('1.2 w');
    content.writeln('40 ${y - 35} 515 40 re S');
    content.writeln('Q');

    content.writeln('BT');
    content.writeln('0.1 0.4 0.2 rg');
    content.writeln('/F2 11 Tf');
    content.writeln('55 ${y - 12} Td (SOUHRN ZA OBDOBI:) Tj');
    content.writeln('0 -15 Td (CELKEM ODPRACOVANO: ${totalHours.toStringAsFixed(1)} HODIN) Tj');
    content.writeln('260 0 Td (CELKOVA HRUBA ODMENA: ${currencyFmt.format(totalWage)}) Tj');
    content.writeln('ET');

    // Signatures Section
    y -= 75;
    content.writeln('BT');
    content.writeln('0.2 0.2 0.2 rg');
    content.writeln('/F1 9 Tf');
    content.writeln('55 $y Td (V ................................... dne ..........................) Tj');
    content.writeln('0 -35 Td (............................................................) Tj');
    content.writeln('0 -12 Td (Podpis zamestnance) Tj');
    content.writeln('300 12 Td (............................................................) Tj');
    content.writeln('0 -12 Td (Podpis a razitko zamestnavatele) Tj');
    content.writeln('ET');

    // Footer
    content.writeln('BT');
    content.writeln('0.5 0.5 0.5 rg');
    content.writeln('/F1 8 Tf');
    content.writeln('40 40 Td (Dokument vygenerovan aplikaci Paragraf v kapse. Slouzi jako oficialni evidence pracovni doby dle § 96 ZP.) Tj');
    content.writeln('ET');

    final contentBytes = utf8.encode(content.toString());

    // Assemble PDF 1.4 Object Stream
    final offsets = <int>[];

    void writeObj(String str) {
      offsets.add(buffer.length);
      buffer.write(str);
    }

    buffer.write('%PDF-1.4\n%\xE2\xE3\xCF\xD3\n');

    // 1: Catalog
    writeObj('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');

    // 2: Pages
    writeObj('2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n');

    // 3: Page
    writeObj(
      '3 0 obj\n'
      '<< /Type /Page /Parent 2 0 R\n'
      '/MediaBox [0 0 595.28 841.89]\n'
      '/Resources <<\n'
      '  /Font <<\n'
      '    /F1 4 0 R\n'
      '    /F2 5 0 R\n'
      '  >>\n'
      '>>\n'
      '/Contents 6 0 R\n'
      '>>\n'
      'endobj\n',
    );

    // 4: Font Helvetica
    writeObj(
      '4 0 obj\n'
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>\n'
      'endobj\n',
    );

    // 5: Font Helvetica-Bold
    writeObj(
      '5 0 obj\n'
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>\n'
      'endobj\n',
    );

    // 6: Stream Content
    writeObj(
      '6 0 obj\n'
      '<< /Length ${contentBytes.length} >>\n'
      'stream\n'
      '${content.toString()}'
      'endstream\n'
      'endobj\n',
    );

    // xref
    final xrefOffset = buffer.length;
    buffer.write('xref\n0 7\n0000000000 65535 f \n');
    for (final offset in offsets) {
      buffer.write('${offset.toString().padLeft(10, '0')} 00000 n \n');
    }

    // trailer
    buffer.write(
      'trailer\n'
      '<< /Size 7 /Root 1 0 R >>\n'
      'startxref\n'
      '$xrefOffset\n'
      '%%EOF\n',
    );

    return latin1.encode(buffer.toString());
  }

  /// Generates CSV format for Excel
  String generateCsv(Contract contract, List<WorkShift> shifts) {
    final sb = StringBuffer();
    // UTF-8 BOM so Excel opens with correct diacritics
    sb.write('\uFEFF');
    sb.writeln('EVIDENCE DOCHÁZKY A ODPRACOVANÉ DOBY (§ 96 ZP)');
    sb.writeln('Zaměstnavatel;${contract.companyName}');
    sb.writeln('Pracovní pozice;${contract.jobTitle}');
    sb.writeln('Typ úvazku;${contract.contractType.label}');
    sb.writeln('Místo výkonu;${contract.workLocation}');
    sb.writeln('Datum exportu;${CzechDateFormatter.formatFull(DateTime.now())}');
    sb.writeln('');
    sb.writeln('Pořadí;Datum směny;Odpracováno (hodiny);Hodinová sazba (Kč/h);Nárok na odměnu (Kč);Poznámka / Popis činnosti');

    for (int i = 0; i < shifts.length; i++) {
      final s = shifts[i];
      sb.writeln(
        '${i + 1};${CzechDateFormatter.formatShort(s.date)};${s.hours.toStringAsFixed(1)};${s.hourlyRate.toInt()};${s.wage.toInt()};"${s.description.replaceAll('"', '""')}"',
      );
    }

    final totalHours = shifts.fold<double>(0.0, (sum, s) => sum + s.hours);
    final totalWage = shifts.fold<double>(0.0, (sum, s) => sum + s.wage);

    sb.writeln('');
    sb.writeln('CELKEM;;${totalHours.toStringAsFixed(1)};;${totalWage.toInt()};');
    return sb.toString();
  }

  /// Generates human-readable text summary
  String generateTextSummary(Contract contract, List<WorkShift> shifts) {
    final totalHours = shifts.fold<double>(0.0, (sum, s) => sum + s.hours);
    final totalWage = shifts.fold<double>(0.0, (sum, s) => sum + s.wage);
    final currencyFmt = NumberFormat.currency(locale: 'cs_CZ', symbol: 'Kč', decimalDigits: 0);

    final sb = StringBuffer();
    sb.writeln('📋 PŘEHLED DOCHÁZKY A ODPRACOVANÝCH HODIN');
    sb.writeln('Zaměstnavatel: ${contract.companyName}');
    sb.writeln('Pozice: ${contract.jobTitle} (${contract.contractType.label})');
    sb.writeln('Místo výkonu: ${contract.workLocation.isNotEmpty ? contract.workLocation : "Dle smlouvy"}');
    sb.writeln('Exportováno: ${CzechDateFormatter.formatFull(DateTime.now())}');
    sb.writeln('--------------------------------------------------');
    sb.writeln('ZÁZNAMY SMĚN:');

    if (shifts.isEmpty) {
      sb.writeln('Žádné zapsané směny.');
    } else {
      for (int i = 0; i < shifts.length; i++) {
        final s = shifts[i];
        final desc = s.description.isNotEmpty ? ' (${s.description})' : '';
        sb.writeln('${i + 1}. ${CzechDateFormatter.formatShort(s.date)} — ${s.hours.toStringAsFixed(1)} hod • ${currencyFmt.format(s.wage)}$desc');
      }
    }

    sb.writeln('--------------------------------------------------');
    sb.writeln('CELKEM ODPRACOVÁNO: ${totalHours.toStringAsFixed(1)} hodin');
    sb.writeln('CELKOVÁ ODMĚNA: ${currencyFmt.format(totalWage)}');
    sb.writeln('Vygenerováno v aplikaci Paragraf v kapse');
    return sb.toString();
  }

  /// Saves bytes to local file storage and returns created File
  Future<File> saveFile({
    required String fileName,
    required List<int> bytes,
  }) async {
    Directory targetDir;
    try {
      // Try Download folder on Android if accessible
      final androidDownload = Directory('/storage/emulated/0/Download');
      if (await androidDownload.exists()) {
        targetDir = androidDownload;
      } else {
        targetDir = Directory.current;
      }
    } catch (_) {
      targetDir = Directory.current;
    }

    final safeName = fileName
        .replaceAll(' ', '_')
        .replaceAll('/', '_')
        .replaceAll('\\', '_');
    final file = File('${targetDir.path}/$safeName');
    return await file.writeAsBytes(bytes, flush: true);
  }
}
