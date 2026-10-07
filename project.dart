// lib/main.dart

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:path/path.dart' as path;

import 'package:pdf/pdf.dart';

import 'package:pdf/widgets.dart' as pw;

import 'package:printing/printing.dart';

import 'package:shamsi_date/shamsi_date.dart';

import 'package:sqflite/sqflite.dart';

const int maxSessions = 10;

const String paid = 'پرداخت شده';

const String unpaid = 'پرداخت نشده';

const Color backgroundColor = Color(0xFF121417);

const Color panelColor = Color(0xFF1B1F24);

const Color fieldColor = Color(0xFF252B33);

const Color borderColor = Color(0xFF323A45);

const Color textColor = Color(0xFFE8EAED);

const Color mutedColor = Color(0xFF9AA4B2);

const Color accentColor = Color(0xFF4F9CF9);

const Color greenColor = Color(0xFF2EAD6B);

const Color redColor = Color(0xFFE5484D);

const Color orangeColor = Color(0xFFF5A524);

String toPersianDigits(Object value) {

  const english = '0123456789';

  const persian = '۰۱۲۳۴۵۶۷۸۹';

  var result = value.toString();

  for (int i = 0; i < english.length; i++) {

    result = result.replaceAll(english, persian);

  }

  return result;

}

String getShamsiDate() {

  final date = Jalali.now();

  final year = date.year.toString();

  final month = date.month.toString().padLeft(2, '0');

  final day = date.day.toString().padLeft(2, '0');

  return toPersianDigits('$year/$month/$day');

}

class SessionRecord {

  final int id;

  final String studentName;

  final int term;

  final int sessionNumber;

  final String sessionDate;

  final String paymentStatus;

  final String notes;

  const SessionRecord({

    required this.id,

    required this.studentName,

    required this.term,

    required this.sessionNumber,

    required this.sessionDate,

    required this.paymentStatus,

    required this.notes,

  });

  factory SessionRecord.fromMap(Map<String, Object?> map) {

    return SessionRecord(

      id: map['id'] as int,

      studentName: map['student_name'] as String,

      term: map['term'] as int,

      sessionNumber: map['session_number'] as int,

      sessionDate: map['session_date'] as String,

      paymentStatus: map['payment_status'] as String,

      notes: (map['notes'] as String?) ?? '',

    );

  }

}

class DatabaseHelper {

  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {

    if (_database != null) {

      return _database!;

    }

    final databasePath = await getDatabasesPath();

    final fullPath = path.join(databasePath, 'teacher_sessions.db');

    _database = await openDatabase(

      fullPath,

      version: 1,

      onCreate: (database, version) async {

        await database.execute('''

          CREATE TABLE sessions (

            id INTEGER PRIMARY KEY AUTOINCREMENT,

            student_name TEXT NOT NULL,

            session_number INTEGER NOT NULL,

            session_date TEXT NOT NULL,

            payment_status TEXT NOT NULL,

            notes TEXT,

            term INTEGER NOT NULL DEFAULT 1

          )

        ''');

      },

    );

    return _database!;

  }

  Future<List<String>> getStudents() async {

    final database = await this.database;

    final rows = await database.rawQuery(

      '''

      SELECT DISTINCT student_name

      FROM sessions

      ORDER BY student_name

      ''',

    );

    return rows

        .map((row) => row['student_name'] as String)

        .toList();

  }

  Future<(int, int)> getStudentState(String studentName) async {

    final database = await this.database;

    final termRows = await database.rawQuery(

      '''

      SELECT MAX(term) AS current_term

      FROM sessions

      WHERE student_name = ?

      ''',

     ,

    );

    final currentTerm =

        (termRows.first['current_term'] as int?) ?? 1;

    final sessionRows = await database.rawQuery(

      '''

      SELECT MAX(session_number) AS last_session

      FROM sessions

      WHERE student_name = ? AND term = ?

      ''',

     ,

    );

    final lastSession =

        (sessionRows.first['last_session'] as int?) ?? 0;

    return (currentTerm, lastSession);

  }

