import 'package:anymex/controllers/service_handler/service_handler.dart';

class CarouselData {
  String? id;
  String? title;
  String? poster;
  String? extraData;
  String? source;
  String? args;
  ServicesType servicesType;
  bool releasing;

  int? anilistUserId;
  int? malUserId;
  String? author;
  String? reason;

  CarouselData({
    this.id,
    this.title,
    this.poster,
    this.extraData,
    this.source,
    this.args,
    required this.servicesType,
    required this.releasing,
    this.anilistUserId,
    this.malUserId,
    this.author,
    this.reason,
  });
}
