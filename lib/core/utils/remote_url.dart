/// 서버가 준 이미지 주소를 절대 주소로 푼다.
///
/// 서버에 공개 주소가 설정돼 있지 않으면 `/static-info/...` 같은 경로만 오므로
/// [base](응답을 준 서버, 모르면 그 서비스의 기본 주소) 기준으로 푼다. 이미
/// 절대 주소면 그대로 둔다. TUK 월드·학식 이미지가 같은 규칙을 쓴다.
String resolveRemoteUrl(String url, Uri base) => base.resolve(url).toString();
