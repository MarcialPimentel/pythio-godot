# ui/ScreenLayout.gd
# The screen is laid out on a 1920x1080 canvas, but the window can be any shape (Steam Deck
# 16:10, ultrawide 21:9). pin() keeps a control where it was on the 1920x1080 canvas, measured
# from the edge or centre it belongs to, so the HUD sticks to the corners and the middle stays
# in the middle when the screen is wider or taller.
class_name ScreenLayout
extends RefCounted

const DESIGN := Vector2(1920, 1080)
const LEFT := 0.0
const TOP := 0.0
const CENTER := 0.5
const RIGHT := 1.0
const BOTTOM := 1.0


## `c` must still use its 1920x1080 position (anchors at the top-left), inside a full-screen parent.
static func pin(c: Control, h: float, v: float) -> void:
	if c == null:
		return
	c.size = c.size.max(c.get_combined_minimum_size())
	var l := c.offset_left
	var t := c.offset_top
	var r := c.offset_right
	var b := c.offset_bottom
	c.set_anchor(SIDE_LEFT, h, true)
	c.set_anchor(SIDE_RIGHT, h, true)
	c.set_anchor(SIDE_TOP, v, true)
	c.set_anchor(SIDE_BOTTOM, v, true)
	c.offset_left = l - h * DESIGN.x
	c.offset_right = r - h * DESIGN.x
	c.offset_top = t - v * DESIGN.y
	c.offset_bottom = b - v * DESIGN.y
	# Grow away from the edge it's pinned to (only the right edge grows leftwards).
	c.grow_horizontal = Control.GROW_DIRECTION_BEGIN if h == RIGHT else Control.GROW_DIRECTION_END
	c.grow_vertical = Control.GROW_DIRECTION_END
