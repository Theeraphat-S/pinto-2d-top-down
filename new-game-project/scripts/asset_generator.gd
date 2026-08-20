@tool
extends SceneTree

# ==============================================================================
# PINTO 2D TOP-DOWN SURVIVAL ARENA - ASSET GENERATOR (Milestone M1)
# Procedurally drafts and saves all pixel art PNG textures and native WAV sfx.
# ==============================================================================

# Master Color Palette Constants
const C_CLEAR := Color(0, 0, 0, 0)
const C_WHITE := Color("#FFFFFF")
const C_CREAM := Color("#F1F5F9")
const C_SLATE_LIGHT := Color("#94A3B8")
const C_SLATE_MID := Color("#475569")
const C_SLATE_DARK := Color("#1E293B")
const C_NAVY := Color("#0F172A")
const C_DARK_BG := Color("#0B1120")

# Accent Colors
const C_MINT := Color("#2DD4BF")
const C_MINT_DARK := Color("#0D9488")
const C_EMERALD := Color("#10B981")
const C_EMERALD_LIGHT := Color("#34D399")
const C_EMERALD_DARK := Color("#064E3B")
const C_CYAN := Color("#06B6D4")
const C_CYAN_LIGHT := Color("#38BDF8")
const C_CYAN_GLOW := Color("#22D3EE")
const C_BLUE_SKY := Color("#0284C7")
const C_BLUE_DARK := Color("#0369A1")
const C_TEAL_SKIRT := Color("#0E7490")
const C_ROSE := Color("#F43F5E")
const C_BLUSH := Color("#FB7185")
const C_RUBY := Color("#E11D48")
const C_GOLD := Color("#F59E0B")
const C_GOLD_LIGHT := Color("#FDE68A")
const C_PURPLE := Color("#8B5CF6")
const C_PURPLE_LIGHT := Color("#C084FC")
const C_PURPLE_DARK := Color("#4C1D95")
const C_ORANGE := Color("#FB923C")

func _init() -> void:
	print("[AssetGenerator] Starting asset generation...")
	generate_all()
	print("[AssetGenerator] All assets generated and saved successfully!")
	quit(0)

static func generate_all(base_res: String = "res://assets/") -> void:
	_ensure_directories(base_res)
	
	_generate_pinto_spritesheet(base_res + "sprites/pinto_spritesheet.png")
	
	_generate_slime_sprite(base_res + "sprites/enemies/slime.png")
	_generate_bat_sprite(base_res + "sprites/enemies/bat.png")
	_generate_drone_sprite(base_res + "sprites/enemies/drone.png")
	_generate_golem_sprite(base_res + "sprites/enemies/golem.png")
	_generate_boss_sprite(base_res + "sprites/enemies/boss_giga_null.png")
	
	_generate_bullet_sprite(base_res + "sprites/projectiles/bullet.png")
	_generate_energy_orb_sprite(base_res + "sprites/projectiles/energy_orb.png")
	_generate_laser_sprite(base_res + "sprites/projectiles/laser.png")
	
	_generate_xp_small_sprite(base_res + "sprites/pickups/xp_small.png")
	_generate_xp_med_sprite(base_res + "sprites/pickups/xp_med.png")
	_generate_xp_large_sprite(base_res + "sprites/pickups/xp_large.png")
	
	_generate_arena_tileset(base_res + "tilesets/arena_tileset.png")
	_generate_props(base_res + "tilesets/props.png")
	
	_generate_card_background(base_res + "ui/card_background.png")
	_generate_ui_icons(base_res + "ui/icons/")
	# Also save in ui/ root for direct fallback access
	_generate_ui_icons(base_res + "ui/")
	
	_generate_sfx(base_res + "sfx/")

static func _ensure_directories(base_res: String) -> void:
	var dirs := [
		base_res,
		base_res + "sprites",
		base_res + "sprites/enemies",
		base_res + "sprites/projectiles",
		base_res + "sprites/pickups",
		base_res + "tilesets",
		base_res + "ui",
		base_res + "ui/icons",
		base_res + "sfx"
	]
	for d in dirs:
		var global_dir := ProjectSettings.globalize_path(d)
		DirAccess.make_dir_recursive_absolute(global_dir)

# ==============================================================================
# DRAWING UTILITIES
# ==============================================================================

