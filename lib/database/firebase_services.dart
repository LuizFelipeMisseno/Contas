import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contas/database/transation_info.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

class FirebaseManagement {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? downloadURL;
  ListResult? listOfImages;
  List<String> urls = [];

  //Adicionar no Firebase
  addTransiction(Conta transictionData, DateTime date) async {
    List list = [transictionData.toMap()];
    String month = DateFormat.MMMM('pt br').format(date);
    String year = date.year.toString();

    try {
      await _db.collection(year).doc(month).update(
        {
          'contas': FieldValue.arrayUnion(list),
        },
      );
    } catch (e) {
      try {
        _db.collection(year).doc(month).set({
          'contas': FieldValue.arrayUnion(list),
        });
      } catch (e) {
        _db.collection(year).add(
          {
            'contas': FieldValue.arrayUnion(list),
          },
        );
      }
    }
  }

  //Atualizar no Firebase
  updateTransiction(Conta transictionData, String year, String month) async {
    await _db.collection(year).doc(month).update(
          transictionData.toMap(),
        );
  }

  //Deletar do Firebase
  Future<void> deleteTransiction(Conta transictionData, DateTime date) async {
    List list = [transictionData.toMap()];
    String month = DateFormat.MMMM('pt br').format(date);
    String year = date.year.toString();

    await _db.collection(year).doc(month).update(
      {
        'contas': FieldValue.arrayRemove(list),
      },
    );
  }
}
