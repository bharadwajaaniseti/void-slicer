extends CanvasLayer

signal push_deeper_requested
signal extract_requested

var decision_made: bool = false

@onready var depth_value: Label = %DepthValue
@onready var cash_value: Label = %CashValue
@onready var shards_value: Label = %ShardsValue
@onready var bosses_value: Label = %BossesValue
@onready var scaling_value: Label = %ScalingValue
@onready var push_button: Button = %PushButton
@onready var extract_button: Button = %ExtractButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	push_button.pressed.connect(_choose_push)
	extract_button.pressed.connect(_choose_extract)


func setup(depth: int, cash: float, shards: int, bosses: int, enemy_health: float, boss_health: float, rewards: float) -> void:
	depth_value.text = str(depth)
	cash_value.text = str(roundi(cash))
	shards_value.text = str(shards)
	bosses_value.text = str(bosses)
	scaling_value.text = "NEXT DEPTH\nEnemy health +%d%%\nBoss health +%d%%\nResources +%d%%" % [roundi((enemy_health - 1.0) * 100.0), roundi((boss_health - 1.0) * 100.0), roundi((rewards - 1.0) * 100.0)]


func _choose_push() -> void:
	if decision_made: return
	decision_made = true
	_set_disabled()
	push_deeper_requested.emit()


func _choose_extract() -> void:
	if decision_made: return
	decision_made = true
	_set_disabled()
	extract_requested.emit()


func _set_disabled() -> void:
	push_button.disabled = true
	extract_button.disabled = true

