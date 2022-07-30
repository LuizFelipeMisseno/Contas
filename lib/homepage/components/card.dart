import 'package:contas/components/app_fonts.dart';
import 'package:contas/database/firebase_services.dart';
import 'package:contas/database/transation_info.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CardTransacao extends StatefulWidget {
  final Map snapshot;

  const CardTransacao({Key? key, required this.snapshot}) : super(key: key);

  @override
  State<CardTransacao> createState() => _CardTransacaoState();
}

class _CardTransacaoState extends State<CardTransacao> {
  final currency = NumberFormat("R\$ #,##0.00", "pt_BR");

  @override
  Widget build(BuildContext context) {
    Conta conta = Conta(
      data: widget.snapshot['data'] ?? '',
      description: widget.snapshot['descricao'] ?? '',
      price: widget.snapshot['valor'] ?? 0.0,
      occurrence: widget.snapshot['ocorrencia'] ?? '',
    );
    DateTime dt = (conta.data).toDate();

    return GestureDetector(
      onTap: () {
        dialog(context, conta, dt);
      },
      child: Container(
        height: 100,
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(
              Radius.circular(20),
            ),
            color: conta.description.contains("Transferência via PIX") ||
                    conta.description.contains("Depósito na conta")
                ? Color.fromARGB(255, 219, 219, 219)
                : conta.occurrence == 'entrada'
                    ? const Color.fromARGB(255, 143, 255, 126)
                    : const Color.fromARGB(255, 255, 119, 119),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 3,
                offset: Offset(3, 4),
              ),
            ]),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        conta.description,
                        style: AppFonts.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'Data: ' +
                          DateFormat('dd')
                              .format(conta.data.toDate())
                              .toString() +
                          '/' +
                          DateFormat('MM')
                              .format(conta.data.toDate())
                              .toString(),
                      style: AppFonts.description,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      currency.format(conta.price),
                      style: AppFonts.description,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  dialog(context, conta, dt) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(conta.description),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Dia: ' +
                    DateFormat('dd/MM/yyyy')
                        .format(conta.data.toDate())
                        .toString(),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Horário: ' + DateFormat('HH:mm').format(dt).toString(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Ocorrência: ' + conta.occurrence,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Valor: ' + currency.format(conta.price),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                FirebaseManagement().deleteTransiction(conta, dt);
                Navigator.of(context).pop();
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }
}
