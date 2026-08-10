# KanjiVG 획순 데이터 라이선스

`JLPTN3Resources/KanjiStrokes.json`은 **KanjiVG** 프로젝트의 데이터에서
이 앱의 어휘에 등장하는 한자 434자의 획 경로만 추려 낸 파생물입니다.

- 원본: KanjiVG — https://kanjivg.tagaini.net / https://github.com/KanjiVG/kanjivg
- 저작자: Ulrich Apel 및 KanjiVG 기여자
- 라이선스: **Creative Commons Attribution-ShareAlike 3.0 Unported (CC BY-SA 3.0)**
  https://creativecommons.org/licenses/by-sa/3.0/

## 조건

CC BY-SA 3.0에 따라

1. **저작자 표시** — 앱의 쓰기 연습 화면에 「획순 데이터 © KanjiVG · CC BY-SA 3.0」을
   표기하고 있습니다.
2. **동일조건변경허락** — `KanjiStrokes.json` 및 이를 변형한 결과물은
   동일하게 CC BY-SA 3.0으로 배포되어야 합니다.

이 조건은 획순 데이터 파일에 적용되며, 저장소의 나머지 애플리케이션 소스 코드에는
적용되지 않습니다.

## 변형 내용

원본 SVG(`kanji/*.svg`)에서 `kvg:...-sN` id를 가진 `<path>` 요소의 `d` 속성만
획순 순서대로 추출해 `{"한자": ["path", ...]}` 형태의 JSON으로 재구성했습니다.
좌표계는 원본과 동일한 109×109를 유지합니다.
