extern number angle;

// Whole-screen spin for the Record boss blind. Runs as a real SMODS.ScreenShader
// (same ping-pong pipeline as the built-in CRT shader) instead of a manual
// setCanvas/clear/redraw dance patched into game.lua -- this only costs
// anything on the frames should_apply() is true, matching how every other
// ScreenShader already behaves.
vec4 effect(vec4 colour, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    // texture_coords is normalized 0-1 on both axes, but the screen itself
    // isn't square -- rotating raw 0-1 UVs stretches/shears the image as it
    // turns, since a given angular step covers a different physical distance
    // on each axis. Correct to a square, aspect-matched space before
    // rotating, then convert back, so the rotation reads as rigid instead of
    // wobbly/distorted.
    float aspect = love_ScreenSize.x / love_ScreenSize.y;
    vec2 uv = texture_coords - vec2(0.5);
    uv.x *= aspect;

    float c = cos(-angle);
    float s = sin(-angle);
    vec2 rotated = vec2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);
    rotated.x /= aspect;
    vec2 source = rotated + vec2(0.5);

    if (source.x < 0.0 || source.x > 1.0 || source.y < 0.0 || source.y > 1.0) {
        return vec4(0.0, 0.0, 0.0, 1.0);
    }
    return Texel(texture, source) * colour;
}
