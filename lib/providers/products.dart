import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/http_exception.dart';
import './product.dart';

class Products with ChangeNotifier {
  List<Product> _items = [
    // Product(
    //   id: 'p1',
    //   title: 'Red Shirt',
    //   description: 'A red shirt - it is pretty red!',
    //   price: 29.99,
    //   imageUrl:
    //       'https://cdn.pixabay.com/photo/2016/10/02/22/17/red-t-shirt-1710578_1280.jpg',
    // ),
    // Product(
    //   id: 'p2',
    //   title: 'Trousers',
    //   description: 'A nice pair of trousers.',
    //   price: 59.99,
    //   imageUrl:
    //       'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Trousers%2C_dress_%28AM_1960.022-8%29.jpg/512px-Trousers%2C_dress_%28AM_1960.022-8%29.jpg',
    // ),
    // Product(
    //   id: 'p3',
    //   title: 'Yellow Scarf',
    //   description: 'Warm and cozy - exactly what you need for the winter.',
    //   price: 19.99,
    //   imageUrl:
    //       'https://live.staticflickr.com/4043/4438260868_cc79b3369d_z.jpg',
    // ),
    // Product(
    //   id: 'p4',
    //   title: 'A Pan',
    //   description: 'Prepare any meal you want.',
    //   price: 49.99,
    //   imageUrl:
    //       'https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Cast-Iron-Pan.jpg/1024px-Cast-Iron-Pan.jpg',
    // ),
  ];

  final String authToken;
  final String userId;

  Products(this.authToken, this.userId, this._items);

  List<Product> get items {
    return [..._items];
  }

  List<Product> get favoriteItems {
    return _items.where((prod) => prod.isFavorite).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((prod) => prod.id == id);
  }

  Future<void> fetchAndSetData([bool filterByUser = false]) async {
    
    var filterString = filterByUser ? 'orderBy="creatorId"&equalTo="$userId"' : '';
    var url = 'https://YOUR_PROJECT.firebaseio.com/products.json?auth=$authToken&$filterString';
    try {
      final response = await http.get(url);

      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      final List<Product> loadedProducts = [];
      if(extractedData == null){
        return;
      }

      url ='https://YOUR_PROJECT.firebaseio.com/userFavorite/$userId.json?auth=$authToken';
      final favoriteResponse = await http.get(url);
      final favoriteData = json.decode(favoriteResponse.body);

      extractedData.forEach((key, value) {
        loadedProducts.add(
          Product(
            id: key,
            title: value['title'],
            description: value['description'],
            price: value['price'],
            imageUrl: value['imageUrl'],
            isFavorite: favoriteData == null ? false : favoriteData[key] ?? false,
          ),
        );
        _items = loadedProducts;
        notifyListeners();
      });
    } catch (error) {
      throw error;
    }
  }

  Future<void> addProduct(Product p) async {
    try {
      final url = 'https://YOUR_PROJECT.firebaseio.com/products.json?auth=$authToken';
      final response = await http.post(
        url,
        body: json.encode({
          'title': p.title,
          'description': p.description,
          'price': p.price,
          'imageUrl': p.imageUrl,
          'creatorId': userId,
        }),
      );

      final newProduct = Product(
          description: p.description,
          title: p.title,
          imageUrl: p.imageUrl,
          price: p.price,
          id: json.decode(response.body)['name']);
      _items.add(newProduct);
      notifyListeners();
    } catch (error) {
      print(error);
      throw error;
    }
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    final _prodIndex = _items.indexWhere((prod) => prod.id == id);
    if (_prodIndex >= 0) {
      // TO-DO: Adicionar try catch
      final url =
          'https://YOUR_PROJECT.firebaseio.com/products/$id.json?auth=$authToken';
      await http.patch(url,
          body: json.encode({
            'title': newProduct.title,
            'description': newProduct.description,
            'price': newProduct.price,
            'imageUrl': newProduct.imageUrl,
          }));
      _items[_prodIndex] = newProduct;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String prodId) async {
    final indexProd = _items.indexWhere((prod) => prod.id == prodId);
    var existingProduct = _items[indexProd];
    _items.removeWhere((prod) => prod.id == prodId);
    notifyListeners();
    try {
      final url =
          'https://YOUR_PROJECT.firebaseio.com/products/$prodId.json?auth=$authToken';
      final response = await http.delete(url);
      if (response.statusCode >= 400) {
        throw HttpException('Could not delete');
      }
      existingProduct = null;
    } catch (e) {
      _items.insert(indexProd, existingProduct);
      notifyListeners();
      throw e;
    }
  }
}
