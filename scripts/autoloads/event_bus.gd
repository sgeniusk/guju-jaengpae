# 시스템 간 결합을 끊는 신호 중계 싱글톤. 발신자는 여기로 emit, 수신자는 여기에 connect.
extends Node

## 전투 루프 신호 (feat-003/004에서 사용)
signal battle_started(lord_id: StringName)
signal wave_cleared(wave_index: int)
signal battle_won
signal battle_lost
signal card_rewarded(card_id: StringName)