  Future<void> insertSession({

    required String studentName,

    required int term,

    required int sessionNumber,

    required String sessionDate,

    required String paymentStatus,

    required String notes,

  }) async {

    final database = await this.database;

    await database.insert(

      'sessions',

      {

        'student_name': studentName,

        'term': term,

        'session_number': sessionNumber,

        'session_date': sessionDate,

        'payment_status': paymentStatus,

        'notes': notes,

      },

    );

  }

  Future<List<SessionRecord>> getSessions(String searchText) async {

    final database = await this.database;

    final rows = await database.query(

      'sessions',

      where: searchText.isEmpty ? null : 'student_name LIKE ?',

      whereArgs: searchText.isEmpty ? null : ['%$searchText%'],

      orderBy: 'student_name, term, session_number',

    );

    return rows.map(SessionRecord.fromMap).toList();

  }

  Future<void> deleteSession(int id) async {

    final database = await this.database;

    await database.delete(

      'sessions',

      where: 'id = ?',

      whereArgs:,

    );

  }

  Future<void> updatePaymentStatus(

    int id,

    String paymentStatus,

  ) async {

    final database = await this.database;

    await database.update(

      'sessions',

      {'payment_status': paymentStatus},

      where: 'id = ?',

      whereArgs:,

    );

  }

}

​<light>void main() {​</light>

  WidgetsFlutterBinding.ensureInitialized();

  runApp(const TeacherSessionApp());

}

class TeacherSessionApp extends StatelessWidget {

  const TeacherSessionApp({super.key});

  @override

  Widget build(BuildContext context) {

    return MaterialApp(

      title: 'مدیریت جلسات آموزشی',

      debugShowCheckedModeBanner: false,

      locale: const Locale('fa', 'IR'),

      builder: (context, child) {

        return Directionality(

          textDirection: TextDirection.rtl,

          child: child ?? const SizedBox(),

        );

      },

      theme: ThemeData(

        brightness: Brightness.dark,

        fontFamily: 'Vazirmatn',

        scaffoldBackgroundColor: backgroundColor,

        colorScheme: const ColorScheme.dark(

          primary: accentColor,

          surface: panelColor,

        ),

        inputDecorationTheme: InputDecorationTheme(

          filled: true,

          fillColor: fieldColor,

          labelStyle: const TextStyle(color: mutedColor),

          enabledBorder: OutlineInputBorder(

            borderRadius: BorderRadius.circular(8),

            borderSide: const BorderSide(color: borderColor),

          ),

          focusedBorder: OutlineInputBorder(

            borderRadius: BorderRadius.circular(8),

            borderSide: const BorderSide(color: accentColor),

          ),

          border: OutlineInputBorder(

            borderRadius: BorderRadius.circular(8),

            borderSide: const BorderSide(color: borderColor),

          ),

        ),

      ),

      home: const HomePage(),

    );

  }

}

class HomePage extends StatefulWidget {

  const HomePage({super.key});

  @override

  State<HomePage> createState() => _HomePageState();

}

class _HomePageState extends State<HomePage> {

  final DatabaseHelper databaseHelper = DatabaseHelper.instance;

  final TextEditingController studentNameController =

      TextEditingController();

  final TextEditingController dateController =

      TextEditingController(text: getShamsiDate());

  final TextEditingController notesController =

      TextEditingController();

  final TextEditingController searchController =

      TextEditingController();

  List<String> students = [];

  List<SessionRecord> sessions = [];

  String paymentStatus = unpaid;

  String informationText = 'نام شاگرد را وارد یا انتخاب کنید.';

  Color informationColor = mutedColor;

  int nextSession = 1;

  int currentTerm = 1;

  int? selectedSessionId;

  bool termFinished = false;

  @override

