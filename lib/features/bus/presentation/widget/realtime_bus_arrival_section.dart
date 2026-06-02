import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:handori/features/bus/domain/model/bus_arrival.dart';
import 'package:handori/features/bus/presentation/provider/city_bus_provider.dart';

/// 한국공대 인근 시내버스 정류장 ID (GBIS stationId).
///
/// busstationservice 검색 API가 현재 인증키로 비활성화되어 코드로 조회할 수
/// 없으므로 상수로 관리한다. 캠퍼스 정류장 ID 확인 시 아래 값을 교체한다.
abstract class CampusBusStops {
  /// 정문 버스 정류장 — 시흥시 정류소 번호 25701 (GBIS stationId 216000701).
  static const int mainGate = 216000701;

  /// 정왕역 승차 정류장 2곳 — 시흥시 정류소 번호 25835, 25904.
  /// (GBIS stationId 216000835, 216000904)
  static const List<int> jeongwangStations = [
    216000835, // 정류소 번호 25835
    216000904, // 정류소 번호 25904
  ];
}

// ─── Palette (프로젝트 규약 §7) ───────────────────────────────────────────────
const Color _kPrimary = Color(0xFF00C4F9);
const Color _kBgBase = Colors.white;
const Color _kBgSoft = Color(0xFFFAFAFA);
const Color _kBorderSoft = Color(0xFFF0F0F8);
const Color _kTextPrimary = Color(0xFF1A1A1A);
const Color _kTextMuted = Color(0xFF8A8F98);

const double _kCardRadius = 12.0;

/// 실시간 시내버스 도착 정보 섹션.
///
/// [stationId] 정류장의 도착 정보를 `cityBusArrivalsProvider`로 구독하고
/// 로딩/에러/데이터 3가지 상태를 모두 처리한다(규약 §6).
///
/// [label] 이 지정되면 섹션 상단에 정류장 구분용 서브 타이틀을 표시한다.
/// 한 방면에 정류장이 여러 곳일 때 각 섹션을 구분하기 위해 사용한다.
class RealtimeBusArrivalSection extends ConsumerWidget {
  final int stationId;
  final String? label;

  const RealtimeBusArrivalSection({
    super.key,
    required this.stationId,
    this.label,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = cityBusArrivalsProvider(stationId: stationId);
    final asyncArrivals = ref.watch(provider);

    final content = asyncArrivals.when(
      data: (arrivals) {
        final running = arrivals.where((a) => a.hasArrival).toList();
        if (running.isEmpty) {
          return const _RealtimeMessage(
            icon: Icons.directions_bus_filled_outlined,
            message: '현재 도착 예정인 버스가 없어요',
          );
        }
        return Column(
          children: [
            for (final arrival in running)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ArrivalCard(arrival: arrival),
              ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              color: _kPrimary,
            ),
          ),
        ),
      ),
      error: (_, _) => _RealtimeMessage(
        icon: Icons.error_outline_rounded,
        message: '도착 정보를 불러오지 못했어요',
        onRetry: () => ref.invalidate(provider),
      ),
    );

    if (label == null) return content;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: _kTextMuted,
              ),
              const SizedBox(width: 4),
              Text(
                label!,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _kTextMuted,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
        content,
      ],
    );
  }
}

/// 빈 상태 / 에러 상태 공용 메시지 박스.
class _RealtimeMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  const _RealtimeMessage({
    required this.icon,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
      decoration: BoxDecoration(
        color: _kBgBase,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: _kBorderSoft),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: _kTextMuted),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: _kTextMuted,
              letterSpacing: -0.2,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: _kPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              ),
              child: const Text(
                '다시 시도',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 노선 1개의 실시간 도착 카드.
class _ArrivalCard extends StatelessWidget {
  // 임박 강조 기준(분).
  static const int _imminentThreshold = 5;

  final BusArrival arrival;

  const _ArrivalCard({required this.arrival});

  @override
  Widget build(BuildContext context) {
    final first = arrival.first!;
    final isImminent = first.predictMinutes <= _imminentThreshold;

    return Container(
      decoration: BoxDecoration(
        color: _kBgBase,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: _kBorderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _kBgSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kBorderSoft),
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              color: _kTextPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        arrival.routeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _kTextPrimary,
                          letterSpacing: -0.4,
                          height: 1.1,
                        ),
                      ),
                    ),
                    if (first.isLowFloor) ...[
                      const SizedBox(width: 8),
                      const _Badge(label: '저상'),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _subLabel(first),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: _kTextMuted,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _ArrivalTime(
            minutes: first.predictMinutes,
            isImminent: isImminent,
          ),
        ],
      ),
    );
  }

  String _subLabel(BusArrivalPrediction p) {
    final parts = <String>[];
    if (arrival.destinationName != null) {
      parts.add('${arrival.destinationName} 방면');
    }
    if (p.remainingStops != null) {
      parts.add('${p.remainingStops}번째 전');
    }
    if (p.remainSeats != null) {
      parts.add('빈자리 ${p.remainSeats}석');
    }
    return parts.isEmpty ? '실시간 운행 중' : parts.join(' · ');
  }
}

class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _kPrimary,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

/// 도착 시간 표시 — 임박 시 핀포인트 블루로 강조.
class _ArrivalTime extends StatelessWidget {
  final int minutes;
  final bool isImminent;

  const _ArrivalTime({required this.minutes, required this.isImminent});

  @override
  Widget build(BuildContext context) {
    final numberColor = isImminent ? _kPrimary : _kTextPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$minutes',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: numberColor,
                letterSpacing: -0.5,
                height: 1.0,
              ),
            ),
            const SizedBox(width: 2),
            const Text(
              '분',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _kTextMuted,
                height: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          '후 도착',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: _kTextMuted,
          ),
        ),
      ],
    );
  }
}