static func _set_pixel_safe(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
		if color.a < 1.0 and color.a > 0.0:
			var prev := img.get_pixel(x, y)
			img.set_pixel(x, y, prev.blend(color))
		else:
			img.set_pixel(x, y, color)

static func _draw_rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for dy in range(h):
		for dx in range(w):
			_set_pixel_safe(img, x + dx, y + dy, color)

static func _draw_outline_rect(img: Image, x: int, y: int, w: int, h: int, fill: Color, border: Color) -> void:
	_draw_rect(img, x, y, w, h, fill)
	for dx in range(w):
		_set_pixel_safe(img, x + dx, y, border)
		_set_pixel_safe(img, x + dx, y + h - 1, border)
	for dy in range(h):
		_set_pixel_safe(img, x, y + dy, border)
		_set_pixel_safe(img, x + w - 1, y + dy, border)

static func _draw_circle(img: Image, cx: int, cy: int, r: int, color: Color) -> void:
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if dx * dx + dy * dy <= r * r:
				_set_pixel_safe(img, cx + dx, cy + dy, color)

static func _draw_line(img: Image, x0: int, y0: int, x1: int, y1: int, color: Color) -> void:
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	var x := x0
	var y := y0
	while true:
		_set_pixel_safe(img, x, y, color)
		if x == x1 and y == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy

# ==============================================================================
# 1. PINTO SPRITESHEET GENERATION
# ==============================================================================

static func _generate_pinto_spritesheet(path: String) -> void:
	# 8 columns x 4 rows of 32x32 frames -> 256x128 image
	var img := Image.create(256, 128, false, Image.FORMAT_RGBA8)
	img.fill(C_CLEAR)
	
	# Row 0: Idle (frames 0-3), Walk Down (frames 4-7)
	for i in range(4):
		_draw_pinto_frame(img, i * 32, 0, "idle", i)
	for i in range(4):
		_draw_pinto_frame(img, (4 + i) * 32, 0, "walk_down", i)
		
	# Row 1: Walk Up (frames 8-11), Walk Side (frames 12-15)
	for i in range(4):
		_draw_pinto_frame(img, i * 32, 32, "walk_up", i)
	for i in range(4):
		_draw_pinto_frame(img, (4 + i) * 32, 32, "walk_side", i)
		
	# Row 2: Hurt (frames 16-17), Death (frames 18-23)
	for i in range(2):
		_draw_pinto_frame(img, i * 32, 64, "hurt", i)
	for i in range(6):
		_draw_pinto_frame(img, (2 + i) * 32, 64, "death", i)
		
	# Row 3: Attack Burst (frames 24-25), Victory / Cheer (frames 26-31)
	for i in range(2):
		_draw_pinto_frame(img, i * 32, 96, "attack", i)
	for i in range(6):
		_draw_pinto_frame(img, (2 + i) * 32, 96, "victory", i)
		
	img.save_png(ProjectSettings.globalize_path(path))
	print("[AssetGenerator] Pinto spritesheet generated: ", path)

static func _draw_pinto_frame(img: Image, ox: int, oy: int, anim: String, frame_idx: int) -> void:
	var bob_y: int = 0
	var leg_offset: int = 0
	var eye_state: String = "open"
	var show_back: bool = (anim == "walk_up")
	var is_side: bool = (anim == "walk_side")
	var is_hurt: bool = (anim == "hurt")
	var is_death: bool = (anim == "death")
	var is_victory: bool = (anim == "victory")
	
	if anim == "idle":
		if frame_idx == 1 or frame_idx == 2:
			bob_y = 1
		if frame_idx == 3:
			eye_state = "blink"
	elif anim == "walk_down":
		bob_y = 1 if (frame_idx % 2 == 1) else 0
		leg_offset = 1 if (frame_idx == 0 or frame_idx == 1) else -1
	elif anim == "walk_up":
		bob_y = 1 if (frame_idx % 2 == 1) else 0
		leg_offset = 1 if (frame_idx == 0 or frame_idx == 1) else -1
	elif anim == "walk_side":
		bob_y = 1 if (frame_idx % 2 == 1) else 0
		leg_offset = 1 if (frame_idx == 0 or frame_idx == 1) else -1
	elif anim == "hurt":
		bob_y = -1
		eye_state = "squeeze"
	elif anim == "death":
		if frame_idx < 3:
			eye_state = "dizzy"
			bob_y = frame_idx
		else:
			eye_state = "closed"
			bob_y = 4
	elif anim == "victory":
		bob_y = -2 if (frame_idx % 2 == 1) else 0
		eye_state = "joy"

	# Shadow under feet
	if not is_death or frame_idx < 4:
		_draw_circle(img, ox + 16, oy + 30, 6, Color(0, 0, 0, 0.35))
		
	# Death smoke poof on later frames
	if is_death and frame_idx >= 3:
		_draw_circle(img, ox + 8 + frame_idx * 2, oy + 26, 4, Color(C_CYAN_LIGHT.r, C_CYAN_LIGHT.g, C_CYAN_LIGHT.b, 0.4))
		_draw_circle(img, ox + 24 - frame_idx * 2, oy + 24, 3, Color(C_MINT.r, C_MINT.g, C_MINT.b, 0.5))

	var hx := ox + 5
	var hy := oy + 4 + bob_y
	
	if is_side:
		hx += 2
	
	# 1. Top Carrying Handle
	if not (is_death and frame_idx >= 2):
		_draw_outline_rect(img, ox + 10, hy - 3, 12, 4, C_CREAM, C_NAVY)
		_draw_rect(img, ox + 14, hy - 3, 4, 2, C_EMERALD) # Emerald Grip
		
	# 2. Rounded Cooler Head Chassis (22w x 16h)
	if is_side:
		_draw_outline_rect(img, hx, hy, 18, 16, C_WHITE, C_NAVY)
		_draw_rect(img, hx + 1, hy + 1, 16, 14, C_CREAM)
		_draw_rect(img, hx + 1, hy + 1, 14, 2, C_WHITE)
	else:
		_draw_outline_rect(img, hx, hy, 22, 16, C_WHITE, C_NAVY)
		# Inner fill with rounded corners and highlights
		_draw_rect(img, hx + 1, hy + 1, 20, 14, C_CREAM)
		_draw_rect(img, hx + 2, hy + 1, 18, 2, C_WHITE) # Top shine
		_draw_rect(img, hx + 1, hy + 2, 2, 12, C_WHITE) # Left shine
		_draw_rect(img, hx + 19, hy + 2, 2, 12, C_SLATE_LIGHT) # Right shadow
		
	# 3. Mint Visor Band
	if not show_back:
		if is_side:
			_draw_rect(img, hx + 6, hy + 4, 11, 3, C_MINT)
			_draw_rect(img, hx + 6, hy + 6, 11, 1, C_MINT_DARK)
		else:
			_draw_rect(img, hx + 2, hy + 4, 18, 3, C_MINT)
			_draw_rect(img, hx + 2, hy + 6, 18, 1, C_MINT_DARK)
	else:
		_draw_rect(img, hx + 2, hy + 4, 18, 2, C_SLATE_LIGHT)
		
	# 4. Over-Ear Headphones (Left / Right)
	if not is_side:
		# Left Earcup
		_draw_outline_rect(img, ox + 2, hy + 4, 5, 8, C_WHITE, C_NAVY)
		_draw_circle(img, ox + 4, hy + 8, 2, C_EMERALD)
		_draw_pixel(img, ox + 4, hy + 7, C_EMERALD_LIGHT)
		# Right Earcup
		_draw_outline_rect(img, ox + 25, hy + 4, 5, 8, C_WHITE, C_NAVY)
		_draw_circle(img, ox + 27, hy + 8, 2, C_EMERALD)
		_draw_pixel(img, ox + 27, hy + 7, C_EMERALD_LIGHT)
		# Audio pulse effect for attack
		if anim == "attack":
			_draw_circle(img, ox + 2, hy + 8, 4, Color(C_CYAN_GLOW.r, C_CYAN_GLOW.g, C_CYAN_GLOW.b, 0.5))
			_draw_circle(img, ox + 29, hy + 8, 4, Color(C_CYAN_GLOW.r, C_CYAN_GLOW.g, C_CYAN_GLOW.b, 0.5))
	else:
		# Side Earcup (Center of side head)
		_draw_outline_rect(img, hx + 3, hy + 4, 7, 9, C_WHITE, C_NAVY)
		_draw_circle(img, hx + 6, hy + 8, 3, C_EMERALD)
		_draw_pixel(img, hx + 6, hy + 7, C_EMERALD_LIGHT)
		
	# 5. Face Features (Eyes, Blush, Mouth)
	if not show_back and not is_side:
		if eye_state == "open":
			# Left Eye
			_draw_rect(img, hx + 4, hy + 8, 4, 5, C_BLUE_SKY)
			_draw_rect(img, hx + 4, hy + 8, 4, 2, C_NAVY)
			_draw_rect(img, hx + 4, hy + 11, 4, 2, C_CYAN_LIGHT)
			_draw_pixel(img, hx + 6, hy + 9, C_WHITE) # Highlight
			# Right Eye
			_draw_rect(img, hx + 14, hy + 8, 4, 5, C_BLUE_SKY)
			_draw_rect(img, hx + 14, hy + 8, 4, 2, C_NAVY)
			_draw_rect(img, hx + 14, hy + 11, 4, 2, C_CYAN_LIGHT)
			_draw_pixel(img, hx + 16, hy + 9, C_WHITE) # Highlight
		elif eye_state == "blink":
			_draw_line(img, hx + 4, hy + 10, hx + 7, hy + 10, C_NAVY)
			_draw_line(img, hx + 14, hy + 10, hx + 17, hy + 10, C_NAVY)
		elif eye_state == "squeeze":
			# >.< Eyes
			_draw_line(img, hx + 4, hy + 9, hx + 6, hy + 11, C_NAVY)
			_draw_line(img, hx + 4, hy + 13, hx + 6, hy + 11, C_NAVY)
			_draw_line(img, hx + 17, hy + 9, hx + 15, hy + 11, C_NAVY)
			_draw_line(img, hx + 17, hy + 13, hx + 15, hy + 11, C_NAVY)
		elif eye_state == "dizzy":
			# @.@ Spiral Eyes
			_draw_rect(img, hx + 4, hy + 9, 4, 4, C_CYAN)
			_draw_pixel(img, hx + 5, hy + 10, C_NAVY)
			_draw_rect(img, hx + 14, hy + 9, 4, 4, C_CYAN)
			_draw_pixel(img, hx + 15, hy + 10, C_NAVY)
		elif eye_state == "joy":
			# ^.^ Eyes
			_draw_line(img, hx + 4, hy + 11, hx + 6, hy + 9, C_NAVY)
			_draw_line(img, hx + 6, hy + 9, hx + 8, hy + 11, C_NAVY)
			_draw_line(img, hx + 14, hy + 11, hx + 16, hy + 9, C_NAVY)
			_draw_line(img, hx + 16, hy + 9, hx + 18, hy + 11, C_NAVY)
			
		# Cheeks Blush
		_draw_rect(img, hx + 2, hy + 12, 3, 1, C_BLUSH)
		_draw_rect(img, hx + 17, hy + 12, 3, 1, C_BLUSH)
		
		# Cheerful Mouth
		if eye_state == "joy":
			_draw_rect(img, hx + 9, hy + 12, 4, 2, C_RUBY)
		elif eye_state != "squeeze" and eye_state != "dizzy":
			_draw_pixel(img, hx + 10, hy + 13, C_RUBY)
			_draw_pixel(img, hx + 11, hy + 13, C_RUBY)
	elif is_side:
		if eye_state == "open":
			_draw_rect(img, hx + 12, hy + 8, 3, 5, C_BLUE_SKY)
			_draw_rect(img, hx + 12, hy + 8, 3, 2, C_NAVY)
			_draw_pixel(img, hx + 14, hy + 9, C_WHITE)
		_draw_rect(img, hx + 12, hy + 13, 2, 1, C_BLUSH)
		_draw_pixel(img, hx + 15, hy + 13, C_RUBY)
		
	# 6. Sailor Vest & Torso
	var tx := ox + 10
	var ty := hy + 16
	if is_side:
		tx = hx + 4
		_draw_outline_rect(img, tx, ty, 8, 5, C_NAVY, C_NAVY)
		_draw_rect(img, tx + 1, ty + 1, 6, 3, C_SLATE_DARK)
		_draw_rect(img, tx + 6, ty + 1, 2, 4, C_CYAN) # Side tie
	else:
		_draw_outline_rect(img, tx, ty, 12, 5, C_NAVY, C_NAVY)
		_draw_rect(img, tx + 1, ty + 1, 10, 3, C_SLATE_DARK)
		if not show_back:
			# Cyan Collar & Pointed Tie
			_draw_rect(img, tx + 4, ty, 4, 2, C_CYAN)
			_draw_rect(img, tx + 5, ty + 2, 2, 3, C_CYAN_LIGHT)
			_draw_pixel(img, tx + 5, ty + 4, C_CYAN)
		else:
			# Rear Sailor Collar
			_draw_rect(img, tx + 2, ty, 8, 3, C_CYAN)
			_draw_rect(img, tx + 3, ty + 1, 6, 1, C_WHITE)
			
	# 7. Pleated Skirt
	var sk_y := ty + 5
	if is_side:
		_draw_rect(img, tx - 1, sk_y, 10, 4, C_TEAL_SKIRT)
		_draw_pixel(img, tx + 3, sk_y + 1, C_CYAN)
		_draw_pixel(img, tx + 6, sk_y + 1, C_CYAN)
	else:
		_draw_rect(img, tx - 2, sk_y, 16, 4, C_TEAL_SKIRT)
		# Pleats
		_draw_line(img, tx + 1, sk_y, tx + 1, sk_y + 3, C_NAVY)
		_draw_line(img, tx + 5, sk_y, tx + 5, sk_y + 3, C_NAVY)
		_draw_line(img, tx + 9, sk_y, tx + 9, sk_y + 3, C_NAVY)
		
	# 8. Legs & Shoes
	var leg_y := sk_y + 4
	if is_side:
		var lx := tx + 2
		_draw_rect(img, lx + leg_offset, leg_y, 3, 2, C_CREAM)
		_draw_rect(img, lx + leg_offset, leg_y + 2, 4, 2, C_NAVY) # Shoe
	else:
		# Left Leg
		_draw_rect(img, tx + 1, leg_y + (1 if leg_offset > 0 else 0), 3, 2, C_CREAM)
		_draw_rect(img, tx + 1, leg_y + 2 + (1 if leg_offset > 0 else 0), 3, 2, C_NAVY)
		# Right Leg
		_draw_rect(img, tx + 8, leg_y + (1 if leg_offset < 0 else 0), 3, 2, C_CREAM)
		_draw_rect(img, tx + 8, leg_y + 2 + (1 if leg_offset < 0 else 0), 3, 2, C_NAVY)
		
	# Victory Stars Particles
	if is_victory:
		_draw_pixel(img, ox + 4, oy + 4, C_GOLD)
		_draw_pixel(img, ox + 27, oy + 6, C_GOLD_LIGHT)
		_draw_pixel(img, ox + 28, oy + 5, C_GOLD)

static func _draw_pixel(img: Image, x: int, y: int, color: Color) -> void:
	_set_pixel_safe(img, x, y, color)

# ==============================================================================
# 2. ENEMY SPRITES GENERATION
# ==============================================================================

static func _generate_slime_sprite(path: String) -> void:
	# 4 frames 32x32 -> 128x32
	var img := Image.create(128, 32, false, Image.FORMAT_RGBA8)
	img.fill(C_CLEAR)
	
	for f in range(4):
		var ox := f * 32
		var squish: int = 0
		if f == 1: squish = 2 # Squashed
		elif f == 2: squish = -2 # Stretched high
		
		# Shadow
		_draw_circle(img, ox + 16, 28, 7, Color(0, 0, 0, 0.3))
		
		# Slime body
		var bx := ox + 6 - squish
		var by := 12 + squish
		var bw := 20 + squish * 2
		var bh := 16 - squish
		
		_draw_outline_rect(img, bx, by, bw, bh, C_EMERALD, C_EMERALD_DARK)
		_draw_rect(img, bx + 2, by + 2, bw - 4, bh - 4, C_EMERALD_LIGHT)
		# Glitch pixels
		_draw_pixel(img, bx + 3, by + 3, C_WHITE)
		_draw_pixel(img, bx + bw - 4, by + 4, C_CYAN_GLOW)
		_draw_pixel(img, bx + 4, by + bh - 4, C_MINT)
		
		# Cute angry eyes
		_draw_rect(img, ox + 11, by + 5, 2, 3, C_NAVY)
		_draw_rect(img, ox + 19, by + 5, 2, 3, C_NAVY)
		_draw_pixel(img, ox + 12, by + 5, C_ROSE)
		_draw_pixel(img, ox + 20, by + 5, C_ROSE)
		
	img.save_png(ProjectSettings.globalize_path(path))
	print("[AssetGenerator] Slime sprite generated: ", path)

static func _generate_bat_sprite(path: String) -> void:
	# 4 frames 32x32 -> 128x32
	var img := Image.create(128, 32, false, Image.FORMAT_RGBA8)
	img.fill(C_CLEAR)
	
	for f in range(4):
		var ox := f * 32
		var wing_y: int = 0
		if f == 0: wing_y = -3 # Wings up
		elif f == 1: wing_y = 0  # Wings mid
		elif f == 2: wing_y = 3  # Wings down
		elif f == 3: wing_y = 1  # Glide
		
		# Shadow
		_draw_circle(img, ox + 16, 28, 4, Color(0, 0, 0, 0.25))
		
		# Left Wing
		_draw_line(img, ox + 12, 14, ox + 3, 12 + wing_y, C_PURPLE_DARK)
		_draw_line(img, ox + 3, 12 + wing_y, ox + 6, 19 + wing_y, C_PURPLE)
		_draw_line(img, ox + 6, 19 + wing_y, ox + 12, 16, C_PURPLE_LIGHT)
		
		# Right Wing
		_draw_line(img, ox + 20, 14, ox + 29, 12 + wing_y, C_PURPLE_DARK)
		_draw_line(img, ox + 29, 12 + wing_y, ox + 26, 19 + wing_y, C_PURPLE)
		_draw_line(img, ox + 26, 19 + wing_y, ox + 20, 16, C_PURPLE_LIGHT)
		
		# Center Mech Body
		_draw_outline_rect(img, ox + 12, 10, 8, 10, C_PURPLE, C_NAVY)
		_draw_rect(img, ox + 13, 11, 6, 8, C_PURPLE_LIGHT)
		
		# Glowing Cyclops Visor
		_draw_rect(img, ox + 14, 13, 4, 3, C_ROSE)
		_draw_pixel(img, ox + 15, 14, C_WHITE)
		
		# Antenna ears
		_draw_pixel(img, ox + 13, 9, C_PURPLE_DARK)
		_draw_pixel(img, ox + 18, 9, C_PURPLE_DARK)
		
	img.save_png(ProjectSettings.globalize_path(path))
	print("[AssetGenerator] Bat sprite generated: ", path)

static func _generate_drone_sprite(path: String) -> void:
	# 4 frames 32x32 -> 128x32
	var img := Image.create(128, 32, false, Image.FORMAT_RGBA8)
	img.fill(C_CLEAR)
	
	for f in range(4):
		var ox := f * 32
		var bob: int = 1 if (f % 2 == 1) else 0
		
		# Shadow
		_draw_circle(img, ox + 16, 29, 6, Color(0, 0, 0, 0.25))
		
		# Antenna
		_draw_line(img, ox + 16, 4 + bob, ox + 16, 7 + bob, C_SLATE_MID)
		_draw_pixel(img, ox + 16, 4 + bob, C_ROSE)
		
		# Monitor Chassis
		_draw_outline_rect(img, ox + 6, 7 + bob, 20, 16, C_SLATE_LIGHT, C_NAVY)
		_draw_rect(img, ox + 7, 8 + bob, 18, 14, C_SLATE_DARK)
		
		# Green CRT Screen
		_draw_outline_rect(img, ox + 9, 10 + bob, 14, 10, C_NAVY, C_SLATE_MID)
		_draw_rect(img, ox + 10, 11 + bob, 12, 8, Color("#064E3B"))
		
		# Animated Green Skull / Crosshair Icon
		if f % 2 == 0:
			_draw_rect(img, ox + 13, 12 + bob, 6, 4, C_EMERALD_LIGHT)
			_draw_pixel(img, ox + 14, 14 + bob, C_NAVY)
			_draw_pixel(img, ox + 17, 14 + bob, C_NAVY)
			_draw_rect(img, ox + 14, 16 + bob, 4, 2, C_EMERALD_LIGHT)
		else:
			_draw_line(img, ox + 12, 15 + bob, ox + 20, 15 + bob, C_CYAN_GLOW)
			_draw_line(img, ox + 16, 12 + bob, ox + 16, 18 + bob, C_CYAN_GLOW)
			
		# Thruster Exhaust
		_draw_rect(img, ox + 14, 23 + bob, 4, 3, C_CYAN_LIGHT)
		_draw_pixel(img, ox + 15, 25 + bob, C_WHITE)
		
	img.save_png(ProjectSettings.globalize_path(path))
	print("[AssetGenerator] Drone sprite generated: ", path)

static func _generate_golem_sprite(path: String) -> void:
	# 4 frames 48x48 -> 192x48
	var img := Image.create(192, 48, false, Image.FORMAT_RGBA8)
	img.fill(C_CLEAR)
	
	for f in range(4):
		var ox := f * 48
		var stomp: int = 1 if (f % 2 == 1) else 0
		var step_l: int = 2 if f == 1 else 0
		var step_r: int = 2 if f == 3 else 0
		
		# Shadow
		_draw_circle(img, ox + 24, 44, 14, Color(0, 0, 0, 0.4))
		
		# Heavy Feet
		_draw_outline_rect(img, ox + 10, 38 - step_l, 10, 6, C_SLATE_MID, C_NAVY)
		_draw_outline_rect(img, ox + 28, 38 - step_r, 10, 6, C_SLATE_MID, C_NAVY)
		
		# Huge Armored Torso (24w x 20h)
		_draw_outline_rect(img, ox + 12, 14 + stomp, 24, 22, C_SLATE_DARK, C_NAVY)
		_draw_rect(img, ox + 14, 16 + stomp, 20, 18, C_SLATE_MID)
		
		# Glowing Crimson Reactor Core
		_draw_circle(img, ox + 24, 24 + stomp, 5, C_ROSE)
		_draw_circle(img, ox + 24, 24 + stomp, 3, C_GOLD_LIGHT)
		_draw_pixel(img, ox + 24, 24 + stomp, C_WHITE)
		
		# Massive Shoulders & Fists
		_draw_outline_rect(img, ox + 4, 16 + stomp, 8, 16, C_SLATE_DARK, C_NAVY)
		_draw_rect(img, ox + 5, 17 + stomp, 6, 14, C_SLATE_MID)
		_draw_outline_rect(img, ox + 36, 16 + stomp, 8, 16, C_SLATE_DARK, C_NAVY)
		_draw_rect(img, ox + 37, 17 + stomp, 6, 14, C_SLATE_MID)
		
		# Head / Helmet Visor
		_draw_outline_rect(img, ox + 18, 6 + stomp, 12, 9, C_SLATE_DARK, C_NAVY)
		_draw_rect(img, ox + 20, 10 + stomp, 8, 3, C_ROSE)
		_draw_pixel(img, ox + 23, 11 + stomp, C_WHITE)
		
	img.save_png(ProjectSettings.globalize_path(path))
	print("[AssetGenerator] Golem sprite generated: ", path)

static func _generate_boss_sprite(path: String) -> void:
	# 4 frames 80x80 -> 320x80
	var img := Image.create(320, 80, false, Image.FORMAT_RGBA8)
	img.fill(C_CLEAR)
	
	for f in range(4):
		var ox := f * 80
		var core_color := C_CYAN_GLOW
		if f == 1: core_color = C_GOLD # Phase 2 (Yellow)
		elif f == 2: core_color = C_ROSE # Phase 3 (Red)
		elif f == 3: core_color = C_WHITE # Defeated / Meltdown
		
		# Grand Shadow
		_draw_circle(img, ox + 40, 72, 24, Color(0, 0, 0, 0.45))
		
		# Floating Satellite Pods (Left & Right)
		_draw_outline_rect(img, ox + 6, 24, 12, 28, C_SLATE_DARK, C_NAVY)
		_draw_circle(img, ox + 12, 38, 4, core_color)
		_draw_outline_rect(img, ox + 62, 24, 12, 28, C_SLATE_DARK, C_NAVY)
		_draw_circle(img, ox + 68, 38, 4, core_color)
		
		# Mainframe Heavy Chassis (44w x 48h)
		_draw_outline_rect(img, ox + 18, 14, 44, 52, C_NAVY, C_SLATE_DARK)
		_draw_rect(img, ox + 20, 16, 40, 48, C_SLATE_DARK)
		_draw_outline_rect(img, ox + 24, 20, 32, 40, C_NAVY, C_SLATE_LIGHT)
		_draw_rect(img, ox + 26, 22, 28, 36, C_DARK_BG)
		
		# Gigantic Eye / Ocular Fusion Core
		_draw_circle(img, ox + 40, 40, 12, core_color)
		_draw_circle(img, ox + 40, 40, 7, C_WHITE)
		_draw_circle(img, ox + 40, 40, 3, C_NAVY)
		
		# Circuit Traces
		_draw_line(img, ox + 28, 26, ox + 36, 32, core_color)
		_draw_line(img, ox + 52, 26, ox + 44, 32, core_color)
		_draw_line(img, ox + 28, 54, ox + 36, 48, core_color)
		_draw_line(img, ox + 52, 54, ox + 44, 48, core_color)
		
		# Top Horns / Server Antennas
		_draw_outline_rect(img, ox + 24, 6, 6, 10, C_SLATE_MID, C_NAVY)
		_draw_outline_rect(img, ox + 50, 6, 6, 10, C_SLATE_MID, C_NAVY)
		_draw_pixel(img, ox + 26, 7, core_color)
		_draw_pixel(img, ox + 52, 7, core_color)
		
	img.save_png(ProjectSettings.globalize_path(path))
	print("[AssetGenerator] Boss sprite generated: ", path)

# ==============================================================================
# 3. PROJECTILE SPRITES GENERATION
# ==============================================================================

static func _generate_bullet_sprite(path: String) -> void:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(C_CLEAR)
	# Glowing Cyan Sonic Pulse Orb
	_draw_circle(img, 8, 8, 6, Color(C_CYAN_GLOW.r, C_CYAN_GLOW.g, C_CYAN_GLOW.b, 0.4))
	_draw_circle(img, 8, 8, 4, C_CYAN_LIGHT)
	_draw_circle(img, 8, 8, 2, C_WHITE)
	img.save_png(ProjectSettings.globalize_path(path))
	print("[AssetGenerator] Bullet sprite generated: ", path)

static func _generate_energy_orb_sprite(path: String) -> void:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(C_CLEAR)
	# Glowing Magenta / Orange Plasma Orb
	_draw_circle(img, 8, 8, 6, Color(C_ROSE.r, C_ROSE.g, C_ROSE.b, 0.4))
	_draw_circle(img, 8, 8, 4, C_ROSE)
	_draw_circle(img, 8, 8, 2, C_GOLD_LIGHT)
	_draw_pixel(img, 8, 8, C_WHITE)
	img.save_png(ProjectSettings.globalize_path(path))
	print("[AssetGenerator] Energy orb sprite generated: ", path)

static func _generate_laser_sprite(path: String) -> void:
	var img := Image.create(32, 8, false, Image.FORMAT_RGBA8)
	img.fill(C_CLEAR)
	# High intensity plasma beam
	_draw_rect(img, 0, 1, 32, 6, Color(C_PURPLE.r, C_PURPLE.g, C_PURPLE.b, 0.4))
	_draw_rect(img, 2, 2, 28, 4, C_PURPLE_LIGHT)
	_draw_rect(img, 4, 3, 24, 2, C_WHITE)
	img.save_png(ProjectSettings.globalize_path(path))
	print("[AssetGenerator] Laser sprite generated: ", path)

# ==============================================================================
# 4. PICKUP SPRITES GENERATION
# ==============================================================================

static func _generate_xp_small_sprite(path: String) -> void:
	var img := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	img.fill(C_CLEAR)
	# 12x12 Cyan Diamond Crystal (1 XP)
	_draw_line(img, 6, 1, 10, 6, C_CYAN_LIGHT)
	_draw_line(img, 10, 6, 6, 10, C_BLUE_SKY)
	_draw_line(img, 6, 10, 1, 6, C_BLUE_DARK)
	_draw_line(img, 1, 6, 6, 1, C_CYAN_LIGHT)
	_draw_rect(img, 4, 4, 4, 4, C_CYAN_GLOW)
	_draw_pixel(img, 5, 4, C_WHITE)
	img.save_png(ProjectSettings.globalize_path(path))
	print("[AssetGenerator] XP Small gem generated: ", path)

static func _generate_xp_med_sprite(path: String) -> void:
	var img := Image.create(14, 14, false, Image.FORMAT_RGBA8)
	img.fill(C_CLEAR)
	# 14x14 Emerald Octagon Core (5 XP)
	_draw_outline_rect(img, 2, 2, 10, 10, C_EMERALD, C_EMERALD_DARK)
	_draw_rect(img, 4, 4, 6, 6, C_EMERALD_LIGHT)
	_draw_pixel(img, 5, 5, C_WHITE)
	_draw_pixel(img, 8, 8, C_MINT)
	img.save_png(ProjectSettings.globalize_path(path))
	print("[AssetGenerator] XP Med gem generated: ", path)

static func _generate_xp_large_sprite(path: String) -> void:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(C_CLEAR)
	# 16x16 Gold Star Reactor Gem (20 XP)
	_draw_circle(img, 8, 8, 5, C_GOLD)
	_draw_line(img, 8, 1, 8, 14, C_GOLD_LIGHT)
	_draw_line(img, 1, 8, 14, 8, C_GOLD_LIGHT)
	_draw_line(img, 3, 3, 12, 12, C_GOLD)
	_draw_line(img, 12, 3, 3, 12, C_GOLD)
	_draw_circle(img, 8, 8, 2, C_WHITE)
	img.save_png(ProjectSettings.globalize_path(path))
	print("[AssetGenerator] XP Large gem generated: ", path)

# ==============================================================================
# 5. TILESETS & PROPS GENERATION
# ==============================================================================

static func _generate_arena_tileset(path: String) -> void:
	# 256x128 image containing 8x4 grid of 32x32 tiles
	var img := Image.create(256, 128, false, Image.FORMAT_RGBA8)
	img.fill(C_CLEAR)
	
	# Row 0: Floor Tiles
	# Tile 0: Plain Slate Grid
	_draw_outline_rect(img, 0, 0, 32, 32, C_SLATE_DARK, C_NAVY)
	_draw_line(img, 0, 0, 31, 0, C_SLATE_MID)
	_draw_line(img, 0, 0, 0, 31, C_SLATE_MID)
	
	# Tile 1: Circuit Lines Floor
	_draw_outline_rect(img, 32, 0, 32, 32, C_SLATE_DARK, C_NAVY)
	_draw_line(img, 32, 16, 48, 16, C_CYAN)
	_draw_line(img, 48, 16, 48, 31, C_CYAN)
	_draw_circle(img, 48, 16, 2, C_CYAN_LIGHT)
	
	# Tile 2: Dual Circuit Node Floor
	_draw_outline_rect(img, 64, 0, 32, 32, C_SLATE_DARK, C_NAVY)
	_draw_line(img, 80, 0, 80, 31, C_CYAN_LIGHT)
	_draw_line(img, 64, 16, 95, 16, C_CYAN_LIGHT)
	_draw_circle(img, 80, 16, 3, C_MINT)
	
	# Tile 3: Caution Hatch Floor
	_draw_outline_rect(img, 96, 0, 32, 32, C_SLATE_DARK, C_NAVY)
	for d in range(-32, 64, 8):
		_draw_line(img, 96 + d, 0, 96 + d + 32, 31, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.4))
		
	# Row 1: Wall Top Cap
	for c in range(8):
		var wx := c * 32
		_draw_outline_rect(img, wx, 32, 32, 32, C_SLATE_MID, C_NAVY)
		_draw_line(img, wx, 33, wx + 31, 33, C_SLATE_LIGHT)
		_draw_line(img, wx, 62, wx + 31, 62, C_SLATE_DARK)
		
	# Row 2: Wall Front Face / Bulkheads
	for c in range(8):
		var wx := c * 32
		_draw_outline_rect(img, wx, 64, 32, 32, C_NAVY, C_SLATE_DARK)
		_draw_rect(img, wx + 4, 68, 24, 24, C_SLATE_DARK)
		_draw_line(img, wx + 8, 72, wx + 23, 72, C_SLATE_MID)
		_draw_line(img, wx + 8, 80, wx + 23, 80, C_SLATE_MID)
		_draw_line(img, wx + 8, 88, wx + 23, 88, C_SLATE_MID)
		
	# Row 3: Boundary Borders
	for c in range(8):
		var wx := c * 32
		_draw_outline_rect(img, wx, 96, 32, 32, C_DARK_BG, C_NAVY)
		_draw_circle(img, wx + 16, 112, 4, C_MINT)
		
	img.save_png(ProjectSettings.globalize_path(path))
	print("[AssetGenerator] Arena tileset generated: ", path)

