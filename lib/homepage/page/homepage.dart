import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:contas/homepage/components/create_pdf.dart';
import 'package:contas/new_transations/components/calendar.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contas/components/app_fonts.dart';
import 'package:contas/homepage/components/homepage_calendar.dart';
import 'package:contas/homepage/components/card.dart';
import 'package:contas/new_transations/page/new_transaction.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final currency = NumberFormat("R\$ #,##0.00", "pt_BR");
  String selectedView = 'tudo';
  String selectedRange = 'mes';

  @override
  Widget build(BuildContext context) {
    //double screenHeight = MediaQuery.of(context).size.height;
    HomePageDatePicker datePicker = Provider.of<HomePageDatePicker>(context);
    String month = DateFormat.MMMM('pt br').format(datePicker.dateTime);
    CollectionReference services = FirebaseFirestore.instance
        .collection(datePicker.dateTime.year.toString());

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        body: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(20),
            child: Column(
              children: [
                header(datePicker, services, month),
                total(month, services),
                const SizedBox(height: 20),
                const Divider(
                  thickness: 3.0,
                  height: 10,
                ),
                const SizedBox(height: 20),
                body(month, datePicker, services),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NewTransactions(),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  header(datePicker, services, month) {
    return Column(
      children: [
        Align(
          child: Text(
            'Contas da Congregação',
            style: AppFonts.title,
          ),
          alignment: Alignment.center,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  datePicker.showYearCalendar(context);
                },
                child: Text(
                  'Ano: ' + datePicker.dateTime.year.toString(),
                  style: AppFonts.subtitle,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      datePicker.showCalendar(context);
                    },
                    icon: const Icon(Icons.calendar_today),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: creatingPDF,
                    builder: (context, loading, _) {
                      return IconButton(
                        onPressed: () {
                          createPDF(services, month, datePicker);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Criando PDF...'),
                            ),
                          );
                        },
                        icon: loading
                            ? const Padding(
                                padding: EdgeInsets.all(5),
                                child: CircularProgressIndicator(),
                              )
                            : const Icon(
                                Icons.file_copy,
                              ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  total(month, services) {
    return StreamBuilder(
      stream: services.snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 80),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                //Ver tudo
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedView = 'tudo';
                    });
                  },
                  child: Container(
                    child: Text('Todas',
                        style: selectedView == 'tudo'
                            ? AppFonts.optionsSelected
                            : AppFonts.optionsUnselected),
                    decoration: selectedView == 'tudo'
                        ? const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.black, width: 2),
                            ),
                          )
                        : null,
                  ),
                ),
                //Ver entradas
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedView = 'entradas';
                    });
                  },
                  child: Container(
                    child: Text('Entradas',
                        style: selectedView == 'entradas'
                            ? AppFonts.optionsSelected
                            : AppFonts.optionsUnselected),
                    decoration: selectedView == 'entradas'
                        ? const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.black, width: 2),
                            ),
                          )
                        : null,
                  ),
                ),
                //Ver saídas
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedView = 'saidas';
                    });
                  },
                  child: Container(
                    child: Text('Saídas',
                        style: selectedView == 'saidas'
                            ? AppFonts.optionsSelected
                            : AppFonts.optionsUnselected),
                    decoration: selectedView == 'saidas'
                        ? const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.black, width: 2),
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
          //Espaçamento
          const SizedBox(height: 20),
          const Divider(
            thickness: 3.0,
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: createList(snapshot, month).isNotEmpty
                ? Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          selectedRange == 'mes'
                              ? 'Total do mês:'
                              : 'Total do dia:',
                          style: AppFonts.subtitle,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              selectedView == 'saidas'
                                  ? Text(
                                      'Entradas:  Indisponível',
                                      style: AppFonts.normal,
                                    )
                                  : Text(
                                      'Entradas:  ' +
                                          currency.format(
                                            getEntrada(snapshot, month),
                                          ),
                                      style: AppFonts.normal,
                                    ),
                              selectedView == 'entradas'
                                  ? Text(
                                      'Saídas:  Indisponível',
                                      style: AppFonts.normal,
                                    )
                                  : Text(
                                      'Saídas:  ' +
                                          currency.format(
                                            getSaida(snapshot, month),
                                          ),
                                      style: AppFonts.normal,
                                    ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  "Obra mundial: " +
                                      currency.format(
                                        getObraMundial(snapshot, month),
                                      ),
                                  style: AppFonts.normal),
                              selectedView == 'tudo'
                                  ? Text(
                                      selectedRange == 'mes'
                                          ? 'Saldo:  ' +
                                              currency.format(
                                                getSaldo(
                                                  getEntrada(snapshot, month),
                                                  getSaida(snapshot, month),
                                                ),
                                              )
                                          : 'Saldo final do dia:  ' +
                                              currency.format(
                                                getSaldo(
                                                  getEntrada(snapshot, month),
                                                  getSaida(snapshot, month),
                                                ),
                                              ),
                                      style: AppFonts.normal,
                                    )
                                  : Container(),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  )
                : Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Entradas:  ...',
                            style: AppFonts.normal,
                          ),
                          Text(
                            'Saídas:  ...',
                            style: AppFonts.normal,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text(
                            'Saldo da conta: ...',
                            style: AppFonts.normal,
                          ),
                        ],
                      )
                    ],
                  ),
          )
        ],
      ),
    );
  }

  body(month, HomePageDatePicker datePicker, services) {
    return Column(
      children: [
        //Ver tudo
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  selectedRange = 'mes';
                });
              },
              child: Container(
                child: Text('Mês',
                    style: selectedRange == 'mes'
                        ? AppFonts.optionsSelected
                        : AppFonts.optionsUnselected),
                decoration: selectedRange == 'mes'
                    ? const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.black, width: 2),
                        ),
                      )
                    : null,
              ),
            ),
            //Ver entradas
            GestureDetector(
              onTap: () {
                setState(() {
                  selectedRange = 'dia';
                });
              },
              child: Container(
                child: Text('Dia',
                    style: selectedRange == 'dia'
                        ? AppFonts.optionsSelected
                        : AppFonts.optionsUnselected),
                decoration: selectedRange == 'dia'
                    ? const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.black, width: 2),
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
        //Espaçamento
        const SizedBox(height: 20),
        selectedRange == 'dia'
            ? GestureDetector(
                onTap: () {
                  datePicker.showCalendar(context);
                },
                child: Text(
                  DateFormat('dd').format(datePicker.dateTime).toString() +
                      '/' +
                      DateFormat('MM').format(datePicker.dateTime).toString(),
                  style: AppFonts.subtitle,
                ),
              )
            : GestureDetector(
                onTap: () {
                  monthPicker(datePicker);
                },
                child: Text(
                  toBeginningOfSentenceCase(
                    DateFormat.MMMM('pt br').format(datePicker.dateTime),
                  )!,
                  style: AppFonts.subtitle,
                ),
              ),
        const SizedBox(height: 20),
        StreamBuilder(
          stream: services.snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (createList(snapshot, month).isNotEmpty) {
              return ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                shrinkWrap: true,
                itemCount: createList(snapshot, month).length,
                itemBuilder: (context, index) {
                  return CardTransacao(
                    snapshot: createList(snapshot, month).elementAt(index),
                  );
                },
              );
            }
            return Center(
              child: Text(
                selectedRange == 'mes'
                    ? 'Não há transações nesse mês'
                    : 'Não há transações nesse dia',
                style: AppFonts.optionsUnselected,
              ),
            );
          },
        ),
      ],
    );
  }

  List<dynamic> createList(
      AsyncSnapshot<QuerySnapshot<Object?>> snapshot, month) {
    HomePageDatePicker datePicker = Provider.of<HomePageDatePicker>(context);
    List listaInicial = [];
    List listaIntermediaria = [];
    List listaFinal = [];
    if (snapshot.hasData) {
      //Pega todas as transações do mês selecionado
      for (var element
          in snapshot.data!.docs.where((element) => element.id == month)) {
        listaInicial.add(element['contas']);
      }
      //Se for especificado um dia, separa somente as transações do dia
      if (selectedRange == 'dia') {
        for (var element in listaInicial) {
          for (var e in element) {
            if (e['data'].toDate().day == datePicker.dateTime.day) {
              listaIntermediaria.add(e);
            }
          }

          for (var e in listaIntermediaria) {
            //Cria a lista final com entradas e saídas
            if (selectedView == 'tudo') {
              listaFinal.add(e);
            }
            //Se especificado, separa somente as entradas
            else if (selectedView == 'entradas') {
              if (e['ocorrencia'] == 'entrada') {
                listaFinal.add(e);
              }
            }
            //Se especificado, separa somente as saídas
            else if (selectedView == 'saidas') {
              if (e['ocorrencia'] == 'saida') {
                listaFinal.add(e);
              }
            }
          }
          listaFinal.sort((a, b) => a["data"].compareTo(b["data"]));
          return listaFinal;
        }
      }
      for (var element in listaInicial) {
        for (var e in element) {
          //Cria a lista final com entradas e saídas
          if (selectedView == 'tudo') {
            listaFinal.add(e);
          }
          //Se especificado, separa somente as entradas
          else if (selectedView == 'entradas') {
            if (e['ocorrencia'] == 'entrada') {
              listaFinal.add(e);
            }
          }
          //Se especificado, separa somente as saídas
          else if (selectedView == 'saidas') {
            if (e['ocorrencia'] == 'saida') {
              listaFinal.add(e);
            }
          }
        }
      }
    }
    listaFinal.sort((a, b) => a["data"].compareTo(b["data"]));
    return listaFinal;
  }

  getEntrada(AsyncSnapshot<QuerySnapshot<Object?>> snapshot, month) {
    List entrada = [];
    dynamic total = 0;
    createList(snapshot, month).forEach(
      (element) {
        if (element['ocorrencia'] == 'entrada') {
          if (element['descricao'] != 'Transferência via PIX') {
            if (element["descricao"].contains("Depósito") == false) {
              total += element['valor'];
            }
          }
        }
      },
    );

    return total;
  }

  getSaida(AsyncSnapshot<QuerySnapshot<Object?>> snapshot, month) {
    List saida = [];
    dynamic total = 0;
    createList(snapshot, month).forEach((element) {
      if (element['ocorrencia'] == 'saida') {
        saida.add(element['valor']);
      }
    });
    if (saida.isNotEmpty) {
      total = saida.reduce((total, valor) => total + valor);
    }
    return total;
  }

  getSaldo(entrada, saida) {
    var total = entrada - saida;
    return total;
  }

  getObraMundial(AsyncSnapshot<QuerySnapshot<Object?>> snapshot, month) {
    dynamic total = 0;
    createList(snapshot, month).forEach((element) {
      if (element['descricao'].contains('Obra Mundial')) {
        total += element['valor'];
      }
    });
    return total;
  }

  monthPicker(datePicker) {
    int year = datePicker.dateTime.year;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Escolha um mês'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 100,
                        child: ElevatedButton(
                            onPressed: () {
                              datePicker.changeData(DateTime(year, 1));
                              Navigator.of(context).pop();
                            },
                            child: const Text('Janeiro')),
                      ),
                      SizedBox(
                        width: 100,
                        child: ElevatedButton(
                            onPressed: () {
                              datePicker.changeData(DateTime(year, 3));
                              Navigator.of(context).pop();
                            },
                            child: const Text('Março')),
                      ),
                      SizedBox(
                        width: 100,
                        child: ElevatedButton(
                            onPressed: () {
                              datePicker.changeData(DateTime(year, 5));
                              Navigator.of(context).pop();
                            },
                            child: const Text('Maio')),
                      ),
                      SizedBox(
                        width: 100,
                        child: ElevatedButton(
                            onPressed: () {
                              datePicker.changeData(DateTime(year, 7));
                              Navigator.of(context).pop();
                            },
                            child: const Text('Julho')),
                      ),
                      SizedBox(
                        width: 100,
                        child: ElevatedButton(
                            onPressed: () {
                              datePicker.changeData(DateTime(year, 9));
                              Navigator.of(context).pop();
                            },
                            child: const Text('Setembro')),
                      ),
                      SizedBox(
                        width: 100,
                        child: ElevatedButton(
                            onPressed: () {
                              datePicker.changeData(DateTime(year, 11));
                              Navigator.of(context).pop();
                            },
                            child: const Text('Novembro')),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 100,
                        child: ElevatedButton(
                            onPressed: () {
                              datePicker.changeData(DateTime(year, 2));
                              Navigator.of(context).pop();
                            },
                            child: const Text('Fevereiro')),
                      ),
                      SizedBox(
                        width: 100,
                        child: ElevatedButton(
                            onPressed: () {
                              datePicker.changeData(DateTime(year, 4));
                              Navigator.of(context).pop();
                            },
                            child: const Text('Abril')),
                      ),
                      SizedBox(
                        width: 100,
                        child: ElevatedButton(
                            onPressed: () {
                              datePicker.changeData(DateTime(year, 6));
                              Navigator.of(context).pop();
                            },
                            child: const Text('Junho')),
                      ),
                      SizedBox(
                        width: 100,
                        child: ElevatedButton(
                            onPressed: () {
                              datePicker.changeData(DateTime(year, 8));
                              Navigator.of(context).pop();
                            },
                            child: const Text('Agosto')),
                      ),
                      SizedBox(
                        width: 100,
                        child: ElevatedButton(
                            onPressed: () {
                              datePicker.changeData(DateTime(year, 10));
                              Navigator.of(context).pop();
                            },
                            child: const Text('Outubro')),
                      ),
                      SizedBox(
                        width: 100,
                        child: ElevatedButton(
                            onPressed: () {
                              datePicker.changeData(DateTime(year, 12));
                              Navigator.of(context).pop();
                            },
                            child: const Text('Dezembro')),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
