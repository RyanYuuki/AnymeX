import 'package:anymex/controllers/service_handler/service_handler.dart';

class CarouselData {
  String? id;
  String? title;
  String? poster;
  String? extraData;
  String? source;
  String? args;
  ServicesType? servicesType;

  CarouselData(
      {this.id,
      this.title,
      this.poster,
      this.extraData,
      this.source,
      this.args,
      this.servicesType});
}
