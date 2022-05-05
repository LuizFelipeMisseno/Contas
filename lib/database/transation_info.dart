import 'package:cloud_firestore/cloud_firestore.dart';

class Conta {
  Conta({
    required this.data,
    required this.description,
    required this.price,
    required this.occurrence,
  });

  Timestamp data;
  String description;
  dynamic price;
  String occurrence;

  //passar dados para mapa
  Map<String, dynamic> toMap() {
    return {
      'data': data,
      'descricao': description,
      'valor': price,
      'ocorrencia': occurrence,
    };
  }
}

class GetFirestoreProductsList {
  CollectionReference reference = FirebaseFirestore.instance.collection('2022');

  Future<List<Conta>> get() async {
    var result = await reference.get();
    List<Conta> itens = [];

    result.docs.map((e) => e).forEach(
      (element) {
        itens.add(
          Conta(
              data: element['data'],
              description: element['descricao'],
              price: element['valor'],
              occurrence: element['ocorrencia']),
        );
      },
    );

    return itens;
  }
}