static func _generate_props(path: String) -> void:
	# 128x64 image containing props
	var img := Image.create(128, 64, false, Image.FORMAT_RGBA8)
	img.fill(C_CLEAR)
	
	# Prop 1: Server Rack Tower (32x48) at (0, 16)
	_draw_outline_rect(img, 0, 16, 32, 48, C_SLATE_DARK, C_NAVY)
	_draw_rect(img, 2, 18, 28, 44, C_NAVY)
	# Server LED bays
	for r in range(4):
		var ry := 22 + r * 10
		_draw_outline_rect(img, 4, ry, 24, 8, C_SLATE_MID, C_SLATE_DARK)
		_draw_pixel(img, 6, ry + 3, C_EMERALD)
		_draw_pixel(img, 9, ry + 3, C_CYAN_LIGHT)
		_draw_pixel(img, 12, ry + 3, C_ROSE)
		_draw_line(img, 16, ry + 4, 24, ry + 4, C_SLATE_LIGHT)
		
	# Prop 2: Hologram Pylon (16x48) at (36, 16)
	_draw_outline_rect(img, 36, 36, 16, 28, C_SLATE_DARK, C_NAVY)
	_draw_rect(img, 40, 20, 8, 16, Color(C_CYAN_GLOW.r, C_CYAN_GLOW.g, C_CYAN_GLOW.b, 0.6))
	_draw_circle(img, 44, 24, 3, C_WHITE)
	_draw_line(img, 44, 16, 44, 20, C_CYAN_LIGHT)
	
	# Prop 3: Power Crystal Pedestal (32x32) at (56, 32)
	_draw_outline_rect(img, 56, 44, 32, 20, C_SLATE_DARK, C_NAVY)
	_draw_line(img, 72, 32, 80, 44, C_EMERALD)
	_draw_line(img, 80, 44, 72, 56, C_EMERALD_DARK)
	_draw_line(img, 72, 56, 64, 44, C_EMERALD)
	_draw_line(img, 64, 44, 72, 32, C_EMERALD_LIGHT)
	_draw_circle(img, 72, 44, 3, C_WHITE)
	
	# Prop 4: Terminal Console (32x32) at (92, 32)
	_draw_outline_rect(img, 92, 40, 32, 24, C_SLATE_MID, C_NAVY)
	_draw_outline_rect(img, 96, 32, 24, 16, C_SLATE_DARK, C_NAVY)
	_draw_rect(img, 98, 34, 20, 12, Color("#064E3B"))
	_draw_line(img, 100, 38, 116, 38, C_EMERALD_LIGHT)
	_draw_line(img, 100, 42, 112, 42, C_EMERALD_LIGHT)
	
	img.save_png(ProjectSettings.globalize_path(path))
	print("[AssetGenerator] Props generated: ", path)

