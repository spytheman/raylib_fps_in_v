// Ported from https://github.com/raysan5/raylib/blob/master/examples/models/models_first_person_maze.c
import os
import irishgreencitrus.raylibv as r

const player_radius = f32(0.1) // Collision radius (player is modelled as a cilinder for collision)

const screen_width = 800

const screen_height = 450

const craywhite = r.Color{245, 245, 245, 255}

const cwhite = r.Color{255, 255, 255, 255}

const cred = r.Color{230, 41, 55, 255}

const cgreen = r.Color{0, 228, 48, 255}

fn main() {
	r.init_window(screen_width, screen_height, c'raylib [models] example - first person maze')
	r.set_target_fps(60)

	map_position := r.Vector3{-16.0, 0.0, -8.0}
	mut camera := r.Camera{
		position: r.Vector3{0.2, 0.4, 0.2}
		target: r.Vector3{0.0, 0.0, 0.0}
		up: r.Vector3{0.0, 1.0, 0.0}
		fovy: 45.0
		projection: 0
	}
	r.set_camera_mode(camera, C.CAMERA_FIRST_PERSON)

	path_to_map := os.resource_abs_path('cubicmap.png')
	path_to_atlas := os.resource_abs_path('cubicmap_atlas.png')

	immap := r.load_image(path_to_map.str)
	cubicmap := r.load_texture_from_image(immap)
	mesh := r.gen_mesh_cubicmap(immap, r.Vector3{1.0, 1.0, 1.0})
	mut model := r.load_model_from_mesh(mesh)

	texture := r.load_texture(path_to_atlas.str)
	unsafe {
		model.materials[0].maps[C.MATERIAL_MAP_DIFFUSE].texture = texture
	}
	// Get map image data to be used for collision detection
	map_pixels := r.load_image_colors(immap)
	r.unload_image(immap)

	for !r.window_should_close() { // Detect window close button or ESC key
		old_cam_pos := camera.position
		r.update_camera(&camera)

		// Check player collision (we simplify to 2D collision detection)
		player_pos := r.Vector2{camera.position.x, camera.position.z}

		mut player_cell_x := int(player_pos.x - map_position.x + 0.5)
		mut player_cell_y := int(player_pos.y - map_position.z + 0.5)

		// Out-of-limits security check
		if player_cell_x < 0 {
			player_cell_x = 0
		} else if player_cell_x >= cubicmap.width {
			player_cell_x = cubicmap.width - 1
		}

		if player_cell_y < 0 {
			player_cell_y = 0
		} else if player_cell_y >= cubicmap.height {
			player_cell_y = cubicmap.height - 1
		}

		// Check map collisions using image data and player position
		// TODO: Improvement: Just check player surrounding cells for collision
		for y := 0; y < cubicmap.height; y++ {
			for x := 0; x < cubicmap.width; x++ {
				// Collision: white pixel, only check R channel
				if unsafe { map_pixels[y * cubicmap.width + x].r == 255 } {
					if r.check_collision_circle_rec(player_pos, player_radius, r.Rectangle{
						map_position.x - 0.5 + f32(x) * 1.0, map_position.z - 0.5 + f32(y) * 1.0, 1.0, 1.0})
					{
						// Collision detected, reset camera position
						camera.position = old_cam_pos
					}
				}
			}
		}

		r.begin_drawing()
		{
			r.clear_background(craywhite)

			r.begin_mode_3d(r.Camera3D(camera))
			r.draw_model(model, map_position, 1.0, cwhite) // Draw maze map
			r.end_mode_3d()

			r.draw_texture_ex(cubicmap, r.Vector2{r.get_screen_width() - cubicmap.width * 4 - 20, 20.0},
				0.0, 4.0, cwhite)
			r.draw_rectangle_lines(r.get_screen_width() - cubicmap.width * 4 - 20, 20,
				cubicmap.width * 4, cubicmap.height * 4, cgreen)

			// Draw player position radar
			r.draw_rectangle(r.get_screen_width() - cubicmap.width * 4 - 20 + player_cell_x * 4,
				20 + player_cell_y * 4, 4, 4, cred)

			r.draw_fps(10, 10)
		}
		r.end_drawing()
	}

	r.unload_image_colors(map_pixels) // Unload color array

	r.unload_texture(cubicmap) // Unload cubicmap texture
	r.unload_texture(texture) // Unload map texture
	r.unload_model(model) // Unload map model

	r.close_window() // Close window and OpenGL context
}
