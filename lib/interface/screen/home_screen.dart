import 'dart:io';
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
  pdfwidgets.Document pdf;
  File pdfFile;

  @override
  void initState() {
    textController = TextEditingController();
    pdf = pdfwidgets.Document();

    pdf.addPage(pdfwidgets.Page(
                            pageFormat: PdfPageFormat.a4,
                            build: (pdfwidgets.Context context) => pdfwidgets.Container()
                          ));

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
                  child: FutureBuilder<Uint8List>(
                      future: getPdfFile(),
                      builder: (BuildContext context, AsyncSnapshot<Uint8List> pdfSnapshot) {
                        if (pdfSnapshot.hasData) return PdfPreview(build: (PdfPageFormat format) => pdfSnapshot.data);

                        return Center(child: CircularProgressIndicator());
                      }),
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
                        textController.clear();

                        pdf.addPage(pdfwidgets.Page(
                            pageFormat: PdfPageFormat.a4,
                            build: (pdfwidgets.Context context) {
                              return pdfwidgets.Center(
                                child: pdfwidgets.Text("Hello World"),
                              ); // Center
                            }));

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

  Future<Uint8List> getPdfFile() async {
    Uint8List pdfDocument = pdf.save();

    debugPrint("Restituisco il PDF renderizzato.");
    return pdfDocument;
  }
}
