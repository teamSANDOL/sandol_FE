import 'package:handori/features/home/model/banner_model.dart';
import 'package:handori/features/bus/model/bus_model.dart';

class StaticDataRepository {
  final List<Banners> banners = [
    Banners(ImagePath: 'assets/img/banner1.png'),
    Banners(ImagePath: 'assets/img/banner2.png'),
    Banners(ImagePath: 'assets/img/banner3.png'),
  ];

  static final List<Bus> bus = [
    Bus(busIcon: 'assets/img/bus.png', busNumber: '33', busTime: '2분'),
    Bus(busIcon: 'assets/img/bus.png', busNumber: '20-1', busTime: '7분'),
    Bus(busIcon: 'assets/img/bus.png', busNumber: '26-1', busTime: '3분'),
  ];
}
