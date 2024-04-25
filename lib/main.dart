import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdfLib;

class DBHelper {
  static late Database _database;

  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await initDatabase();
    return _database;
  }

  Future<Database> initDatabase() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = directory.path + 'your_database.db';
    return await openDatabase(path, version: 1, onCreate: _createDb);
  }

  void _createDb(Database db, int newVersion) async {
    await db.execute(
        'CREATE TABLE your_table(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, price REAL)');
  }

  Future<void> insertData(String name, double price) async {
    final db = await database;
    await db.insert('your_table', {'name': name, 'price': price});
  }

  Future<List<Map<String, dynamic>>> getData() async {
    final db = await database;
    return await db.query('your_table');
  }
}

class MyApp extends StatelessWidget {
  final DBHelper dbHelper = DBHelper();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('SQLite & PDF Example'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Product Name'),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  String name = nameController.text;
                  double price = double.parse(priceController.text);
                  dbHelper.insertData(name, price);
                },
                child: Text('Store Data'),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  List<Map<String, dynamic>> data = await dbHelper.getData();
                  await generatePDF(data);
                },
                child: Text('Generate Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> generatePDF(List<Map<String, dynamic>> data) async {
    final pdfLib.Document pdf = pdfLib.Document();
    pdf.addPage(
      pdfLib.Page(
        build: (pdfLib.Context context) => pdfLib.Table.fromTextArray(
          context: context,
          data: [
            ['ID', 'Name', 'Price'],
            for (var item in data)
              [item['id'].toString(), item['name'], item['price'].toString()],
          ],
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/example.pdf");
    await file.writeAsBytes(await pdf.save());
  }
}

void main() {
  runApp(MyApp());
}
