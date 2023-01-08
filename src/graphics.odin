package main

import "core:math/linalg"
import rl "raylib"

models : struct {
  selector : rl.Model,
  tile : rl.Model,
  vine : rl.Model,
  pumpkin : rl.Model,
  portal_border : rl.Model,
  portal_fill : rl.Model,
}

default_shader : rl.Shader
lighted_shader : rl.Shader
lighted_day_normal, lighted_night_normal : rl.ShaderLocationIndex

load_graphics :: proc() {
  models.selector = rl.LoadModel("res/selector.glb")
  default_shader = models.selector.materials[0].shader

  lighted_shader = rl.LoadShaderFromMemory(BASE_LIGHTING_VS, LIGHTING_FS)
  lighted_shader.locs[rl.ShaderLocationIndex.MATRIX_MODEL] = rl.GetShaderLocation(lighted_shader, "matModel")
  lighted_day_normal = rl.ShaderLocationIndex(rl.GetShaderLocation(lighted_shader, "dayNormal"))
  lighted_night_normal = rl.ShaderLocationIndex(rl.GetShaderLocation(lighted_shader, "nightNormal"))

  models.tile = rl.LoadModel("res/tile.glb")
  models.tile.materials[0].shader = lighted_shader

  models.vine = rl.LoadModel("res/vine.glb")
  models.vine.materials[0].shader = lighted_shader

  models.pumpkin = rl.LoadModel("res/pumpkin.glb")
  models.pumpkin.materials[0].shader = lighted_shader

  models.portal_border = rl.LoadModel("res/portal_border.glb")
  models.portal_border.materials[0].shader = lighted_shader

  models.portal_fill = rl.LoadModel("res/portal_fill.glb")
}

update_lighting :: proc() {
  time_mat := linalg.matrix4_rotate(linalg.TAU * daytime, V3{ 0, 0, 1 })
  v4 :: proc(v3 : V3) -> [4]f32 {
    return { v3.x, v3.y, v3.z, 1 }
  }
  day_vec := (time_mat * v4(linalg.normalize(V3{ 7, 1, -2 }))).xyz
  night_vec := (time_mat * v4(linalg.normalize(V3{ -7, -1, 2 }))).xyz

  rl.SetShaderValue(lighted_shader, lighted_day_normal, &day_vec, .VEC3)
  rl.SetShaderValue(lighted_shader, lighted_night_normal, &night_vec, .VEC3)
}

// SHADERS /////////////////////////////////////////////////////////////////////////////////////////

  BASE_LIGHTING_VS :: `#version 330

    // Input vertex attributes
    in vec3 vertexPosition;
    in vec2 vertexTexCoord;
    in vec3 vertexNormal;
    in vec4 vertexColor;

    // Input uniform values
    uniform mat4 mvp;
    uniform mat4 matModel;
    uniform mat4 matNormal;

    // Output vertex attributes (to fragment shader)
    out vec3 fragPosition;
    out vec2 fragTexCoord;
    out vec4 fragColor;
    out vec3 fragNormal;

    // NOTE: Add here your custom variables

    void main()
    {
        // Send vertex attributes to fragment shader
        fragPosition = vec3(matModel*vec4(vertexPosition, 1.0));
        fragTexCoord = vertexTexCoord;
        fragColor = vertexColor;
        fragNormal = normalize(vec3(matNormal*vec4(vertexNormal, 1.0)));

        // Calculate final vertex position
        gl_Position = mvp*vec4(vertexPosition, 1.0);
    }`

  LIGHTING_FS :: `#version 330

    // Input vertex attributes (from vertex shader)
    in vec3 fragPosition;
    in vec2 fragTexCoord;
    in vec4 fragColor;
    in vec3 fragNormal;

    // Input uniform values
    uniform sampler2D texture0;
    uniform vec4 colDiffuse;
    uniform vec3 dayNormal;
    uniform vec3 nightNormal;

    // Output fragment color
    out vec4 finalColor;

    // NOTE: Add here your custom variables

    float map(float value, float inMin, float inMax, float outMin, float outMax) {
      float t = (value - inMin) / (inMax - inMin);
      return (t * (outMax - outMin)) + outMin;
    }

    void main()
    {
        // Texel color fetching from texture sampler
        vec4 texelColor = texture(texture0, fragTexCoord);
        vec3 normal = normalize(fragNormal);
        // vec3 light_dir = normalize(vec3(5, 10, 2));

        // NOTE: Implement here your fragment shader code

        float day_atten = map(dot(dayNormal, normal), -1.0, 1.0, 0.25, 1.0);
        float night_atten = map(dot(nightNormal, normal), -1.0, 1.0, 0.25, 1.0);
        day_atten = day_atten * day_atten;
        night_atten = night_atten * night_atten;
        vec3 light = day_atten*vec3( 0.858, 0.686, 0.533 ) + night_atten*vec3( 0.137, 0.207, 0.321 );

        finalColor = fragColor * texelColor * colDiffuse * vec4(light, 1);
    }`