  void initState() {

    super.initState();

    studentNameController.addListener(

      updateSessionInformation,

    );

    refreshData();

  }

  @override

  void dispose() {

    studentNameController.dispose();

    dateController.dispose();

    notesController.dispose();

    searchController.dispose();

    super.dispose();

  }

  Future<void> refreshData() async {

    await refreshStudents();

    await loadSessions();

    await updateSessionInformation();

  }

  Future<void> refreshStudents() async {

    final result = await databaseHelper.getStudents();

    if (!mounted) {

      return;

    }

    setState(() {

      students = result;

    });

  }

  Future<void> loadSessions() async {

    final result = await databaseHelper.getSessions(

      searchController.text.trim(),

    );

    if (!mounted) {

      return;

    }

    setState(() {

      sessions = result;

      if (selectedSessionId != null &&

          !sessions.any((item) => item.id == selectedSessionId)) {

        selectedSessionId = null;

      }

    });

  }

  Future<void> updateSessionInformation() async {

    final studentName = studentNameController.text.trim();

    if (studentName.isEmpty) {

      if (!mounted) {

        return;

      }

      setState(() {

        nextSession = 1;

        currentTerm = 1;

        termFinished = false;

        informationText = 'نام شاگرد را وارد یا انتخاب کنید.';

        informationColor = mutedColor;

      });

      return;

    }

    final state =

        await databaseHelper.getStudentState(studentName);

    final term = state.$1;

    final lastSession = state.$2;

    if (!mounted) {

      return;

    }

    setState(() {

      currentTerm = term;

      if (lastSession >= maxSessions) {

        termFinished = true;

        nextSession = maxSessions;

        informationText =

            'دوره ${toPersianDigits(term)} این شاگرد با '

            '${toPersianDigits(maxSessions)} جلسه تمام شده است.';

        informationColor = redColor;

      } else {

        termFinished = false;

        nextSession = lastSession + 1;

        if (lastSession == 0) {

          informationText =

              'دوره ${toPersianDigits(term)}: اولین جلسه این شاگرد است.';

        } else {

          informationText =

              'دوره ${toPersianDigits(term)}: '

              '${toPersianDigits(lastSession)} جلسه از '

              '${toPersianDigits(maxSessions)} جلسه برگزار شده است.';

        }

        informationColor = greenColor;

      }

    });

  }

