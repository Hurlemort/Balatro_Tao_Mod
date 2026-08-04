extern vec2 light_pos;      // cursor, 0-1 across the screen
extern number light_radius; // as a fraction of screen height

#define FADE 0.45 // fadeout beyong light_radius, fraction of light_radius

// Blacks out everything outside a circle around the cursor, for The Light boss blind.
vec4 effect(vec4 colour, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    // measure the circle in an aspect-matched space so it stays round on a wide screen
    float aspect = love_ScreenSize.x / love_ScreenSize.y;
    vec2 uv = vec2(texture_coords.x * aspect, texture_coords.y);
    vec2 centre = vec2(light_pos.x * aspect, light_pos.y);

    float lit = 1.0 - smoothstep(light_radius, light_radius * (1.0 + FADE), distance(uv, centre));

    vec4 tex = Texel(texture, texture_coords) * colour;
    return vec4(tex.rgb * lit, tex.a);
}
