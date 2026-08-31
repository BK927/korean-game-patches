# Dream Date Korean recovery 0.1.0-rc1

## 변경 사항

- 실제 설정에서 선택 가능한 중국어 간체 Localization 오브젝트
  `resources.assets / MonoBehaviour path_id=3832`에 기존 한국어 1,274쌍을
  원문 키·행 순서 그대로 활성화합니다.
- `sharedassets0.assets / Font path_id=93, 94`에 재배포 가능한 Nanum Gothic
  임베드를 사용합니다.
- `level2 / MonoBehaviour path_id=764, 768, 776, 822`의 프로필 라벨을
  각각 `생일`, `신장`, `취미`, `치수`로 바꿉니다.
- 원본 자산 전체 대신 세 Unity 파일에 대한 VCDIFF 델타를 제공합니다.
- 설치 전 자동 백업, 원본·결과 SHA-256 검증, 실패 시 롤백, 복구 스크립트를
  제공합니다. `.resS` 사이드카는 건드리지 않습니다.

## 설치 요약

1. Steam과 게임을 종료합니다.
2. xdelta3 3.x를 설치하고 PATH에 둡니다.
3. 압축을 푼 폴더에서 `install.ps1 -Force`를 실행합니다.
4. `verify.ps1 -State patched`로 결과를 확인합니다.
5. 문제가 있으면 설치 때 출력된 백업 경로로 `restore.ps1 -Force`를 실행합니다.

실제 Steam 설치본에서 메인 메뉴, 프로필 네 라벨, 첫 맵 대사와 한글 글꼴을
확인했습니다. 맵의 큰 분홍색 패널은 패치 전 상태에서도 동일하게 재현되는
게임 원본 렌더링 문제입니다. 전 구간 수동 플레이는 남아 있어 RC로 배포합니다.