# ==============================================================================
# 6. UI & UPGRADE ICONS GENERATION
# ==============================================================================

static func _generate_card_background(path: String) -> void:
	# 120x180 Card Frame
	var img := Image.create(120, 180, false, Image.FORMAT_RGBA8)
	img.fill(C_CLEAR)
	
	# Outer border
	_draw_outline_rect(img, 0, 0, 120, 180, Color(0.04, 0.07, 0.13, 0.95), C_NAVY)
	_draw_outline_rect(img, 2, 2, 116, 176, Color(0.06, 0.10, 0.18, 0.95), C_CYAN)
	_draw_outline_rect(img, 4, 4, 112, 172, Color(0.04, 0.07, 0.13, 0.95), C_SLATE_DARK)
	
	# Title Header Ribbon
	_draw_outline_rect(img, 6, 8, 108, 24, C_SLATE_DARK, C_CYAN)
	
	# Icon Frame (48x48 centered at x: 36, y: 38)
	_draw_outline_rect(img, 36, 38, 48, 48, C_NAVY, C_CYAN_LIGHT)
	_draw_rect(img, 38, 40, 44, 44, C_DARK_BG)
	
	# Description Box
	_draw_outline_rect(img, 8, 92, 104, 56, C_DARK_BG, C_SLATE_MID)
	
	# Bottom Rarity / Tier Banner
	_draw_outline_rect(img, 12, 154, 96, 18, C_SLATE_DARK, C_GOLD)
	
	img.save_png(ProjectSettings.globalize_path(path))
	print("[AssetGenerator] Card background generated: ", path)

