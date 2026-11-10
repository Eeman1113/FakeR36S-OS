// FakeR36S-OS passthrough pass (RetroArch GLSL). Filtering is chosen per pass in the preset.
// Direct varying -> texture2D lookup only: no fragment maths, so it is exact on FP16 (Mali-400).
#if defined(VERTEX)
attribute vec4 VertexCoord;
attribute vec4 TexCoord;
uniform mat4 MVPMatrix;
varying vec2 TEX0;
void main() {
    gl_Position = MVPMatrix * VertexCoord;
    TEX0 = TexCoord.xy;
}
#elif defined(FRAGMENT)
#ifdef GL_ES
precision mediump float;
#endif
uniform sampler2D Texture;
varying vec2 TEX0;
void main() {
    gl_FragColor = texture2D(Texture, TEX0);
}
#endif
