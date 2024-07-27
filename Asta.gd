extends CharacterBody3D


var speed = 1.5
const JUMP_VELOCITY = 4.5
const ROTATION_SPEED: float = 0.15

@onready var pivot = $CamOrigin
@onready var armature = $Armature
@onready var anim_tree = $AnimationTree
@export var sens = 0.2

enum {IDLE, RUN, WALK}
var curAnim = IDLE
var battle = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * sens))
		armature.rotate_y(deg_to_rad(event.relative.x * sens))
		pivot.rotate_x(deg_to_rad(-event.relative.y * sens))
		pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(-90), deg_to_rad(45))
		
func _physics_process(delta):
	handle_animations()
	
	if not is_on_floor():
		velocity.y -= gravity * delta


	# Handle Jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		jump()
		
	if Input.is_action_pressed("Attack") and is_on_floor():
		battle = true
		anim_tree.set("parameters/Battle/transition_request", "Fighting")
		anim_tree.set("parameters/Attack/transition_request", "Single_Attack")
	elif Input.is_action_pressed("Block") and is_on_floor():
		battle = true
		anim_tree.set("parameters/Battle/transition_request", "Fighting")
		anim_tree.set("parameters/Attack/transition_request", "Block")
	else:
		battle = false
		anim_tree.set("parameters/Battle/transition_request", "Normal")
	
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var input_angle: float = input_dir.angle_to(Vector2.DOWN)
	var input_length: float = input_dir.length()

	# Face character in direction of input
	if input_length > 0:
		armature.rotation.y = lerp_angle(
			armature.rotation.y,
			# Away from camera
			pivot.rotation.y + input_angle,
			#(input_angle if input_angle > (-PI / 2) else 0),
			ROTATION_SPEED
		)
		

	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		if Input.is_action_pressed("Sprint"):
			speed = 5
		else:
			speed = 1.5
			
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		if is_on_floor():
			if Input.is_action_pressed("Sprint"):
				curAnim = RUN
			else:
				curAnim = WALK
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		if is_on_floor():
			curAnim = IDLE

	move_and_slide()
	
func _walk():
	return Input.is_action_pressed("up") or Input.is_action_pressed("down") or Input.is_action_pressed("left") or Input.is_action_pressed("right")

func handle_animations():
	if !battle:
		match curAnim:
			IDLE:
				anim_tree.set("parameters/Movement/transition_request", "Idle")
			WALK :
				anim_tree.set("parameters/Movement/transition_request", "Walk")
			RUN :
				anim_tree.set("parameters/Movement/transition_request", "Run")

func jump():
	anim_tree.set("parameters/Jump/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
