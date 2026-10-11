class_name StatusLabel
extends Label

## 플레이어 머리 위에 짧게 상태 텍스트를 표시한다.


## duration이 0이면 hide_text()로 지우거나 다른 텍스트로 덮일 때까지 유지된다.
func show_text(value: String, color: Color, duration: float = 0.6) -> void:
	text = value
	modulate = color
	visible = true

	if duration > 0.0:
		get_tree().create_timer(duration).timeout.connect(hide_text.bind(value))


## 지정한 텍스트가 아직 표시 중일 때만 숨긴다 (그 사이 다른 텍스트로 바뀌었으면 유지).
func hide_text(value: String) -> void:
	if text == value:
		visible = false
