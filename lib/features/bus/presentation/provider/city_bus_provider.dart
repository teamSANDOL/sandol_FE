import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:handori/core/network/gyeonggi_bus_dio_provider.dart';
import 'package:handori/features/bus/data/data_source/city_bus_api.dart';
import 'package:handori/features/bus/data/repository/city_bus_repository_impl.dart';
import 'package:handori/features/bus/domain/model/bus_arrival.dart';
import 'package:handori/features/bus/domain/repository/city_bus_repository.dart';

part 'city_bus_provider.g.dart';

/// `.env`의 경기도 버스 API 인증키. 누락 시 명확한 예외를 던진다.
const String _envApiKey = 'GYEONGGI_BUS_API_KEY';

@riverpod
CityBusApi cityBusApi(Ref ref) {
  final dio = ref.watch(gyeonggiBusDioProvider);
  return CityBusApi(dio);
}

@riverpod
CityBusRepository cityBusRepository(Ref ref) {
  final api = ref.watch(cityBusApiProvider);
  final serviceKey = dotenv.env[_envApiKey];
  if (serviceKey == null || serviceKey.isEmpty) {
    throw StateError('.env에 $_envApiKey 가 설정되어 있지 않습니다.');
  }
  return CityBusRepositoryImpl(api, serviceKey);
}

/// [stationId] 정류장의 실시간 버스 도착 정보.
/// UI는 이 provider를 `AsyncValue.when`으로 구독한다.
@riverpod
Future<List<BusArrival>> cityBusArrivals(Ref ref, {required int stationId}) {
  final repo = ref.watch(cityBusRepositoryProvider);
  return repo.getArrivals(stationId);
}
