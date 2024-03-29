import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contas/database/transation_info.dart';
import 'package:contas/homepage/components/homepage_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

ValueNotifier<bool> creatingPDF = ValueNotifier<bool>(false);

createPDF(CollectionReference services, selectedMonth, datePicker) async {
  creatingPDF.value = true;
  PdfDocument document = PdfDocument(
      inputBytes: (await rootBundle.load('assets/pdf/folha_de_contas.pdf'))
          .buffer
          .asUint8List());
  PdfStandardFont headerFont = PdfStandardFont(PdfFontFamily.timesRoman, 17);
  PdfStandardFont bodyFont = PdfStandardFont(PdfFontFamily.timesRoman, 11);
  List<dynamic> contas = await createList(services, selectedMonth);

//Get the form.
  PdfForm form = document.form;

//Nome da congregação
  PdfTextBoxField congregationName = form.fields[0] as PdfTextBoxField;
  congregationName.text = 'Santo Hilário - 107599';
  congregationName.font = headerFont;

//Cidade
  PdfTextBoxField city = form.fields[4] as PdfTextBoxField;
  city.text = 'Goiânia';
  city.font = headerFont;

//Estado
  PdfTextBoxField state = form.fields[8] as PdfTextBoxField;
  state.text = 'GO';
  state.font = headerFont;

//Mês
  PdfTextBoxField month = form.fields[12] as PdfTextBoxField;
  month.text = toBeginningOfSentenceCase(
    DateFormat.MMMM('pt br').format(datePicker.dateTime),
  )!;
  month.font = headerFont;

//Ano
  PdfTextBoxField year = form.fields[16] as PdfTextBoxField;
  year.text = datePicker.dateTime.year.toString();
  year.font = headerFont;

//52 linhas no fomrulário
//534 forms

//Save and dispose the document.
  var status = await Permission.storage.status;
  if (status.isDenied) {
    Permission.storage.request();
  } else if (status.isGranted) {
    contas.sort(
      ((a, b) {
        var aDate = a['data'].toDate().day;
        var bDate = b['data'].toDate().day;
        return aDate.compareTo(bDate);
      }),
    );

    //Passando data para folha

    int dataIndex = 23;
    int o = 0;
    while (o < contas.length && dataIndex < 227) {
      PdfTextBoxField data = form.fields[dataIndex] as PdfTextBoxField;
      data.text = contas.elementAt(o)['data'].toDate().day.toString();
      data.font = bodyFont;
      dataIndex = dataIndex + 4;
      o++;
    }

    //Passando descrição para folha

    int descriptionIndex = 231;
    o = 0;
    while (o < contas.length && descriptionIndex < 426) {
      PdfTextBoxField description =
          form.fields[descriptionIndex] as PdfTextBoxField;
      String noSpecialCharacteres = contas
          .elementAt(o)['descricao']
          .toString()
          .replaceAll(RegExp('[^A-Za-z0-9 ãõâéàáçÇêó]'), '');
      description.text = noSpecialCharacteres;
      description.font = bodyFont;
      descriptionIndex = descriptionIndex + 4;
      o++;
    }

    //Passando S para folha

    int sIndex = 427;
    o = 0;
    while (o < contas.length && sIndex < 478) {
      PdfTextBoxField sTextBox = form.fields[sIndex] as PdfTextBoxField;
      sTextBox.text =
          contas.elementAt(o)['descricao'].contains('Donativos - Congregação')
              ? 'C'
              : contas
                      .elementAt(o)['descricao']
                      .contains('Donativos - Obra Mundial')
                  ? 'O'
                  : contas.elementAt(o)['descricao'].contains('Transferência')
                      ? 'T'
                      : contas.elementAt(o)['descricao'].contains('Depósito')
                          ? 'D'
                          : '';
      sIndex = sIndex + 1;
      o++;
    }

    //Passando valor para a folha

    int valueIndex = 1;
    int value2Index = 2;
    o = 0;
    final currency = NumberFormat("####0.00");
    while (o < contas.length && valueIndex < 426) {
      if (contas.elementAt(o)['ocorrencia'] == 'entrada' &&
          contas.elementAt(o)['descricao'] != 'Transferência via PIX' &&
          contas.elementAt(o)['descricao'] != 'Depósito na conta') {
        if (o >= 5) {
          valueIndex = 20 + ((o - 5) * (4));
        } else {
          valueIndex = 1 + (o * 4);
        }
        PdfTextBoxField value = form.fields[valueIndex] as PdfTextBoxField;
        value.text = currency.format(contas.elementAt(o)['valor']);
        value.font = bodyFont;
      } else if (contas.elementAt(o)['ocorrencia'] == 'saida') {
        valueIndex = 213 + (o * 4);
        PdfTextBoxField value = form.fields[valueIndex] as PdfTextBoxField;
        value.text = currency.format(contas.elementAt(o)['valor']);
        value.font = bodyFont;
      }

      if (contas.elementAt(o)['descricao'] == 'Depósito na conta' ||
          contas.elementAt(o)['descricao'] == 'Transferência via PIX') {
        if (o < 4) {
          value2Index = 2 + (o * 4);
        } else if (o == 4) {
          value2Index = 18;
        } else if (o == 5) {
          value2Index = 21;
        } else if (o > 5) {
          value2Index = 25 + ((o - 6) * 4);
        }

        PdfTextBoxField value2 = form.fields[value2Index] as PdfTextBoxField;
        value2.text = currency.format(contas.elementAt(o)['valor']);
        value2.font = bodyFont;
      } else if (contas.elementAt(o)['descricao'].contains('Donativo')) {
        value2Index = 212 + (o * 4);
        PdfTextBoxField value2 = form.fields[value2Index] as PdfTextBoxField;
        value2.text = currency.format(contas.elementAt(o)['valor']);
        value2.font = bodyFont;
      }
      o++;
    }

    saveInStorage(document, datePicker);
  }
}

Future<List> createList(CollectionReference services, month) async {
  List listaInicial = [];
  List listaFinal = [];
  QuerySnapshot<Object?> list = await services.get();

  listaInicial = list.docs
      .map((doc) => doc)
      .where((element) => element.id == month)
      .toList();

  for (var element in listaInicial) {
    for (var transaction in element['contas']) {
      listaFinal.add(transaction);
    }
  }

  return listaFinal;
}

Future saveInStorage(document, datePicker) async {
  final directory =
      (await getExternalStorageDirectories(type: StorageDirectory.downloads))!
          .first;
  final String month = toBeginningOfSentenceCase(
    DateFormat.MMMM('pt br').format(datePicker.dateTime),
  )!;
  File file2 = File("${directory.path}/$month.pdf");
  //await file2.writeAsString('TEST ONE');

  file2.writeAsBytesSync(document.save());
  document.dispose();
  await FlutterShare.shareFile(
    title: 'Example share',
    text: 'Example share text',
    filePath: "${directory.path}/$month.pdf",
  );
  creatingPDF.value = false;

  print(directory.path);
}
