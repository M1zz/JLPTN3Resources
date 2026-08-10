# JLPT N3 앱 TODO

## 완료
- [x] 앱 기존 구조 파악 (ResourceListView, StudyPlanView)
- [x] LearningCard.swift - 데이터 모델 (SRS 필드 포함)
- [x] N3ContentData.swift - 실제 N3 어휘/문법 컨텐츠 (~155 어휘 + 40 문법)
- [x] LearningStore.swift - SM-2 SRS 엔진 + 상태 관리 + UserDefaults 영속화
- [x] LearningHomeView.swift - 학습 대시보드 UI
- [x] StudySessionView.swift - 플래시카드 학습 UI (앞/뒷면 + 4단계 평가)
- [x] ContentView.swift 업데이트 - 학습 탭 추가
- [x] project.pbxproj 업데이트 - 5개 새 파일 등록

## 완료 (N3ContentData.swift 전면 재작성)
- [x] N3ContentData.swift - 실제 스크랩 데이터로 전면 교체 (2026-03-29)
  - 문법 182개 (gramB1~gramB5, 각 36-38개 배치)
  - jlptsensei 어휘 192개 (vocabS1~vocabS4, 48개 배치)
  - jisho 고유 어휘 200개 (vocabK1~vocabK5, 40개 배치)
  - 총 574개 카드 (영어 의미 → 한국어 번역 완료)
  - 핵심 문법 패턴에 예문 포함

## 완료 (데이터 수집)
- [x] 웹 스크래핑 - n3_raw_data.md 생성 (2026-03-29)
  - jlptsensei.com: 문법 182개 (5페이지), 어휘 192개 (2페이지)
  - jisho.org: 단어 400개 (20페이지)
  - 총 774개 항목