static func _generate_ui_icons(dir: String) -> void:
	_generate_icon_damage(dir + "icon_damage.png")
	_generate_icon_attack_speed(dir + "icon_attack_speed.png")
	_generate_icon_move_speed(dir + "icon_move_speed.png")
	_generate_icon_max_hp(dir + "icon_max_hp.png")
	_generate_icon_multishot(dir + "icon_multishot.png")
	_generate_icon_pierce(dir + "icon_pierce.png")
	_generate_icon_range(dir + "icon_range.png")
	_generate_icon_magnet(dir + "icon_magnet.png")
	_generate_icon_regen(dir + "icon_regen.png")
	_generate_icon_crit(dir + "icon_crit.png")

static func _create_icon_canvas() -> Image:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(C_CLEAR)
	_draw_outline_rect(img, 0, 0, 32, 32, C_DARK_BG, C_SLATE_DARK)
	return img

static func _generate_icon_damage(path: String) -> void:
	var img := _create_icon_canvas()
	# Crossed Energy Blades
	_draw_line(img, 6, 26, 26, 6, C_ROSE)
	_draw_line(img, 7, 26, 26, 7, C_WHITE)
	_draw_line(img, 6, 6, 26, 26, C_ROSE)
	_draw_line(img, 7, 6, 26, 25, C_WHITE)
	_draw_circle(img, 16, 16, 3, C_GOLD)
	img.save_png(ProjectSettings.globalize_path(path))

