# Dream Date 잔존 UI 자산 조사

- 조사 시각(UTC): `2026-08-31T02:53:22+00:00`
- 기준: `D:\SteamLibrary\steamapps\common\Dream Date`
- 실제 Steam 게임 파일 수정: 아니요 (읽기 전용)

## 결론

- 프로필의 `身高/三围/生日/爱好`는 `UnityEngine.UI.Text MonoBehaviour components in level2, not Texture2D/Sprite`.
- 확인된 Text 오브젝트는 모두 `Font path_id=93`을 참조하며, 표기만 남아 있고 이미지 텍스처/스프라이트가 아닙니다.
- `加载中` 정확 문자열은 설치된 `Dream Date_Data` 전체(대용량 `.resS` 포함)와 게임 DLL에서 찾지 못했습니다. Exact UTF-8/UTF-16LE ‘加载中’ was not found in any file under the installed Dream Date_Data tree (including .resS sidecars), serialized assets, or the two game DLLs. The scene loading overlay stores the visible Text value as English ‘Loading...’ under GameManager/UIManager/DLC Loading; the reported Chinese value must therefore come from runtime localization/another bundle/state not present in this read-only install scan. The DLL ‘加载’ hits belong to third-party ad/error strings, not LoadingController UI text.
- 분홍 다이아 가설: The four profile Text objects reference Font path_id 93. The staged Nanum Gothic cmap lacks all reported Chinese characters, so missing-glyph diamonds in a Nanum staging run are consistent with font coverage failure; the labels themselves are hardcoded scene Text and remain untranslated.
- 맵 이미지 교차 확인: The map active-dialogue Image components reference unchanged mainGame_active_dialogue_btn Sprite variants (274/503/504) backed by Texture2D 119. Their active and .orig serialized/image payload hashes match; this pink map art is therefore not introduced by the Font 93/94 replacement.
- 판단 신뢰도: `high that the named pink map panels are unchanged map art; high that Nanum can separately create missing-glyph diamonds for Chinese Text; visual certainty about which screenshot region was observed still requires a capture`

## 프로필 Text 매핑

| GameObject | Text path ID | 원문 | Font path ID |
|---|---:|---|---:|
| `Birthday` | `764` | `生日` | `93` |
| `Height` | `768` | `身高` | `93` |
| `Hobby` | `776` | `爱好` | `93` |
| `Measurement` | `822` | `三围` | `93` |

## Loading UI 매핑

씬에 직렬화된 로딩 문구는 중국어 `加载中`이 아니라 `GameManager/UIManager/DLC Loading/Text` 아래의 `Loading...`입니다. `LoadingController` 자체는 문구를 보유하지 않고 전환 애니메이션과 진행 Image만 제어합니다.

| 자산 | Text path ID | 계층 | Font path ID | 값 |
|---|---:|---|---:|---|
| `level0` | `987` | `GameManager/UIManager/DLC Loading/Text` | `94` | `Loading...` |
| `level1` | `1103` | `GameManager/UIManager/DLC Loading/Text` | `94` | `Loading...` |
| `level2` | `1260` | `GameManager/UIManager/DLC Loading/Text` | `94` | `Loading...` |
| `level3` | `1092` | `GameManager/UIManager/DLC Loading/Text` | `94` | `Loading...` |
| `resources.assets` | `5525` | `GameManager/UIManager/DLC Loading/Text` | `94` | `Loading...` |
| `resources.assets.orig` | `5525` | `GameManager/UIManager/DLC Loading/Text` | `94` | `Loading...` |

## 글꼴 cmap 확인

Nanum Gothic Regular는 한글 음절은 포함하지만 조사 대상 중국어 글자에 대한 cmap 항목은 없습니다. 따라서 Font 93을 Nanum으로 교체한 staging에서 해당 Text가 분홍색 누락 글리프로 보이는 현상은 폰트 교체와 일치합니다.

| 글꼴/자산 | 身高 | 三围 | 生日 | 爱好 |
|---|---:|---:|---:|---:|
| `NanumGothic-Regular.ttf` | 아니요 | 아니요 | 아니요 | 아니요 |
| `sharedassets0.assets / Font 93` | 예 | 아니요 | 예 | 아니요 |
| `sharedassets0.assets / Font 94` | 예 | 아니요 | 예 | 아니요 |
| `sharedassets0.assets.orig / Font 93` | 예 | 아니요 | 예 | 아니요 |
| `sharedassets0.assets.orig / Font 94` | 아니요 | 아니요 | 아니요 | 아니요 |

## 맵 분홍 패널 이미지 확인

`resources.assets`의 `Texture2D path_id=119 (mainGame_active_dialogue_btn)`와 Sprite 274/503/504가 맵의 다수 `Activce.Button`/`Light` Image에 연결됩니다. 이 오브젝트들의 active/.orig payload hash와 Texture2D 디코드 이미지 hash가 일치하므로, 해당 분홍 패널 아트는 폰트 교체로 생긴 것이 아닙니다.

| path ID | active raw SHA-256 | .orig raw SHA-256 | 일치 |
|---:|---|---|:---:|
| `119` | `fad4c0b644c47abeae212c2399d62a9850db74263e60fe43680eccd96a15471a` | `fad4c0b644c47abeae212c2399d62a9850db74263e60fe43680eccd96a15471a` | 예 |
| `274` | `1e23b2b81cc6ef077c17fbcebfeff74dcaec60fad15eb66ece8d266107351827` | `1e23b2b81cc6ef077c17fbcebfeff74dcaec60fad15eb66ece8d266107351827` | 예 |
| `503` | `7cb764ef01524d45b312afd20655392e835cd51de9b71d561de9e533f5787f5f` | `7cb764ef01524d45b312afd20655392e835cd51de9b71d561de9e533f5787f5f` | 예 |
| `504` | `2f897cd2dbd2d74b0ddb3cebbee6946c1d3d0b2f5d557b0af6879ffb61565469` | `2f897cd2dbd2d74b0ddb3cebbee6946c1d3d0b2f5d557b0af6879ffb61565469` | 예 |

- Image 참조 수: Sprite 274 = 37, Sprite 503 = 37, Sprite 504 = 37

## 근거 산출물

- `residual-ui-investigation.json`: UnityPy 오브젝트/경로 ID/고유명사·폰트·맵 Image 참조와 자산별 해시
- `level2`의 `MonoBehaviour 764/768/776/822`는 각각 `Birthday/Height/Hobby/Measurement` GameObject의 Unity UI Text입니다.
- 정확한 `加载中` 자산 문자열 부재(대용량 `.resS` 포함), 씬의 `Loading...` 위치, DLL의 `加载` 광고 오류 문자열 분리를 기록했습니다.

## 다음 조치

1. 공개용 글꼴은 중국어 잔존 UI까지 고려해 CJK+한글 cmap을 갖춘 재배포 허용 글꼴로 선정하거나, Font 93을 원본 CJK 글꼴로 유지하고 별도 한글 폰트를 적용하는 방식을 검토합니다.
2. `加载中`은 현재 설치본의 직렬화 자산에는 없으므로, 재현 가능한 DLC/AssetBundle이 다시 제공될 때 같은 검색을 수행하거나 runtime hierarchy 캡처로 생성 주체를 확인합니다.
3. 맵에서 보인 분홍 패널이 위의 `mainGame_active_dialogue_btn`와 일치하는지 화면 캡처로 최종 대조합니다. 정적 자산 hash상 이 아트는 원본과 동일하며, 별도로 Nanum의 CJK cmap 누락은 Chinese Text에 누락 글리프를 만들 수 있습니다.
