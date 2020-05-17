import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class HomeScreen extends StatefulWidget {
  static const String route = "/homeScreen";

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController textController;

  pw.Document pdfDocument;
  List<pw.Widget> currentPageLabels;

  /*final image = PdfImage.file(
  pdf.document,
  bytes: File('test.webp').readAsBytesSync(),
);*/

  static pw.Font arial;
  
  List<pw.Page> pages;

  @override
  void initState() {
    debugPrint("Inizializzo tutto.");

    textController = TextEditingController();
    pdfDocument = pw.Document();

    currentPageLabels = List<pw.Widget>();
    pages = List<pw.Page>();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Creatore etichette Prezzi - Hi-Tec"),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    pdfDocument = pw.Document();
    pages.forEach((pw.Page page) =>pdfDocument.addPage(page));

    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1 / sqrt2,
                  child: PdfPreview(
                    initialPageFormat: PdfPageFormat.a4,
                    canChangePageFormat: false,
                    build: (PdfPageFormat format) => pdfDocumentToUint8List(pdfDocument),
                  ),
                ),
              ),
              Text("Preview del documento", style: Theme.of(context).textTheme.caption),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 16.0),
            child: ListView(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: TextField(
                      controller: textController,
                    )),
                    VerticalDivider(color: Colors.transparent),
                    RaisedButton(
                      child: Text("Aggiungi"),
                      onPressed: () async {
                        if (arial == null) {
                          debugPrint("Inizializzo il font.");

                          arial = pw.Font.ttf(await rootBundle.load("assets/Arial-Regular.ttf"));
                        }

                        String text = textController.text;
                        debugPrint("Aggiunto un elemento: $text.");

                        pages.add(pw.Page(build: (pw.Context context) => pw.Center(child: pw.Text(text))));

                        textController.clear();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<Uint8List> pdfDocumentToUint8List(pw.Document pdfDocumentToBeTranslated) async {
    if (pdfDocumentToBeTranslated.document.pdfPageList.pages.isEmpty) {
      debugPrint("Essendo che il documento è vuoto, lo riempio con una pagina di placeholder.");
      pdfDocumentToBeTranslated.addPage(pw.Page(build: (pw.Context context) => pw.Center(child: pw.Text("Ciao!", style: pw.TextStyle(font: arial)))));
    }

    Uint8List rawPdfFile = pdfDocumentToBeTranslated.save();

    debugPrint("Restituisco il PDF renderizzato.");
    return rawPdfFile;
  }
}