static func _generate_icon_attack_speed(path: String) -> void:
	var img := _create_icon_canvas()
	# Lightning Bolt
	_draw_line(img, 18, 4, 10, 16, C_GOLD)
	_draw_line(img, 10, 16, 18, 16, C_GOLD_LIGHT)
	_draw_line(img, 18, 16, 12, 28, C_GOLD)
	_draw_line(img, 19, 4, 11, 16, C_WHITE)
	img.save_png(ProjectSettings.globalize_path(path))

static func _generate_icon_move_speed(path: String) -> void:
	var img := _create_icon_canvas()
	# Winged Speed Boot / Rocket
	_draw_line(img, 8, 22, 24, 10, C_CYAN_LIGHT)
	_draw_line(img, 8, 22, 14, 22, C_CYAN)
	_draw_line(img, 24, 10, 20, 16, C_CYAN)
	_draw_line(img, 4, 20, 10, 24, C_WHITE)
	_draw_line(img, 4, 24, 8, 26, C_CYAN_GLOW)
	img.save_png(ProjectSettings.globalize_path(path))

static func _generate_icon_max_hp(path: String) -> void:
	var img := _create_icon_canvas()
	# Glowing Heart
	_draw_circle(img, 11, 12, 5, C_ROSE)
	_draw_circle(img, 21, 12, 5, C_ROSE)
	_draw_line(img, 6, 14, 16, 26, C_RUBY)
	_draw_line(img, 26, 14, 16, 26, C_RUBY)
	_draw_rect(img, 9, 12, 14, 6, C_ROSE)
	_draw_pixel(img, 11, 10, C_WHITE)
	img.save_png(ProjectSettings.globalize_path(path))