## 완료 (앱 아이콘)
- [x] AppIcon 제작 (2026-08-10)
  - 앱 테마 컬러 적용 (네이비 #0A1628~#16325E 배경 + 골드 #D4A373 마크)
  - 「N3 / 日本語」 구성, 아이콘 캔버스 꽉 차게 배치
  - 시스템 외관 대응: Light(기본) / Dark / Tinted 3종 등록
  - 렌더링 스크립트: CoreGraphics 기반 Swift 스크립트로 1024x1024 PNG 생성
  - 빌드 검증 완료 (xcodebuild BUILD SUCCEEDED)

## 완료 (라이트/다크 시스템 모드 대응)
- [x] Theme.swift 신규 - 시맨틱 컬러 팔레트 (2026-08-10)
  - `Color.adaptive(light:dark:)` — UIColor 동적 provider 기반, 시스템 외관 자동 추종
  - `Color(accentHex:)` — 강조색은 다크에서 원본 hex, 라이트에서 HSB 보정(채도 ×1.25, 명도 ≤0.72)
  - 토큰: background / backgroundElevated / heroBanner / surface / surfaceSoft / track /
    stroke / decoration / shadow / textPrimary~Quaternary / brand / onBrand / inkColor
- [x] 전 화면 하드코딩 컬러 제거 → Theme 토큰으로 교체
  - LearningHomeView, StudySessionView, KanjiWritingView, MilestoneView
  - ResourceListView, ResourceCardView, ResourceDetailView, StudyPlanView
  - Resource / LearningCard 모델의 카테고리·상태 컬러 → `Color(accentHex:)`
  - `.toolbarColorScheme(.dark)` 강제 제거 (시스템 추종)
- [x] AccentColor.colorset 라이트/다크 2종 등록
- [x] 시뮬레이터 검증 — 4개 탭 + 학습 세션 화면, 라이트/다크 각각 스크린샷 확인

## 완료 (쓰기 연습 — 한 화면 한 글자)
- [x] KanjiWritingView 재구성 (2026-08-10)
  - 단어 단위 다칸 → `WritingStep`(낱글자) 단위로 평탄화, 한 화면에 한 글자
  - 단어 20개를 한자 낱글자로 펼쳐 순차 진행 (예: 38스텝)
  - 헤더에 단어 전체 표시 + 현재 쓸 글자만 브랜드 컬러 강조 (같은 한자 중복 대비 charOffset 기준)
  - "한자 N자 중 M번째" 칩 (한자 1자 단어에서는 숨김), 상단 진행 바
  - 캔버스 1개로 축소, 획은 `drawings[stepID]`에 보관 → 이전으로 돌아가면 쓰던 글씨 유지
  - 완료 화면: "N개 단어 · 한자 M자를 연습했습니다"

## 완료 (합격 조건 · 과목별 자가 진단)
- [x] MilestoneView에 «합격 조건» 섹션 추가 (2026-08-10)
  - 총점 95/180점 + 과목별 기준점 19/60점, 한 과목이라도 미달 시 불합격 경고
  - 채점 과목 3개(언어지식 / 독해 / 청해)와 시험 시간(30분+70분, 40분) 표기
- [x] «이 정도면 합격선을 넘었다» 자가 진단 섹션 추가
  - 과목별 19점 체감 기준 4개 + 안정권(35점 안팎) 기준 2개
  - 언어지식은 앱 진도(어휘/문법 readiness)를 목표 60%와 나란히 표시
  - 독해·청해는 앱이 추적하지 않음을 명시 (기출·교재로 훈련)
- [x] StudyPlanView 채점 과목 데이터 수정 — 4과목 오류 → 실제 3과목 구조
  - 문자·어휘와 문법은 «언어지식» 한 과목(60점)으로 합산되는 것이 맞음

## 완료 (미니 모의고사)
- [x] MockExamData.swift / MockExamView.swift 신규 + «모의고사» 탭 추가 (2026-08-10)
  - 18문항: 언어지식 10 · 독해 4 · 청해 4
  - 실제 출제 형식 반영: 漢字読み / 表記 / 文脈規定 / 言い換え類義 / 文法形式の判断,
    독해 短文(お知らせ·エッセイ) 2지문, 청해 課題理解 / ポイント理解 / 即時応答
  - 문항은 전부 자체 제작 (기출문제는 저작권 문제로 사용 불가)
  - 청해: AVSpeechSynthesizer로 재생, 화자별 pitch(男 0.82 / 女 1.18)를 달리해 대화 구분
  - 채점: 과목별 정답률 → 60점 환산, 19점 기준선을 막대에 표시,
    «총점 95점 이상» + «전 과목 19점 이상» 두 조건을 각각 판정
  - 문항별 해설 + 청해 대본 공개(정답 후), 이전/다음으로 답 수정 가능
- [x] 과목 통과/미달 색상 수정 — 과목 색(언어지식 crimson)이 실패색처럼 읽히던 문제

## 완료 (따라쓰기 밑글자)
- [x] 쓰기 연습에 흐릿한 밑글자(placeholder) 상시 표시 (2026-08-10)
  - 기존 «힌트» 토글은 기본 꺼짐 + 글자를 넘길 때마다 초기화되어 따라쓰기에 쓸 수 없었음
  - TraceGuideLevel 3단계 순환: 흐리게(0.13, 기본) → 진하게(0.30) → 없음
  - 브랜드 골드 → 무채색(textPrimary)으로 변경, weight .black → .medium
    (획 형태를 따라 그리기 좋게. 라이트/다크 모두 대비 확보)
  - @AppStorage로 저장 — 글자를 넘겨도, 앱을 다시 켜도 설정 유지

## 완료 (한자 획순)
- [x] KanjiVG 기반 획순 애니메이션 (2026-08-10)
  - 어휘에 쓰인 고유 한자 434자 / 4,192획을 KanjiStrokes.json(352KB)으로 번들
  - KanjiStrokes.swift — SVG path 파서(M/m·L/l·H/h·V/v·C/c·S/s·Z) + 파싱 캐시
  - StrokeShape: phase 하나(0→획수)를 선형으로 움직이고 각 획이 자기 구간만 trim,
    자식마다 클램프해야 순차 재생됨 (호출부에서 클램프하면 전부 동시에 그려짐)
  - 캔버스 우상단 «획순» 버튼으로 재생, 밑글자 위·필기 아래 레이어에 그림
  - 다 그린 뒤 1.2초 후 자동 페이드아웃 (필기 면을 가리지 않도록),
    재생 토큰으로 연속 재생 시 이전 예약 무효화
  - 헤더에 «N획» 칩 추가
- [x] 라이선스: KanjiVG는 CC BY-SA 3.0 — 화면 하단 저작자 표시 + LICENSE-KanjiVG.md

## 완료 (쓰기 = 인출 연습)
- [x] 쓰기 연습을 «문제 풀기» 중심으로 전환 (2026-08-10)
  - 기존엔 답(한자)이 계속 보여서 베껴 쓰기에 그침 → 인출 연습이 되지 않았음
  - 문제 풀기 모드(기본): 단어에서 대상 한자를 «〇»로 가리고 뜻·읽기만 제시,
    밑글자·획순 버튼·획수 칩을 모두 감춘 뒤 «정답 확인»에서 공개
  - 공개 후 «틀림 / 맞음» 자기 채점 → 결과 화면에 정답 수 + «다시 볼 한자» 그리드
  - 따라 쓰기 모드는 그대로 유지 (밑글자 3단계 + 이전/다음)
  - 이미 채점한 글자로 되돌아가면 공개 상태 복원

## 학습과학 설계 원칙
- 간격반복 (Spaced Repetition): SM-2 알고리즘
- 교차 학습 (Interleaved Practice): 어휘/문법 섞어서 복습
- 인출 연습 (Retrieval Practice): 플래시카드 능동적 회상
- 구체→추상 순서: 동사/명사 먼저, 문법 패턴 나중
- 빈도순 학습: 고빈도 N3 단어 우선
