import 'package:flutter/material.dart';
import 'package:my_shop/providers/orders.dart';
import 'package:provider/provider.dart';

import '../providers/cart.dart' show Cart;
import '../providers/orders.dart';
import '../widgets/cart_item.dart';

class CartScreen extends StatelessWidget {
  static const String routeName = '/cart';

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<Cart>(context);
    var _isLoading = false;
    return Scaffold(
      appBar: AppBar(
        title: Text('Seu carrinho'),
      ),
      body: Column(children: [
        _isLoading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : Card(
                margin: EdgeInsets.all(15),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 20,
                        ),
                      ),
                      Spacer(),
                      Chip(
                        label: Text(
                          '\$${cart.totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color:
                                Theme.of(context).primaryTextTheme.title.color,
                          ),
                        ),
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      OrderButton(cart: cart),
                    ],
                  ),
                ),
              ),
        SizedBox(
          height: 10,
        ),
        Expanded(
            child: ListView.builder(
          itemCount: cart.itemCount,
          itemBuilder: (ctx, i) => CartItem(
            id: cart.items.values.toList()[i].id,
            title: cart.items.values.toList()[i].title,
            quantity: cart.items.values.toList()[i].quantity,
            price: cart.items.values.toList()[i].price,
            productId: cart.items.keys.toList()[i],
          ),
        ))
      ]),
    );
  }
}

class OrderButton extends StatefulWidget {
  const OrderButton({
    Key key,
    @required this.cart,
  }) : super(key: key);

  final Cart cart;

  @override
  _OrderButtonState createState() => _OrderButtonState();
}

class _OrderButtonState extends State<OrderButton> {
  var _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      child: _isLoading? Center(child: CircularProgressIndicator(),): Text('ORDER NOW',
          style: TextStyle(color: Theme.of(context).primaryColor)),
      onPressed: (widget.cart.items.length == 0 || _isLoading)
          ? null
          : () async {
              setState(() {
                _isLoading = true;
              });
              try {
                await Provider.of<Orders>(context, listen: false).addOrder(
                  widget.cart.items.values.toList(),
                  widget.cart.totalAmount,
                );
                widget.cart.clear();
              } catch (e) {
                print('got error');
              }
              setState(() {
                _isLoading = false;
              });
            },
    );
  }
}
