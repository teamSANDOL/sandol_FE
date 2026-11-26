import { openDirections } from '../directions';
import { hasLocation, type EmptyClass } from '@/features/empty_class/model';
import type { useMapState } from '../useMapState';
import { BuildingPanel, CampusHomePanel, FacilityFilterPanel } from './CampusPanels';
import { EmptyClassPanel } from './EmptyClassPanel';
import { TukPlaceDetail, TukWorldPanel } from './TukPanels';

type MapState = ReturnType<typeof useMapState>;

interface Props {
  state: MapState;
  buildings: readonly EmptyClass[];
  /** 지도 위치 보기 후 시트를 접는다 */
  collapseSheet: () => void;
  moveCamera: (latitude: number, longitude: number) => void;
}

/** 시트 안에 무엇을 그릴지 (MapScreen 의 패널 분기) */
export function SheetContent({ state: s, buildings, collapseSheet, moveCamera }: Props) {
  const building = buildings.find((b) => b.className === s.buildingName) ?? null;
  const place = s.place;
  const home = <CampusHomePanel onEmptyClass={() => void s.openEmptyClass()} onShowAll={() => void s.show('filter')} />;

  switch (s.panel) {
    case 'home':
      return home;
    case 'filter':
      return <FacilityFilterPanel onClose={() => void s.show('home')} onEmptyClass={() => void s.openEmptyClass()} />;
    case 'building':
    case 'buildingDetail':
      // 데이터가 다시 불러와지며 고른 건물이 사라진 경우 첫 시트로
      if (!building) return home;
      return (
        <BuildingPanel
          building={building}
          expanded={s.panel === 'buildingDetail'}
          onDirections={hasLocation(building) ? () => void openDirections(building.className, building.latitude, building.longitude) : null}
          onDetail={() => void s.show('buildingDetail')}
          onDeselect={s.deselectToHome}
          onEmptyClass={() => void s.openEmptyClass(building.className)}
        />
      );
    case 'emptyClass':
      return <EmptyClassPanel focusBuilding={s.focusBuilding} onBack={() => void s.back()} onBuildingPress={s.openBuilding} />;
    case 'tukDetail':
      if (place) {
        return (
          <TukPlaceDetail
            place={place}
            onBack={() => void s.back()}
            onDirections={() => void openDirections(place.name, place.latitude, place.longitude)}
            onShowOnMap={() => {
              moveCamera(place.latitude, place.longitude);
              collapseSheet();
            }}
          />
        );
      }
      return <TukWorldPanel category={s.tukCategory} onCategory={s.setTukCategory} onPlacePress={s.openPlace} />;
    case 'tuk':
      return <TukWorldPanel category={s.tukCategory} onCategory={s.setTukCategory} onPlacePress={s.openPlace} />;
  }
}
