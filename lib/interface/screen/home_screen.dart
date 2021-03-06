import 'dart:math';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

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
                    },
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
                      for (int index = 0; index < int.parse(quantityController.text); index++) labels.add(priceController.text);

                      priceController.clear();
                      quantityController.clear();

                      setState(() {});
                    }
                  },
                ),
                RaisedButton(child: Text("Salva"),
                onPressed: () async {
                  pw.Document finale = await renderDocument();

                  var directory = await getApplicationDocumentsDirectory();


                  File finaleFile = File(directory.path + "/result.pdf");
                  finaleFile.writeAsBytes(finale.save());
                  debugPrint("Salvato su file.");
                

                  // labels = List<String>();
                },),
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
      bytes: (await rootBundle.load("assets/logo.jpg")).buffer.asUint8List(),
    );
    pw.Font arial = pw.Font.ttf(await rootBundle.load("assets/Arial-Regular.ttf"));

    labels.forEach(
      (String label) => renderedLabels.add(
        pw.Container(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: <pw.Widget>[
                pw.Expanded(flex: 6, child: pw.Image(logo, fit: pw.BoxFit.contain)),
                pw.Expanded(
                  flex: 9,
                  child: pw.Row(
                    mainAxisSize: pw.MainAxisSize.max,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: <pw.Widget>[
                      pw.VerticalDivider(color: PdfColors.white, width: 8.0),
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.max,
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: <pw.Widget>[
                          pw.Text("€", style: pw.TextStyle(font: arial, fontSize: 16.0)),
                          pw.Text(double.parse(label).toStringAsFixed(2).replaceAll(".", ","),
                              style: pw.TextStyle(font: arial, fontSize: 16.0, decoration: pw.TextDecoration.underline)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ),
      ),
    );

    for (int index = 0; index < neededPages; index++) {
      debugPrint(index.toString());
      // Questo è l'ultimo giro.
      if (index == neededPages - 1) {
        debugPrint("Siamo all\'ultimo foglio.");

        List<pw.Widget> widgets = renderedLabels.getRange(44 * index, labels.length).toList();
        for (int i = labels.length; i < (44 * (index + 1)); i++) widgets.add(pw.Container());

        pages.add(pw.Page(pageTheme: pw.PageTheme(margin: pw.EdgeInsets.all(16.0)),build: (pw.Context context) => pw.GridView(crossAxisSpacing: 4.0,mainAxisSpacing: 4.0,childAspectRatio: 2, crossAxisCount: 4, children: widgets)));
        continue;
      }
      pages.add(pw.Page(pageTheme: pw.PageTheme(margin: pw.EdgeInsets.all(16.0)),
          build: (pw.Context context) =>
              pw.GridView(childAspectRatio: 2, crossAxisCount: 4, children: renderedLabels.getRange(44 * index, 44 * (index + 1)).toList())));
    }
    pages.forEach((pw.Page page) => pdfDocument.addPage(page));

    debugPrint("Ecco il pdf renderizzato.");
    return pdfDocument;
  }

  Future<Uint8List> pdfDocumentToUint8List(pw.Document pdfDocumentToBeTranslated) async {
    if (pdfDocumentToBeTranslated.document.pdfPageList.pages.isEmpty) {
      debugPrint("Essendo che il documento è vuoto, lo riempio con una pagina di placeholder.");
      pdfDocumentToBeTranslated.addPage(pw.Page(build: (pw.Context context) => pw.Center(child: pw.Text("Ciao!"))));
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
