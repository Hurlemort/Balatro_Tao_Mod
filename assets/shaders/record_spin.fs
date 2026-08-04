extern number angle;

// Spins the whole screen for the Record boss blind.
vec4 effect(vec4 colour, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    // square the space up first, or the spin shears the picture
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
