# 카드 데이터의 허용 값 사전 — 검증과 일관성 유지용. docs/worldview.md 스키마와 일치.
class_name CardVocab

const REALMS := ["mortal", "heaven", "demon"]            # 三界
const NATIONS := ["wei", "shu", "wu"]                    # 현세 3국. 천계·마계는 후속 세션 확장.
const CARD_TYPES := ["general", "troop", "scheme", "treasure", "building"]
const TROOP_TYPES := ["infantry", "archer", "cavalry", "crossbow", "navy", "fantasy"]
const FANTASY_TIERS := ["historical", "romance", "heroic", "mythic"]
const ATTACK_RANGES := ["melee", "ranged"]
const TARGET_RULES := ["nearest", "backline", "strongest_ranged", "lowest_hp", "highest_hp"]

static func is_in(value: String, allowed: Array) -> bool:
	return value in allowed
