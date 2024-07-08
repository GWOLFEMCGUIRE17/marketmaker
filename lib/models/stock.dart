import 'package:swipe/models/asset.dart';
import 'package:swipe/models/asset_data.dart';
import 'package:swipe/models/news_data.dart';
import 'package:swipe/models/price_data.dart';
import 'package:swipe/models/stock_data.dart';
import 'package:yahoofin/yahoofin.dart';

class Stock extends Asset {

  Stock(super.symbol, super.name, super.stockData, super.priceData, super.newsData);

}