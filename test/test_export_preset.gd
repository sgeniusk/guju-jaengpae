# 릴리스 타깃 export preset이 소스에 남아 있고 민감정보 없이 파싱되는지 검증한다.
extends TestCase

const PRESET_PATH := "res://export_presets.cfg"

var cfg := ConfigFile.new()

func before_each() -> void:
	cfg = ConfigFile.new()
	cfg.load(PRESET_PATH)

func test_macos_desktop_preset_is_present_and_runnable() -> void:
	eq(cfg.load(PRESET_PATH), OK, "export_presets.cfg 로드")
	eq(cfg.get_value("preset.0", "name", ""), "macOS Desktop", "preset 이름")
	eq(cfg.get_value("preset.0", "platform", ""), "macOS", "macOS platform")
	truthy(cfg.get_value("preset.0", "runnable", false), "runnable preset")
	falsy(cfg.get_value("preset.0", "dedicated_server", true), "desktop export는 dedicated server 아님")
	eq(cfg.get_value("preset.0", "export_path", ""), "build/macos/guju-jaengpae.zip", "기본 export 출력 경로")

func test_export_preset_keeps_resource_and_secret_policy_clear() -> void:
	eq(cfg.get_value("preset.0", "export_filter", ""), "all_resources", "프로젝트 리소스 export")
	truthy(String(cfg.get_value("preset.0", "exclude_filter", "")).contains("docs/reports/**"), "보고용 스크린샷 제외")
	truthy(String(cfg.get_value("preset.0", "exclude_filter", "")).contains("test/**"), "테스트 스크립트 제외")
	truthy(String(cfg.get_value("preset.0", "exclude_filter", "")).contains("tools/**"), "개발 도구 스크립트 제외")
	falsy(cfg.get_value("preset.0", "encrypt_pck", true), "PCK 암호화 비활성")
	falsy(cfg.get_value("preset.0", "encrypt_directory", true), "디렉터리 암호화 비활성")
	eq(cfg.get_value("preset.0", "script_export_mode", 0), 2, "스크립트 컴파일 export")

func test_macos_options_are_release_ready_without_credentials() -> void:
	eq(cfg.get_value("preset.0.options", "export/distribution_type", 0), 1, "distribution export")
	eq(cfg.get_value("preset.0.options", "binary_format/architecture", ""), "universal", "universal binary")
	eq(cfg.get_value("preset.0.options", "application/bundle_identifier", ""), "com.taewookkim.gujujaengpae", "bundle id")
	eq(cfg.get_value("preset.0.options", "application/app_category", ""), "Games", "앱 카테고리")
	eq(cfg.get_value("preset.0.options", "application/short_version", ""), "0.7.0", "short version")
	eq(cfg.get_value("preset.0.options", "application/version", ""), "0.7.0", "version")
	eq(cfg.get_value("preset.0.options", "custom_template/release", "secret"), "", "custom release template 없음")
	eq(cfg.get_value("preset.0.options", "codesign/identity", "secret"), "", "서명 identity 미포함")
	eq(cfg.get_value("preset.0.options", "notarization/notarization", -1), 0, "notarization 비활성")
	eq(cfg.get_value("preset.0.options", "notarization/apple_id_password", "secret"), "", "notarization password 미포함")
