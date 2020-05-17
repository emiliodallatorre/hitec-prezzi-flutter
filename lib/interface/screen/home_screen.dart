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

  /*final image = PdfImage.file(
  pdf.document,
  bytes: File('test.webp').readAsBytesSync(),
);*/

  static pw.Font arial;

  int currentPage;
  int currentLabel;

  List<pw.Page> pages;
  List<String> labels;

  GlobalKey<FormState> formKey;
  TextEditingController priceController;
  TextEditingController quantityController;

  @override
  void initState() {
    debugPrint("Inizializzo tutto.");

    labels = List<String>();
    pages = List<pw.Page>();

    formKey = GlobalKey<FormState>();
    priceController = TextEditingController();
    quantityController = TextEditingController();

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
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1 / sqrt2,
                  child: FutureBuilder<pw.Document>(
                      future: renderDocument(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData)
                          return PdfPreview(
                            initialPageFormat: PdfPageFormat.a4,
                            canChangePageFormat: false,
                            build: (PdfPageFormat format) => snapshot.data.save(),
                          );

                        return Center(child: CircularProgressIndicator());
                      }),
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
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        validator: doubleValidator,
                        controller: priceController,
                        decoration: InputDecoration(labelText: "Prezzo", prefixText: "€"),
                      ),
                      TextFormField(
                        validator: intValidator,
                        controller: quantityController,
                        decoration: InputDecoration(labelText: "Quantità"),
                      ),
                    ],
                  ),
                ),
                RaisedButton(
                  child: Text("Aggiungi"),
                  onPressed: () async {
                    if (formKey.currentState.validate()) {
                      if (arial == null) {
                        debugPrint("Inizializzo il font.");
                        arial = pw.Font.ttf(await rootBundle.load("assets/Arial-Regular.ttf"));
                      }

                      for (int index = 0; index < int.parse(quantityController.text); index++) labels.add(priceController.text);

                      priceController.clear();
                      quantityController.clear();

                      setState(() {});
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<pw.Document> renderDocument() async {
    // Restituisce un placeholder vuoto.
    if (labels.isEmpty) {
      pw.Document pdfDocument = pw.Document();
      pdfDocument.addPage(pw.Page());

      return pdfDocument;
    }

    int neededPages = (labels.length / 44).ceil();
    debugPrint("Serviranno $neededPages pagine.");
    List<pw.Page> pages = List<pw.Page>();

    pw.Document pdfDocument = pw.Document();
    List<pw.Widget> renderedLabels = List<pw.Widget>();
    PdfImage logo = PdfImage.file(
      pdfDocument.document,
      bytes: (await rootBundle.load("assets/Arial-Regular.ttf")).buffer.asUint8List(),
    );
    labels.forEach(
      (String label) => renderedLabels.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: <pw.Widget>[
            pw.Image(logo),
            pw.Text(label),
          ],
        ),
      ),
    );

    for (int index = 0; index < neededPages; index++) {
      debugPrint(index.toString());
      // Questo è l'ultimo giro.
      if (index == neededPages - 1) {
        debugPrint("Siamo all\'ultimo foglio.");
        pages.add(pw.Page(
            build: (pw.Context context) =>
                pw.GridView(childAspectRatio: 2, crossAxisCount: 4, children: renderedLabels.getRange(44 * index, labels.length).toList())));
        continue;
      }
      pages.add(pw.Page(
          build: (pw.Context context) =>
              pw.GridView(childAspectRatio: 2, crossAxisCount: 4, children: renderedLabels.getRange(44 * index, 44 * (index + 1)).toList())));
    }
    pages.forEach((pw.Page page) => pdfDocument.addPage(page));

    return pdfDocument;
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

  static String doubleValidator(String text) {
    try {
      double.parse(text);
      return null;
    } catch (e) {
      return "Inserisci un numero valido, separa i decimali con \".\"!";
    }
  }

  static String intValidator(String text) {
    try {
      int.parse(text);
      return null;
    } catch (e) {
      return "Inserisci un numero valido!";
    }
  }
}
