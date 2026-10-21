import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:handori/core/network/static_info_dio_provider.dart';
import 'package:handori/features/map/data/tuk_place.dart';
import 'package:handori/features/map/data/tuk_world_api.dart';

part 'tuk_world_provider.g.dart';

@riverpod
TukWorldApi tukWorldApi(Ref ref) =>
    TukWorldApi(ref.watch(staticInfoDioProvider));

/// TUK 월드 제휴 업체 전체. 분류 필터는 화면에서 한다(수십 곳 규모).
@riverpod
Future<List<TukPlace>> tukWorldPlaces(Ref ref) async {
  final res = await ref.watch(tukWorldApiProvider).getPlaces();
  final base = res.response.realUri;
  return [for (final p in res.data) p.withImagesResolvedAgainst(base)];
}
