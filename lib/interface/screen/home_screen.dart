import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdfwidgets;
import 'package:printing/printing.dart';

class HomeScreen extends StatefulWidget {
  static const String route = "/homeScreen";

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController textController;

  pdfwidgets.Document pdfDocument;
  pdfwidgets.Page currentPage;
  List<pdfwidgets.Widget> currentPageLabels;

  @override
  void initState() {
    debugPrint("Inizializzo tutto.");

    textController = TextEditingController();
    pdfDocument = pdfwidgets.Document();

    // Inizializza la prima pagina.
    pdfDocument.addPage(pdfwidgets.Page(pageFormat: PdfPageFormat.a4, build: (pdfwidgets.Context context) => pdfwidgets.Container()));
    currentPageLabels = List<pdfwidgets.Widget>();

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
                  /*child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                    ),
                  ),*/
                  child: PdfPreview(
                            initialPageFormat: PdfPageFormat.a4,
                            canChangePageFormat: false,
                            build: (PdfPageFormat format) => getPdfFile(pdfDocument),
                          ),
                ),
              ),
              Text("Preview", style: Theme.of(context).textTheme.caption),
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
                      onPressed: () {
                        debugPrint("Aggiunto un elemento: ${textController.text}.");

                        // pdfDocument.document.pdfPageList.pages.removeLast();

                        pdfDocument.addPage(pdfwidgets.Page(
                            pageFormat: PdfPageFormat.a4,
                            build: (pdfwidgets.Context context) {
                            return pdfwidgets.GridView(crossAxisCount: 4, children: <pdfwidgets.Widget>[pdfwidgets.Text("Ciao"), pdfwidgets.Text("Cia"),]);
                            }));

                               pdfDocument.addPage(pdfwidgets.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pdfwidgets.Context context) {
        return pdfwidgets.Center(
          child: pdfwidgets.Text("Hello World"),
        );
      })); 

                        debugPrint("Il documento ha " + pdfDocument.document.pdfPageList.pages.length.toString() + " pagine.");


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

  Future<Uint8List> getPdfFile(pdfwidgets.Document pdfDocument) async {
    if(pdfDocument.document.pdfPageList.pages.isEmpty) {
      debugPrint("Essendo che il documento è vuoto, lo riempio con una pagina di placeholder.");
      pdfDocument.addPage(pdfwidgets.Page(build: (pdfwidgets.Context context) =>pdfwidgets.Center(child: pdfwidgets.Text("Ciao!"))));
    }

    Uint8List rawPdfFile = pdfDocument.save();

    debugPrint("Restituisco il PDF renderizzato.");
    debugPrint(rawPdfFile.lengthInBytes.toString());

    return rawPdfFile;
  }
}