  void showMessage(String message) {

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(content: Text(message)),

    );

  }

  Future<void> showInformationDialog(

    String title,

    String message,

  ) async {

    await showDialog<void>(

      context: context,

      builder: (dialogContext) {

        return AlertDialog(

          title: Text(title),

          content: Text(message),

          actions: [

            TextButton(

              onPressed: () {

                Navigator.pop(dialogContext);

              },

              child: const Text('باشه'),

            ),

          ],

        );

      },

    );

  }

  Future<void> addSession() async {

    final studentName = studentNameController.text.trim();

    final sessionDate = dateController.text.trim();

    final notes = notesController.text.trim();

    if (studentName.isEmpty) {

      showMessage('لطفاً نام شاگرد را وارد کنید.');

      return;

    }

    if (sessionDate.isEmpty) {

      showMessage('لطفاً تاریخ جلسه را وارد کنید.');

      return;

    }

    final state =

        await databaseHelper.getStudentState(studentName);

    final term = state.$1;

    final lastSession = state.$2;

    if (lastSession >= maxSessions) {

      await showInformationDialog(

        'پایان دوره',

        'دوره ${toPersianDigits(term)} شاگرد «$studentName» '

            'با ${toPersianDigits(maxSessions)} جلسه تمام شده است.\n'

            'برای ادامه، دکمه «شروع دوره جدید» را بزنید.',

      );

      await updateSessionInformation();

      return;

    }

    final sessionNumber = lastSession + 1;

    await databaseHelper.insertSession(

      studentName: studentName,

      term: term,

      sessionNumber: sessionNumber,

      sessionDate: sessionDate,

      paymentStatus: paymentStatus,

      notes: notes,

    );

    await refreshStudents();

    await loadSessions();

    setState(() {

      notesController.clear();

      dateController.text = getShamsiDate();

      paymentStatus = unpaid;

    });

    await updateSessionInformation();

    if (sessionNumber == maxSessions) {

      await showInformationDialog(

        'پایان دوره',

        'جلسه ${toPersianDigits(sessionNumber)} ثبت شد.\n'

            'دوره ${toPersianDigits(term)} شاگرد «$studentName» تمام شد.',

      );

    } else {

      showMessage(

        'جلسه ${toPersianDigits(sessionNumber)} ثبت شد. '

        'جلسه بعدی: ${toPersianDigits(sessionNumber + 1)}',

      );

    }

  }

  Future<void> startNewTerm() async {

    final studentName = studentNameController.text.trim();

    if (studentName.isEmpty) {

      showMessage('ابتدا نام شاگرد را انتخاب کنید.');

      return;

    }

    final state =

        await databaseHelper.getStudentState(studentName);

    final term = state.$1;

    final lastSession = state.$2;

    if (lastSession < maxSessions) {

      showMessage('دوره فعلی این شاگرد هنوز تمام نشده است.');

      return;

    }

    final newTerm = term + 1;

    await databaseHelper.insertSession(

      studentName: studentName,

      term: newTerm,

      sessionNumber: 1,

      sessionDate: dateController.text.trim().isEmpty

          ? getShamsiDate()

          : dateController.text.trim(),

      paymentStatus: paymentStatus,

      notes: notesController.text.trim(),

    );

    await loadSessions();

    setState(() {

      notesController.clear();

      dateController.text = getShamsiDate();

      paymentStatus = unpaid;

    });

    await updateSessionInformation();

    showMessage(

      'دوره ${toPersianDigits(newTerm)} شروع شد و جلسه اول ثبت شد.',

    );

  }

  Future<void> deleteSelectedSession() async {

    final id = selectedSessionId;

    if (id == null) {

      showMessage('لطفاً یک جلسه را از جدول انتخاب کنید.');

      return;

    }

    final confirmed = await showDialog<bool>(

      context: context,

      builder: (dialogContext) {

        return AlertDialog(

          title: const Text('تأیید حذف'),

          content: const Text(

            'آیا از حذف جلسه انتخاب‌شده مطمئن هستید؟',

          ),

          actions: [

            TextButton(

              onPressed: () {

                Navigator.pop(dialogContext, false);

              },

              child: const Text('خیر'),

            ),

            TextButton(

              onPressed: () {

                Navigator.pop(dialogContext, true);

              },

              child: const Text('بله'),

            ),

          ],

        );

      },

    );

    if (confirmed != true) {

      return;

    }

    await databaseHelper.deleteSession(id);

    selectedSessionId = null;

    await refreshStudents();

    await loadSessions();

    await updateSessionInformation();

  }

  Future<void> togglePaymentStatus() async {

    final id = selectedSessionId;

    if (id == null) {

      showMessage('لطفاً یک جلسه را از جدول انتخاب کنید.');

      return;

    }

    final selectedSession =

        sessions.firstWhere((item) => item.id == id);

    final newStatus =

        selectedSession.paymentStatus == paid ? unpaid : paid;

    await databaseHelper.updatePaymentStatus(

      id,

      newStatus,

    );

    await loadSessions();

  }

  void clearForm() {

    setState(() {

      studentNameController.clear();

      dateController.text = getShamsiDate();

      notesController.clear();

      paymentStatus = unpaid;

    });

    updateSessionInformation();

  }

  Future<void> exportPdf() async {

    final data = await databaseHelper.getSessions(

      searchController.text.trim(),

    );

    if (data.isEmpty) {

      showMessage('اطلاعاتی برای ساخت گزارش وجود ندارد.');

      return;

    }

    try {

      final fontData = await rootBundle.load(

        'assets/fonts/Vazirmatn-Regular.ttf',

      );

      final font = pw.Font.ttf(fontData);

      pw.Widget tableCell(

        String text, {

        bool header = false,

      }) {

        return pw.Padding(

          padding: const pw.EdgeInsets.all(5),

          child: pw.Text(

            text,

            textDirection: pw.TextDirection.rtl,

            textAlign: pw.TextAlign.center,

            style: pw.TextStyle(

              font: font,

              fontSize: 9,

              color: header ? PdfColors.white : PdfColors.black,

            ),

          ),

        );

      }

      final tableRows = <pw.TableRow>[

        pw.TableRow(

          decoration: const pw.BoxDecoration(

            color: PdfColors.blue700,

          ),

          children: [

            'توضیحات',

            'وضعیت پرداخت',

            'تاریخ جلسه',

            'شماره جلسه',

            'دوره',

            'نام شاگرد',

          ]

              .map(

                (title) => tableCell(

                  title,

                  header: true,

                ),

              )

              .toList(),

        ),

      ];

      for (int index = 0; index < data.length; index++) {

        final item = data;

        tableRows.add(

          pw.TableRow(

            decoration: pw.BoxDecoration(

              color: index.isEven

                  ? PdfColors.white

                  : PdfColors.blue50,

            ),

            children: [

              tableCell(item.notes),

              tableCell(item.paymentStatus),

              tableCell(item.sessionDate),

              tableCell(toPersianDigits(item.sessionNumber)),

              tableCell(toPersianDigits(item.term)),

              tableCell(item.studentName),

            ],

          ),

        );

      }

      final document = pw.Document();

      document.addPage(

        pw.MultiPage(

          pageFormat: PdfPageFormat.a4.landscape,

          margin: const pw.EdgeInsets.all(25),

          build: (context) {

            return [

              pw.Center(

                child: pw.Text(

                  'گزارش جلسات آموزشی شاگردان',

                  textDirection: pw.TextDirection.rtl,

                  style: pw.TextStyle(

                    font: font,

                    fontSize: 16,

                  ),

                ),

              ),

              pw.SizedBox(height: 8),

              pw.Align(

                alignment: pw.Alignment.centerRight,

                child: pw.Text(

                  'تاریخ تهیه گزارش: ${getShamsiDate()}',

                  textDirection: pw.TextDirection.rtl,

                  style: pw.TextStyle(

                    font: font,

                    fontSize: 10,

                  ),

                ),

              ),

              pw.SizedBox(height: 12),

              pw.Table(

                border: pw.TableBorder.all(

                  color: PdfColors.grey,

                  width: 0.5,

                ),

                columnWidths: const {

                  0: pw.FlexColumnWidth(3),

                  1: pw.FlexColumnWidth(2),

                  2: pw.FlexColumnWidth(2),

                  3: pw.FlexColumnWidth(1.5),

                  4: pw.FlexColumnWidth(1),

                  5: pw.FlexColumnWidth(3),

                },

                children: tableRows,

              ),

            ];

          },

        ),

      );

      await Printing.sharePdf(

        bytes: await document.save(),

        filename: 'sessions_report.pdf',

      );

    } catch (error) {

      showMessage('ساخت فایل PDF انجام نشد: $error');

    }

  }

  Widget buildButton(

    String text,

    Color color,

    VoidCallback? onPressed,

  ) {

    return ElevatedButton(

      onPressed: onPressed,

      style: ElevatedButton.styleFrom(

        backgroundColor: color,

        foregroundColor: Colors.white,

        disabledBackgroundColor: color.withOpacity(0.35),

        padding: const EdgeInsets.symmetric(

          horizontal: 18,

          vertical: 14,

        ),

        shape: RoundedRectangleBorder(

          borderRadius: BorderRadius.circular(8),

        ),

      ),

      child: Text(

        text,

        style: const TextStyle(

          fontWeight: FontWeight.bold,

        ),

      ),

    );

  }

  Widget buildForm() {

    final searchName = studentNameController.text.trim();

    final suggestions = students

        .where(

          (student) =>

              searchName.isEmpty || student.contains(searchName),

        )

        .take(12)

        .toList();

    return Container(

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(

        color: panelColor,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: borderColor),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(

            children: [

              Expanded(

                child: TextField(

                  controller: studentNameController,

                  decoration: const InputDecoration(

                    labelText: 'نام شاگرد',

                  ),

                ),

              ),

              const SizedBox(width: 12),

              Container(

                width: 130,

                padding: const EdgeInsets.symmetric(vertical: 8),

                decoration: BoxDecoration(

                  color: fieldColor,

                  borderRadius: BorderRadius.circular(8),

                  border: Border.all(color: borderColor),

                ),

                child: Column(

                  children: [

                    const Text(

                      'شماره جلسه خودکار',

                      style: TextStyle(

                        color: mutedColor,

                        fontSize: 10,

                      ),

                    ),

                    Text(

                      termFinished

                          ? '✓'

                          : toPersianDigits(nextSession),

                      style: TextStyle(

                        color: termFinished

                            ? redColor

                            : accentColor,

                        fontSize: 22,

                        fontWeight: FontWeight.bold,

                      ),

                    ),

                  ],

                ),

              ),

            ],

          ),

          if (suggestions.isNotEmpty) ...[

            const SizedBox(height: 8),

            Wrap(

              spacing: 6,

              runSpacing: 4,

              children: suggestions

                  .map(

                    (student) => ActionChip(

                      label: Text(student),

                      backgroundColor: fieldColor,

                      onPressed: () {

                        studentNameController.text = student;

                      },

                    ),

                  )

                  .toList(),

            ),

          ],

          const SizedBox(height: 12),

          Row(

            children: [

              Expanded(

                child: TextField(

                  controller: dateController,

                  textAlign: TextAlign.center,

                  decoration: const InputDecoration(

                    labelText: 'تاریخ شمسی',

                  ),

                ),

              ),

              const SizedBox(width: 12),

              Expanded(

                child: DropdownButtonFormField<String>(

                  value: paymentStatus,

                  decoration: const InputDecoration(

                    labelText: 'وضعیت پرداخت',

                  ),

                  items: const [

                    DropdownMenuItem(

                      value: paid,

                      child: Text(paid),

                    ),

                    DropdownMenuItem(

                      value: unpaid,

                      child: Text(unpaid),

                    ),

                  ],

                  onChanged: (value) {

                    setState(() {

                      paymentStatus = value ?? unpaid;

                    });

                  },

                ),

              ),

            ],

          ),

          const SizedBox(height: 12),

          TextField(

            controller: notesController,

            decoration: const InputDecoration(

              labelText: 'توضیحات',

            ),

          ),

          const SizedBox(height: 10),

          Text(

            informationText,

            style: TextStyle(

              color: informationColor,

              fontWeight: FontWeight.bold,

            ),

          ),

          const SizedBox(height: 10),

          Wrap(

            spacing: 8,

            runSpacing: 8,

            children: [

              buildButton(

                'ثبت جلسه',

                accentColor,

                termFinished ? null : addSession,

              ),

              buildButton(

                'شروع دوره جدید',

                orangeColor,

                termFinished ? startNewTerm : null,

              ),

              buildButton(

                'پاک کردن فرم',

                const Color(0xFF5B6572),

                clearForm,

              ),

              buildButton(

                'گزارش PDF',

                greenColor,

                exportPdf,

              ),

            ],

          ),

        ],

      ),

    );

  }

  Widget buildSessionsList() {

    if (sessions.isEmpty) {

      return const Center(

        child: Text(

          'جلسه‌ای ثبت نشده است.',

          style: TextStyle(color: mutedColor),

        ),

      );

    }

    return ListView.separated(

      itemCount: sessions.length,

      separatorBuilder: (context, index) {

        return const Divider(

          height: 1,

          color: borderColor,

        );

      },

      itemBuilder: (context, index) {

        final session = sessions;

        final isSelected =

            session.id == selectedSessionId;

        final isPaid = session.paymentStatus == paid;

        return ListTile(

          selected: isSelected,

          selectedTileColor: accentColor.withOpacity(0.25),

          onTap: () {

            setState(() {

              selectedSessionId = session.id;

            });

          },

          leading: CircleAvatar(

            backgroundColor: fieldColor,

            child: Text(

              toPersianDigits(session.sessionNumber),

              style: const TextStyle(color: accentColor),

            ),

          ),

          title: Text(

            '${session.studentName} '

            '(دوره ${toPersianDigits(session.term)})',

          ),

          subtitle: Text(

            '${session.sessionDate}'

            '${session.notes.isNotEmpty ? ' | ${session.notes}' : ''}',

            style: const TextStyle(color: mutedColor),

          ),

          trailing: Text(

            session.paymentStatus,

            style: TextStyle(

              color: isPaid

                  ? const Color(0xFF5BD58F)

                  : const Color(0xFFFF8A8F),

              fontWeight: FontWeight.bold,

            ),

          ),

        );

      },

    );

  }

  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        backgroundColor: backgroundColor,

        title: const Text(

          'سامانه مدیریت جلسات آموزشی',

          style: TextStyle(fontWeight: FontWeight.bold),

        ),

        actions: [

          Padding(

            padding: const EdgeInsets.symmetric(horizontal: 16),

            child: Center(

              child: Text(

                'امروز: ${getShamsiDate()}',

                style: const TextStyle(

                  color: accentColor,

                  fontWeight: FontWeight.bold,

                ),

              ),

            ),

          ),

        ],

      ),

      body: SafeArea(

        child: Padding(

          padding: const EdgeInsets.all(12),

          child: Column(

            children: [

              Flexible(

                flex: 0,

                child: ConstrainedBox(

                  constraints: BoxConstraints(

                    maxHeight:

                        MediaQuery.of(context).size.height * 0.55,

                  ),

                  child: SingleChildScrollView(

                    child: buildForm(),

                  ),

                ),

              ),

              const SizedBox(height: 10),

              Row(

                children: [

                  Expanded(

                    child: TextField(

                      controller: searchController,

                      onChanged: (value) {

                        loadSessions();

                      },

                      decoration: const InputDecoration(

                        labelText: 'جست‌وجوی نام شاگرد',

                        prefixIcon: Icon(Icons.search),

                        isDense: true,

                      ),

                    ),

                  ),

                  const SizedBox(width: 8),

                  TextButton(

                    onPressed: () {

                      searchController.clear();

                      loadSessions();

                    },

                    child: const Text('نمایش همه'),

                  ),

                ],

              ),

              const SizedBox(height: 10),

              Expanded(

                child: Container(

                  decoration: BoxDecoration(

                    color: panelColor,

                    borderRadius: BorderRadius.circular(12),

                    border: Border.all(color: borderColor),

                  ),

                  clipBehavior: Clip.antiAlias,

                  child: buildSessionsList(),

                ),

              ),

              const SizedBox(height: 8),

              Row(

                children: [

                  Text(

                    'تعداد جلسات: ${toPersianDigits(sessions.length)}',

                    style: const TextStyle(color: mutedColor),

                  ),

                  const Spacer(),

                  buildButton(

                    'تغییر وضعیت پرداخت',

                    const Color(0xFF7A5AF8),

                    togglePaymentStatus,

                  ),

                  const SizedBox(width: 8),

                  buildButton(

                    'حذف جلسه',

                    redColor,

                    deleteSelectedSession,

                  ),

                ],

              ),

            ],

          ),

        ),

      ),

    );

  }

}