static func _generate_icon_multishot(path: String) -> void:
	var img := _create_icon_canvas()
	# Triple Projectile Spread Fan
	_draw_circle(img, 16, 8, 3, C_CYAN_GLOW)
	_draw_circle(img, 8, 20, 3, C_CYAN_LIGHT)
	_draw_circle(img, 24, 20, 3, C_CYAN_LIGHT)
	_draw_line(img, 16, 26, 16, 12, C_CYAN)
	_draw_line(img, 16, 26, 10, 22, C_CYAN)
	_draw_line(img, 16, 26, 22, 22, C_CYAN)
	img.save_png(ProjectSettings.globalize_path(path))

static func _generate_icon_pierce(path: String) -> void:
	var img := _create_icon_canvas()
	# Arrow Punching Through Shield
	_draw_outline_rect(img, 12, 8, 14, 16, C_SLATE_MID, C_SLATE_LIGHT)
	_draw_line(img, 4, 16, 28, 16, C_PURPLE_LIGHT)
	_draw_line(img, 24, 12, 28, 16, C_WHITE)
	_draw_line(img, 24, 20, 28, 16, C_WHITE)
	img.save_png(ProjectSettings.globalize_path(path))

static func _generate_icon_range(path: String) -> void:
	var img := _create_icon_canvas()
	# Radar Crosshair
	_draw_circle(img, 16, 16, 9, Color(C_CYAN_GLOW.r, C_CYAN_GLOW.g, C_CYAN_GLOW.b, 0.4))
	_draw_circle(img, 16, 16, 5, Color(C_CYAN_GLOW.r, C_CYAN_GLOW.g, C_CYAN_GLOW.b, 0.2))
	_draw_line(img, 16, 4, 16, 28, C_CYAN_LIGHT)
	_draw_line(img, 4, 16, 28, 16, C_CYAN_LIGHT)
	_draw_pixel(img, 16, 16, C_WHITE)
	img.save_png(ProjectSettings.globalize_path(path))

static func _generate_icon_magnet(path: String) -> void:
	var img := _create_icon_canvas()
	# Horseshoe Magnet
	_draw_outline_rect(img, 8, 8, 16, 16, C_ROSE, C_NAVY)
	_draw_rect(img, 12, 8, 8, 12, C_DARK_BG)
	_draw_rect(img, 8, 8, 4, 4, C_CYAN_LIGHT)
	_draw_rect(img, 20, 8, 4, 4, C_ROSE)
	# Field arcs
	_draw_line(img, 6, 6, 10, 4, C_CYAN_GLOW)
	_draw_line(img, 22, 4, 26, 6, C_CYAN_GLOW)
	img.save_png(ProjectSettings.globalize_path(path))

static func _generate_icon_regen(path: String) -> void:
	var img := _create_icon_canvas()
	# Emerald Healing Cross
	_draw_rect(img, 13, 6, 6, 20, C_EMERALD)
	_draw_rect(img, 6, 13, 20, 6, C_EMERALD)
	_draw_rect(img, 14, 7, 4, 18, C_EMERALD_LIGHT)
	_draw_rect(img, 7, 14, 18, 4, C_EMERALD_LIGHT)
	_draw_pixel(img, 16, 16, C_WHITE)
	img.save_png(ProjectSettings.globalize_path(path))

static func _generate_icon_crit(path: String) -> void:
	var img := _create_icon_canvas()
	# Critical Starburst
	_draw_line(img, 16, 4, 16, 28, C_GOLD)
	_draw_line(img, 4, 16, 28, 16, C_GOLD)
	_draw_line(img, 8, 8, 24, 24, C_GOLD_LIGHT)
	_draw_line(img, 24, 8, 8, 24, C_GOLD_LIGHT)
	_draw_circle(img, 16, 16, 3, C_WHITE)
	img.save_png(ProjectSettings.globalize_path(path))

# ==============================================================================
# 7. PROCEDURAL SFX GENERATION (16-bit PCM RIFF WAV)
# ==============================================================================

