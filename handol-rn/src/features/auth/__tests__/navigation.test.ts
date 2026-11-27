import { withOnlyRoute } from '../navigation';

jest.mock('expo-router', () => ({ useNavigationContainerRef: jest.fn() }));

describe('withOnlyRoute', () => {
  it('__root 아래 앱 스택에서 화면 하나만 남기고 바깥 필드는 둔다', () => {
    const root = {
      key: 'r', index: 0, routeNames: ['__root'], stale: false,
      routes: [{ key: 'a', name: '__root', state: { key: 's', index: 1, routeNames: ['index', 'login', '(tabs)'], stale: false, routes: [{ key: 'i', name: 'index' }, { key: 'l', name: 'login' }] } }],
    };
    const next = withOnlyRoute(root, '(tabs)') as typeof root;
    expect(next).toMatchObject({ key: 'r', routeNames: ['__root'], stale: false });
    expect(next.routes[0].state).toMatchObject({ key: 's', index: 0, routes: [{ name: '(tabs)' }], stale: false });
  });
  it('없는 화면이면 undefined', () => {
    expect(withOnlyRoute({ index: 0, routeNames: ['x'], routes: [{ key: 'x', name: 'x' }] }, 'login')).toBeUndefined();
  });
});
