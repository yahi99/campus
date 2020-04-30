

import 'package:cloud_firestore/cloud_firestore.dart';

class SearchService{
  searchByName(String searchField) {
    return Firestore.instance
        .collection('userData')
        .where('initials', isEqualTo: searchField.substring(0, 1).toUpperCase())
        .getDocuments();
}}