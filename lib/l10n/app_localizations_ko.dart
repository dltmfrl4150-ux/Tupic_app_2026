// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'TUPIC';

  @override
  String helloUser(String name) {
    return '안녕하세요, $name!';
  }

  @override
  String get menuOpen => '메뉴 열기';

  @override
  String get menuClose => '메뉴 닫기';

  @override
  String get menuChannels => '채널 목록';

  @override
  String get menuCreateChannel => '채널 만들기';

  @override
  String get menuManageChannels => '채널 관리';

  @override
  String get menuImportSharedChannel => '공유 채널 가져오기';

  @override
  String get menuSettings => '설정';

  @override
  String get menuMyAccount => '내 계정';

  @override
  String get menuPremiumHint => 'Premium 요금제는 이후 단계에서 안내됩니다.';

  @override
  String get myChannels => '내 채널';

  @override
  String get recommended => '추천 콘텐츠';

  @override
  String get exploreMyContent => '내 콘텐츠 탐색';

  @override
  String get createChannelCard => '채널 만들기';

  @override
  String get kidsBadge => '키즈용';

  @override
  String get generalBadge => '일반';

  @override
  String videoCount(int count) {
    return '영상 $count개';
  }

  @override
  String get playChannel => '재생';

  @override
  String get categoryAll => '전체';

  @override
  String get categoryEnglish => '영어';

  @override
  String get categoryMusic => '음악';

  @override
  String get categoryScience => '과학';

  @override
  String get categoryArt => '미술';

  @override
  String get categoryAnimals => '동물';

  @override
  String get categoryOther => '기타';

  @override
  String get loading => '불러오는 중…';

  @override
  String get errorTitle => '문제가 발생했습니다';

  @override
  String get errorRetry => '다시 시도';

  @override
  String get emptyChannelsTitle => '아직 채널이 없습니다';

  @override
  String get emptyChannelsBody => '첫 TUPIC 채널을 만들어 YouTube 콘텐츠를 모아 보세요.';

  @override
  String get emptyRecommendedTitle => '추천 콘텐츠가 없습니다';

  @override
  String get emptyRecommendedBody => '채널에 인기 영상이 생기면 여기에 표시됩니다.';

  @override
  String get emptyExploreTitle => '이 카테고리에 영상이 없습니다';

  @override
  String get emptyExploreBody => '다른 카테고리를 선택하거나 채널에 영상을 더 추가해 보세요.';

  @override
  String get mockDataBanner => '데모 데이터 — 실제 계정과 연결되지 않습니다';

  @override
  String get demoContentBanner => '추천·탐색은 데모 콘텐츠입니다 — 저장된 영상이 아닙니다';

  @override
  String get comingSoonTitle => '준비 중';

  @override
  String get comingSoonBody => '이 기능은 이후 단계에서 제공됩니다.';

  @override
  String get comingSoonOk => '확인';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsLanguage => '언어 / Language';

  @override
  String get languageSystem => '자동 (기기 언어)';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get accountTitle => '내 계정';

  @override
  String get accountPlaceholder => 'Firebase Authentication 연동 후 로그인할 수 있습니다.';

  @override
  String get helloGuest => '안녕하세요!';

  @override
  String get accountGuestTitle => '계정';

  @override
  String get accountGuestBody =>
      'Google로 로그인하면 계정 정보를 확인할 수 있습니다. 로그인 없이도 로컬에서 채널을 계속 이용할 수 있습니다.';

  @override
  String get accountContinueWithGoogle => 'Google로 계속하기';

  @override
  String get accountSignOut => '로그아웃';

  @override
  String get accountSignedOut => '로그아웃되었습니다. 로컬 채널 데이터는 유지됩니다.';

  @override
  String get accountSignInSuccess => 'Google 로그인에 성공했습니다.';

  @override
  String get accountSignInFailed => '로그인에 실패했습니다. 다시 시도해 주세요.';

  @override
  String get accountSignInBusy => '로그인이 이미 진행 중입니다.';

  @override
  String get accountSignInNetworkError => '네트워크 오류입니다. 연결을 확인한 뒤 다시 시도해 주세요.';

  @override
  String get accountSignInUnavailable =>
      '이 빌드에서는 Google 로그인을 사용할 수 없습니다. Android Firebase 빌드에서 이용해 주세요.';

  @override
  String get accountConsentRequired => '서비스 이용을 위해 필수 약관에 동의해 주세요.';

  @override
  String get accountAnonymousName => 'Google 사용자';

  @override
  String get accountLocalDataNote =>
      '로컬에 저장된 채널·영상·이어보기는 이 Google 계정 소유로 표시되거나 자동 업로드되지 않습니다.';

  @override
  String get accountUnder14Policy =>
      '만 14세 미만의 독립 계정 가입은 법정대리인 동의 확인 절차가 준비되기 전까지 허용하지 않는 정책입니다. Google 계정만으로 연령이 확인되었다고 보지 않으며, 현재 단계에서 신뢰할 수 있는 연령 인증은 제공하지 않습니다.';

  @override
  String get createChannelDialogTitle => '채널 만들기';

  @override
  String get createChannelNameHint => '채널 이름';

  @override
  String get createChannelKidsCheckbox => '키즈용 채널';

  @override
  String get cancel => '취소';

  @override
  String get create => '만들기';

  @override
  String get save => '저장';

  @override
  String get delete => '삭제';

  @override
  String get channelNameRequired => '채널 이름을 입력해 주세요.';

  @override
  String get selectAudienceTitle => '어떤 콘텐츠를 탐색할까요?';

  @override
  String get selectAudienceKids => '키즈용 콘텐츠';

  @override
  String get selectAudienceGeneral => '일반 콘텐츠';

  @override
  String get back => '뒤로';

  @override
  String get premiumTitle => 'Premium';

  @override
  String get premiumBody => '더 많은 채널, 높은 한도, 자동 동기화. 결제는 아직 활성화되지 않았습니다.';

  @override
  String get premiumLimitTitle => '무료 플랜 채널 제한';

  @override
  String premiumLimitBody(int count) {
    return '무료 플랜에서는 채널을 최대 $count개까지 만들 수 있습니다. 더 많은 채널은 Premium에서 제공됩니다.';
  }

  @override
  String get premiumBillingDisabled => '이 버전에서는 결제가 활성화되지 않았습니다.';

  @override
  String get channelDetailTitle => '채널';

  @override
  String get channelNotFound => '이 채널을 찾을 수 없습니다.';

  @override
  String get manageThisChannel => '채널 관리';

  @override
  String get channelVideosComingSoon => 'YouTube 영상 추가는 다음 단계에서 제공됩니다.';

  @override
  String get playOrderLabel => '재생 순서';

  @override
  String get playOrderSequential => '순차';

  @override
  String get playOrderShuffle => '무작위';

  @override
  String get channelTypeLabel => '채널 유형';

  @override
  String get registeredVideosLabel => '등록 영상';

  @override
  String get channelRenamed => '채널 이름이 변경되었습니다.';

  @override
  String get deleteChannel => '채널 삭제';

  @override
  String get deleteChannelTitle => '채널을 삭제할까요?';

  @override
  String deleteChannelBody(String name) {
    return '\"$name\" 채널을 삭제할까요? 이 채널의 로컬 데이터만 삭제됩니다.';
  }

  @override
  String get parentalGateTitle => '보호자 확인';

  @override
  String get parentalGateBody => '키즈용 채널 관리로 이동하려면 출생연도를 입력해 주세요.';

  @override
  String get parentalGateHint => 'YYYY';

  @override
  String get parentalGateContinue => '계속';

  @override
  String get parentalGateInvalidYear => '출생연도 4자리를 올바르게 입력해 주세요.';

  @override
  String get parentalGateDenied => '18세 이상만 이용할 수 있습니다.';

  @override
  String get parentalGateDisclaimer => '법적 성인 인증이 아닌 간단한 접근 제한입니다.';

  @override
  String get importSharedPlaceholder => '공유 채널 가져오기는 이후 단계에서 제공됩니다.';

  @override
  String get addContentTitle => '콘텐츠 추가';

  @override
  String get manageContentTitle => '콘텐츠 관리';

  @override
  String get addContentUrlHint => 'YouTube 링크를 붙여넣으세요';

  @override
  String get paste => '붙여넣기';

  @override
  String get analyzeUrl => '분석';

  @override
  String get registerContent => '등록';

  @override
  String get displayNameHint => '표시 이름';

  @override
  String get contentTypeVideo => '개별 영상';

  @override
  String get contentTypePlaylist => '재생목록';

  @override
  String get contentTypeCreator => '유튜버';

  @override
  String get contentUrlEmpty => 'YouTube URL을 입력해 주세요.';

  @override
  String get contentUrlInvalid => '지원하지 않는 YouTube 링크입니다.';

  @override
  String get contentUrlUnsupportedHost => '공식 YouTube 링크만 사용할 수 있습니다.';

  @override
  String get contentUrlRedirectBlocked => '리디렉션 링크는 따라가지 않습니다.';

  @override
  String get contentDuplicateVideo => '이 채널에 이미 등록된 영상입니다.';

  @override
  String contentVideoLimit(int count) {
    return '무료 플랜에서는 채널당 영상을 최대 $count개까지 등록할 수 있습니다.';
  }

  @override
  String get contentAmbiguousTitle => '이 링크에는 영상과 재생목록이 함께 있습니다';

  @override
  String get contentAmbiguousVideo => '이 영상만 추가';

  @override
  String get contentAmbiguousPlaylist => '재생목록 전체 추가';

  @override
  String get playlistPendingFetch =>
      '재생목록 소스가 등록되었습니다. 영상 목록 가져오기는 YouTube API 연결 후 가능합니다.';

  @override
  String get creatorPendingFetch =>
      '유튜버 소스가 등록되었습니다. 영상 목록 가져오기는 YouTube API 연결 후 가능합니다.';

  @override
  String get creatorImportModeLabel => '가져오기 범위';

  @override
  String get creatorImportRecent30 => '최근 30개';

  @override
  String get creatorImportAll => '전체 영상';

  @override
  String get creatorImportManual => '직접 선택';

  @override
  String get creatorManualNeedsApi => '직접 선택은 YouTube API 연결 후 사용할 수 있습니다.';

  @override
  String get creatorSortLabel => '정렬 방식';

  @override
  String get creatorSortNewest => '최신순';

  @override
  String get creatorSortOldest => '오래된순';

  @override
  String get creatorSortShuffle => '무작위';

  @override
  String get autoSyncLabel => '자동 동기화 (Premium)';

  @override
  String get autoSyncFreeLocked => '자동 동기화는 Premium 전용이며 아직 실행되지 않습니다.';

  @override
  String get autoSyncPremiumHint => 'Premium은 하루 1회 확인이 가능합니다(현재 빌드에서는 비활성).';

  @override
  String get contentSourcesSection => '콘텐츠 소스';

  @override
  String get contentVideosSection => '영상 목록';

  @override
  String get emptySourcesBody => '아직 등록된 콘텐츠 소스가 없습니다. YouTube 링크를 추가해 보세요.';

  @override
  String get emptyVideosBody => '확인된 영상이 없습니다. 개별 영상 링크는 바로 여기에 표시됩니다.';

  @override
  String get apiNotConnectedBanner =>
      '재생목록·유튜버 영상은 YouTube API 연결 전까지 가져오지 않습니다.';

  @override
  String get importStatusReady => '준비됨';

  @override
  String get importStatusPending => '가져오기 대기';

  @override
  String get importStatusFetching => '가져오는 중';

  @override
  String get importStatusFetched => '가져오기 완료';

  @override
  String get importStatusPartial => '일부만 가져옴';

  @override
  String get importStatusFailed => '실패';

  @override
  String get fetchPlaylistVideos => '영상 가져오기';

  @override
  String get retryFetchPlaylist => '다시 시도';

  @override
  String playlistFetchedCount(int count) {
    return '영상 $count개 가져옴';
  }

  @override
  String playlistFetchReport(
    int imported,
    int privateDeleted,
    int notEmbeddable,
    int duplicates,
  ) {
    return '가져온 영상: $imported개 · 비공개·삭제 영상 제외: $privateDeleted개 · 임베드 불가 영상 제외: $notEmbeddable개 · 중복 영상: $duplicates개';
  }

  @override
  String playlistFetchReportPruned(int pruned) {
    return '기존 재생 불가 영상 $pruned개 정리됨';
  }

  @override
  String get localServerRequired =>
      '로컬 YouTube 서버가 필요합니다. server 폴더에서 npm start를 실행하세요.';

  @override
  String get localApiKeyRequired =>
      '로컬 서버에 YOUTUBE_API_KEY가 설정되지 않았습니다. server/.env를 확인하세요.';

  @override
  String get quotaExceededMessage => 'YouTube API 할당량이 초과되었습니다. 잠시 후 다시 시도하세요.';

  @override
  String get dailyLocalLimitMessage => '로컬 일일 API 요청 한도에 도달했습니다.';

  @override
  String get playlistFetchUnexpectedError =>
      '재생목록을 가져오지 못했습니다. 앱을 완전히 재시작한 뒤 로컬 서버(npm start)를 확인하고 다시 시도하세요.';

  @override
  String lastFetchedAtLabel(String time) {
    return '마지막 조회: $time';
  }

  @override
  String videoLimitLabel(int current, int max) {
    return '$current / $max';
  }

  @override
  String queuePreviewCount(int count) {
    return '재생 큐: $count개';
  }

  @override
  String get deleteSourceTitle => '콘텐츠 소스를 삭제할까요?';

  @override
  String deleteSourceBody(String name) {
    return '\"$name\" 소스를 삭제할까요? 이 소스에만 연결된 영상은 제거되고, 다른 소스에도 연결된 영상은 유지됩니다.';
  }

  @override
  String deleteSourceResult(int removed, int kept) {
    return '영상 $removed개 제거, 공유 영상 $kept개 유지';
  }

  @override
  String get deleteVideoTitle => '영상을 삭제할까요?';

  @override
  String deleteVideoBody(String title) {
    return '\"$title\" 영상을 이 채널에서 삭제할까요?';
  }

  @override
  String get excludeVideo => '재생에서 제외';

  @override
  String get restoreVideo => '재생에 복원';

  @override
  String get videoExcluded => '제외됨';

  @override
  String get reorderHint => '길게 눌러 드래그하면 영상 순서를 바꿀 수 있습니다.';

  @override
  String get playerPause => '일시정지';

  @override
  String get playerVideoList => '영상 목록';

  @override
  String get playerSwitchChannel => '채널 전환';

  @override
  String get playerChannelListTitle => 'TUPICK 채널';

  @override
  String get playerLock => '화면 잠금';

  @override
  String get playerUnlock => '잠금 해제';

  @override
  String get playerUnlockHint => '길게 눌러 잠금해제';

  @override
  String get playerNextVideo => '다음 영상';

  @override
  String get playerRetry => '다시 시도';

  @override
  String get playerEmptyQueue => '재생할 영상이 없습니다';

  @override
  String get playerVideoUnavailable => '이 영상은 재생할 수 없습니다';

  @override
  String get playerAllVideosUnavailable => '재생 가능한 영상이 큐에 남아 있지 않습니다';

  @override
  String get playerPlaybackError => '재생 중 오류가 발생했습니다';

  @override
  String get playerLastVideo => '마지막 영상입니다';

  @override
  String get playerReplayQueue => '처음부터 다시 재생';

  @override
  String get playerWebOrientationHint =>
      '웹에서는 화면 방향을 고정할 수 없습니다. 가로 레이아웃으로 시청하세요.';

  @override
  String get playNow => '바로 재생';

  @override
  String get playerResume => '이어보기';

  @override
  String get playerLastPosition => '마지막 시청 위치';

  @override
  String get playerPreparing => '재생 준비 중…';

  @override
  String get playlistFetchPending => '영상 가져오기 대기';

  @override
  String get playlistVideosNotFetchedYet =>
      '아직 재생목록의 영상을 가져오지 않았습니다. 콘텐츠 관리에서 「영상 가져오기」를 누르세요.';

  @override
  String get playableVideosOnlyHint => '확인된 재생 가능 영상만 표시됩니다.';

  @override
  String sourceVsPlayableCount(int sources, int playable) {
    return '소스 $sources개 · 재생 가능 $playable개';
  }

  @override
  String get settingsLegalSection => '약관 및 개인정보';

  @override
  String get termsOfServiceTitle => '이용약관';

  @override
  String get privacyPolicyTitle => '개인정보처리방침';

  @override
  String get legalView => '자세히 보기';

  @override
  String legalVersionLabel(String version) {
    return '문서 버전 $version';
  }

  @override
  String get legalDraftNotice =>
      '본문은 초안입니다. 사업자·연락처 등 미확정 항목은 문서 내 TODO로 표시됩니다.';

  @override
  String get legalKoreanDraftNotice =>
      '본문은 초안입니다. 사업자·연락처 등 미확정 항목은 문서 내 TODO로 표시됩니다.';

  @override
  String get consentTitle => 'TUPICK 서비스 이용 안내';

  @override
  String get consentSubtitle =>
      '필수 항목에 동의하면 다음 단계로 진행할 수 있습니다. 문서를 열람만 한 경우에는 동의로 처리되지 않습니다.';

  @override
  String get consentTermsRequired => '[필수] 이용약관 동의';

  @override
  String get consentPrivacyCollectionRequired => '[필수] 개인정보 수집·이용 동의';

  @override
  String get privacyPolicyViewAlways => '개인정보처리방침 보기';

  @override
  String get consentContinue => '동의하고 계속';
}
