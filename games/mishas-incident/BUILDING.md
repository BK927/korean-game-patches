# Misha's incident 패치 재빌드

저장소에는 게임 원본 JSON을 넣지 않습니다. `payload/translations.json`에는 각 번역 위치, 원문 문자열의 SHA-256, 한국어 목표문과 지원하는 이전 시험판 문자열의 SHA-256만 보관합니다.

## 필드 페이로드 생성

다음 네 종류의 로컬 입력이 필요합니다.

- `corpus.jsonl`: 번역 단위와 실제 JSON 경로 목록
- 순정 게임의 `www/data`
- 지원할 이전 한국어 패치의 `www/data` 한 개 이상
- 최종 검수본의 `www/data`

```powershell
python .\tools\build_field_payload.py `
  --records C:\work\corpus.jsonl `
  --clean-data C:\work\clean\www\data `
  --previous-data C:\work\previous-1\www\data `
  --previous-data C:\work\previous-2\www\data `
  --target-data C:\work\reviewed\www\data `
  --output .\payload\translations.json
```

빌더는 모든 레코드의 원문·이전값·목표값을 실제 JSON 경로에서 다시 읽고, 원문이 corpus와 일치하지 않으면 중단합니다.

## 배포 ZIP 생성

```powershell
python .\tools\build_release_candidate.py
```

출력은 `dist/` 아래에 만들어집니다. ZIP은 고정된 파일 순서와 시각을 사용하므로 동일한 저장소 입력에서 같은 SHA-256이 나옵니다.