static func _generate_sfx(dir: String) -> void:
	_save_wav(dir + "shoot.wav", _synth_shoot())
	_save_wav(dir + "hit.wav", _synth_hit())
	_save_wav(dir + "explosion.wav", _synth_explosion())
	_save_wav(dir + "gem_pickup.wav", _synth_gem_pickup())
	_save_wav(dir + "levelup.wav", _synth_levelup())
	_save_wav(dir + "game_over.wav", _synth_game_over())
	_save_wav(dir + "victory.wav", _synth_victory())

static func _save_wav(path: String, samples: PackedFloat32Array, sample_rate: int = 44100) -> void:
	var num_samples := samples.size()
	var subchunk2_size := num_samples * 2 # 16-bit = 2 bytes per sample
	var chunk_size := 36 + subchunk2_size
	
	var bytes := PackedByteArray()
	bytes.resize(44 + subchunk2_size)
	
	# RIFF chunk
	bytes[0] = 82  # R
	bytes[1] = 73  # I
	bytes[2] = 70  # F
	bytes[3] = 70  # F
	bytes.encode_u32(4, chunk_size)
	bytes[8] = 87  # W
	bytes[9] = 65  # A
	bytes[10] = 86 # V
	bytes[11] = 69 # E
	
	# fmt subchunk
	bytes[12] = 102 # f
	bytes[13] = 109 # m
	bytes[14] = 116 # t
	bytes[15] = 32  # ' '
	bytes.encode_u32(16, 16)         # Subchunk1Size
	bytes.encode_u16(20, 1)          # AudioFormat (PCM)
	bytes.encode_u16(22, 1)          # NumChannels (Mono)
	bytes.encode_u32(24, sample_rate)# SampleRate
	bytes.encode_u32(28, sample_rate * 2) # ByteRate
	bytes.encode_u16(32, 2)          # BlockAlign
	bytes.encode_u16(34, 16)         # BitsPerSample
	
	# data subchunk
	bytes[36] = 100 # d
	bytes[37] = 97  # a
	bytes[38] = 116 # t
	bytes[39] = 97  # a
	bytes.encode_u32(40, subchunk2_size)
	
	# PCM data
	var offset := 44
	for i in range(num_samples):
		var s := clampf(samples[i], -1.0, 1.0)
		var pcm := int(round(s * 32767.0))
		bytes.encode_s16(offset, pcm)
		offset += 2
		
	var global_path := ProjectSettings.globalize_path(path)
	var file := FileAccess.open(global_path, FileAccess.WRITE)
	if file:
		file.store_buffer(bytes)
		file.close()
		print("[AssetGenerator] SFX WAV saved: ", path)
	else:
		printerr("[AssetGenerator] Failed to save WAV to: ", global_path)

static func _synth_shoot() -> PackedFloat32Array:
	var sample_rate := 44100
	var duration := 0.12
	var count := int(sample_rate * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	
	var phase := 0.0
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var progress := t / duration
		var freq := lerpf(920.0, 240.0, progress)
		phase += freq * (TAU / float(sample_rate))
		var env := (1.0 - progress) * (1.0 - progress)
		samples[i] = sin(phase) * env * 0.7
	return samples

static func _synth_hit() -> PackedFloat32Array:
	var sample_rate := 44100
	var duration := 0.10
	var count := int(sample_rate * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	
	var phase := 0.0
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var progress := t / duration
		var freq := lerpf(180.0, 60.0, progress)
		phase += freq * (TAU / float(sample_rate))
		var noise := randf_range(-1.0, 1.0)
		var env := (1.0 - progress)
		samples[i] = (sin(phase) * 0.5 + noise * 0.5) * env * 0.8
	return samples

static func _synth_explosion() -> PackedFloat32Array:
	var sample_rate := 44100
	var duration := 0.35
	var count := int(sample_rate * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	
	var phase := 0.0
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var progress := t / duration
		var freq := lerpf(90.0, 30.0, progress)
		phase += freq * (TAU / float(sample_rate))
		var noise := randf_range(-1.0, 1.0)
		var env := (1.0 - progress) * (1.0 - progress)
		var s := (sin(phase) * 0.6 + noise * 0.4) * env * 0.9
		samples[i] = s
	return samples

static func _synth_gem_pickup() -> PackedFloat32Array:
	var sample_rate := 44100
	var duration := 0.15
	var count := int(sample_rate * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	
	var phase1 := 0.0
	var phase2 := 0.0
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var progress := t / duration
		phase1 += 1320.0 * (TAU / float(sample_rate))
		phase2 += 1760.0 * (TAU / float(sample_rate))
		var env := (1.0 - progress) * (1.0 - progress)
		samples[i] = (sin(phase1) * 0.5 + sin(phase2) * 0.5) * env * 0.7
	return samples

static func _synth_levelup() -> PackedFloat32Array:
	var sample_rate := 44100
	var duration := 0.60
	var count := int(sample_rate * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	
	var notes := [523.25, 659.25, 783.99, 1046.50] # C5, E5, G5, C6
	var note_dur := duration / float(notes.size())
	
	var phase := 0.0
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var note_idx := clampi(int(t / note_dur), 0, notes.size() - 1)
		var note_t := fmod(t, note_dur)
		var env := (1.0 - (note_t / note_dur) * 0.5)
		var freq: float = notes[note_idx]
		phase += freq * (TAU / float(sample_rate))
		samples[i] = (sin(phase) * 0.6 + sin(phase * 2.0) * 0.2) * env * 0.75
	return samples

static func _synth_game_over() -> PackedFloat32Array:
	var sample_rate := 44100
	var duration := 0.80
	var count := int(sample_rate * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	
	var notes := [392.0, 311.13, 261.63, 196.0] # G4, Eb4, C4, G3
	var note_dur := duration / float(notes.size())
	
	var phase := 0.0
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var note_idx := clampi(int(t / note_dur), 0, notes.size() - 1)
		var note_t := fmod(t, note_dur)
		var env := (1.0 - (note_t / note_dur) * 0.6)
		var freq: float = notes[note_idx]
		phase += freq * (TAU / float(sample_rate))
		samples[i] = (sin(phase) * 0.7 + sin(phase * 0.5) * 0.3) * env * 0.7
	return samples

static func _synth_victory() -> PackedFloat32Array:
	var sample_rate := 44100
	var duration := 1.00
	var count := int(sample_rate * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	
	var notes := [523.25, 659.25, 783.99, 1046.50, 1318.51] # C5, E5, G5, C6, E6
	var note_dur := 0.18
	
	var phase1 := 0.0
	var phase2 := 0.0
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var note_idx := clampi(int(t / note_dur), 0, notes.size() - 1)
		var freq1: float = notes[note_idx]
		var freq2: float = freq1 * 1.5
		phase1 += freq1 * (TAU / float(sample_rate))
		phase2 += freq2 * (TAU / float(sample_rate))
		var overall_env := 1.0 - (t / duration) * 0.4
		samples[i] = (sin(phase1) * 0.5 + sin(phase2) * 0.3) * overall_env * 0.75
	return samples
