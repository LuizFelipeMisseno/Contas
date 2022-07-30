import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contas/components/app_fonts.dart';
import 'package:contas/database/firebase_services.dart';
import 'package:contas/database/transation_info.dart';
import 'package:contas/homepage/components/homepage_calendar.dart';
import 'package:contas/new_transations/components/calendar.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';

class NewTransactions extends StatefulWidget {
  const NewTransactions({Key? key}) : super(key: key);

  @override
  State<NewTransactions> createState() => _NewTransactionsState();
}

class _NewTransactionsState extends State<NewTransactions> {
  final formKey = GlobalKey<FormState>();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();
  final descriminationOMController = TextEditingController();
  final descriminationCLController = TextEditingController();
  String occurrence = 'entrada';
  List<BoxShadow> standardShadow = [
    const BoxShadow(
      color: Colors.black38,
      blurRadius: 3,
      offset: Offset(3, 4),
    ),
  ];
  final monthFormat = MaskTextInputFormatter(
    mask: '##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );
  bool isLoading = false;
  String? dropdownValue;

  @override
  Widget build(BuildContext context) {
    HomePageDatePicker datePicker = Provider.of<HomePageDatePicker>(context);

    return SafeArea(
      child: Scaffold(
        body: Form(
          key: formKey,
          child: Container(
            margin: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  header(),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: changeTransactionType(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: body(datePicker),
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            if (descriptionController.text == 'Transferência via PIX') {
              askForDescrimination(datePicker, priceController.text);
            } else {
              setState(() {
                isLoading = true;
              });
              FirebaseManagement().addTransiction(
                Conta(
                    data: Timestamp.fromDate(datePicker.dateTime),
                    description: descriptionController.text,
                    price: double.parse(
                      priceController.text.substring(2).replaceAll(',', ''),
                    ),
                    occurrence: occurrence),
                datePicker.dateTime,
              );
              Navigator.pop(context);
            }
          },
          backgroundColor: const Color.fromARGB(255, 143, 255, 126),
          label: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Text(
                      'Confirmar Transação',
                      style: AppFonts.normal,
                      //overflow: TextOverflow,
                    ),
                  ),
                ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  header() {
    return Text(
      'Nova Transação',
      style: AppFonts.title,
    );
  }

  changeTransactionType() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              occurrence = 'entrada';
            });
          },
          child: Container(
            child: Text('Entrada',
                style: occurrence == 'entrada'
                    ? AppFonts.optionsSelected
                    : AppFonts.optionsUnselected),
            decoration: occurrence == 'entrada'
                ? const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.black, width: 2),
                    ),
                  )
                : null,
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              occurrence = 'saida';
            });
          },
          child: Container(
            child: Text('Saída',
                style: occurrence == 'saida'
                    ? AppFonts.optionsSelected
                    : AppFonts.optionsUnselected),
            decoration: occurrence == 'saida'
                ? const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.black, width: 2),
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  body(HomePageDatePicker datePicker) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              'Valor:',
              style: AppFonts.normal,
            ),
            priceTextField(),
          ],
        ),
        const SizedBox(height: 40),
        Row(
          children: [
            Text(
              'Data:',
              style: AppFonts.normal,
            ),
            data(datePicker),
          ],
        ),
        const SizedBox(height: 40),
        options(),
        const SizedBox(height: 40),
        description(),
        const SizedBox(height: 40),
      ],
    );
  }

  priceTextField() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: TextFormField(
          style: AppFonts.textField,
          controller: priceController,
          inputFormatters: [
            CurrencyTextInputFormatter(
              //locale: 'br',
              symbol: 'R\$',
            )
          ],
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            fillColor: Colors.grey.shade400,
            filled: true,
            hintText: 'R\$',
            contentPadding: const EdgeInsets.fromLTRB(15, 5, 10, 5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.0),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
            if (value!.isEmpty) {
              return 'Informe um valor';
            }
            return null;
          },
        ),
      ),
    );
  }

  data(HomePageDatePicker datePicker) {
    print(datePicker.dateTime);
    return GestureDetector(
      onTap: () {
        datePicker.showCalendar(context);
      },
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              datePicker.showCalendar(context);
            },
            icon: const Icon(Icons.calendar_today),
          ),
          Consumer<DatePicker>(
            builder: ((context, selectedDay, child) {
              return Text(
                DateFormat('dd/MM/yyyy').format(datePicker.dateTime).toString(),
              );
            }),
          ),
        ],
      ),
    );
  }

  description() {
    return Column(
      children: [
        Row(
          children: [
            Text(
              'Descrição da Movimentação:',
              style: AppFonts.normal,
            ),
          ],
        ),
        const SizedBox(height: 20),
        descriptionTextField(),
      ],
    );
  }

  descriptionTextField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: TextFormField(
        style: AppFonts.textField,
        controller: descriptionController,
        maxLines: 3,
        decoration: InputDecoration(
          fillColor: Colors.grey.shade400,
          filled: true,
          contentPadding: const EdgeInsets.fromLTRB(30, 10, 10, 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (value) {
          if (value!.isEmpty) {
            return 'Informe a descrição da transação';
          }
          return null;
        },
      ),
    );
  }

  options() {
    return SizedBox(
      width: double.infinity,
      child: DropdownButton<String>(
        hint: const Text('Escolha uma opção'),
        value: dropdownValue,
        isExpanded: true,
        icon: const Icon(Icons.arrow_drop_down),
        elevation: 16,
        style: const TextStyle(color: Colors.deepPurple),
        underline: Container(
          height: 2,
          color: Colors.deepPurpleAccent,
        ),
        onChanged: (String? newValue) {
          setState(() {
            dropdownValue = newValue!;
          });
          descriptionController.text = newValue!;
        },
        items: <String>[
          'Donativos Congregação Caixa',
          'Donativos Obra Mundial Caixa',
          'Transferência via PIX',
          'Transferência Associação Torre de Vigia',
          'Depósito na conta'
        ].map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  }

  askForDescrimination(HomePageDatePicker datePicker, String totalValue) {
    double value = double.parse(totalValue.replaceAll("R\$", ""));
    value = value / 2;
    log(value.toString());
    showDialog(
      context: context,
      builder: (BuildContext context) {
        descriminationCLController.text = "R\$$value";
        descriminationOMController.text = "R\$$value";

        return SizedBox(
          height: 150,
          width: 150,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Text(
                        'Obra Mundial:',
                        style: AppFonts.normal,
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        style: AppFonts.textField,
                        controller: descriminationOMController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          CurrencyTextInputFormatter(
                            //locale: 'br',
                            symbol: 'R\$',
                          )
                        ],
                        decoration: InputDecoration(
                          fillColor: Colors.grey.shade400,
                          filled: true,
                          hintText: 'R\$',
                          contentPadding:
                              const EdgeInsets.fromLTRB(15, 5, 10, 5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Informe um valor';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Text(
                        'Congregação Local:',
                        style: AppFonts.normal,
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        style: AppFonts.textField,
                        controller: descriminationCLController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          CurrencyTextInputFormatter(
                            //locale: 'br',
                            symbol: 'R\$',
                          )
                        ],
                        decoration: InputDecoration(
                          fillColor: Colors.grey.shade400,
                          filled: true,
                          hintText: 'R\$',
                          contentPadding:
                              const EdgeInsets.fromLTRB(15, 5, 10, 5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Informe um valor';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                )
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    isLoading = false;
                  });
                },
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  saveTransference(datePicker);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Confirmar'),
              ),
            ],
          ),
        );
      },
    );
  }

  saveTransference(HomePageDatePicker datePicker) {
    FirebaseManagement().addTransiction(
      Conta(
          data: Timestamp.fromDate(datePicker.dateTime),
          description: 'Transferência via PIX',
          price: double.parse(
            priceController.text.substring(2).replaceAll(',', ''),
          ),
          occurrence: 'entrada'),
      datePicker.dateTime,
    );
    Timer(
      const Duration(milliseconds: 300),
      () {
        if (descriminationCLController.text.isNotEmpty &&
            descriminationCLController.text != 'R\$0.00') {
          saveCL(datePicker);
        }
        if (descriminationOMController.text.isNotEmpty &&
            descriminationOMController.text != 'R\$0.00') {
          saveOM(datePicker);
        }
      },
    );
  }

  saveOM(HomePageDatePicker datePicker) {
    FirebaseManagement().addTransiction(
      Conta(
          data: Timestamp.fromDate(datePicker.dateTime),
          description: 'Donativos Obra Mundial PIX',
          price: double.parse(
            descriminationOMController.text.substring(2).replaceAll(',', ''),
          ),
          occurrence: 'entrada'),
      datePicker.dateTime,
    );
  }

  saveCL(HomePageDatePicker datePicker) {
    FirebaseManagement().addTransiction(
      Conta(
          data: Timestamp.fromDate(datePicker.dateTime),
          description: 'Donativos Congregação Local PIX',
          price: double.parse(
            descriminationCLController.text.substring(2).replaceAll(',', ''),
          ),
          occurrence: 'entrada'),
      datePicker.dateTime,
    );
  }
}
