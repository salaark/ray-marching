#version 300 es

// Raymarching Shader
// Created By Salaar Kohari 2018

precision highp float;

in vec4 vs_Pos;
out vec4 fs_Pos;

void main() {
	gl_Position = vs_Pos;
	fs_Pos = vs_Pos;
}
