#version 300 es

// Raymarching Shader
// Created By Salaar Kohari 2018

precision highp float;

uniform float u_Time;
uniform float u_Aspect;
uniform float u_Cel;

in vec4 fs_Pos;

out vec4 out_Col;

const int MAX_STEPS = 80;
const float MIN_DIST = 0.0;
const float MAX_DIST = 100.0;
const float EPSILON = 0.0001;
const vec3 eye = vec3(0.0, 0.0, 5.0);
const vec3 light = vec3(1.0, 1.0, 5.0);
const float INTENSITY = 10.0;

float sphereSDF(vec3 pos, vec3 origin, float radius) {
    return length(pos-origin) - radius;
}

float capsuleSDF(vec3 pos, vec3 a, vec3 b, float radius) {
    vec3 pa = pos - a, ba = b - a;
    float h = clamp(dot(pa,ba)/dot(ba,ba), 0.0, 1.0);
    return length(pa - ba*h) - radius;
}


float greenSDF(vec3 pos) {
	float nose = sphereSDF(pos, vec3(0, 0, 0), 0.5);
	float hole1 = sphereSDF(pos, vec3(-0.2, 0, 0.5), 0.1);
	float hole2 = sphereSDF(pos, vec3(0.2, 0, 0.5), 0.1);
	float total = max(max(-hole1,nose), max(-hole2,nose));

	float eye1 = capsuleSDF(pos, vec3(-0.2,0.25,-0.5), vec3(-0.2,0.6,-0.5), 0.25);
	float eyesub = capsuleSDF(pos, vec3(-0.19,0.25,-0.3), vec3(-0.19,0.5,-0.3), 0.23);
	eye1 = max(-eyesub, eye1);

	float eye2 = capsuleSDF(pos, vec3(0.2,0.25,-0.5), vec3(0.2,0.6,-0.5), 0.25);
	eyesub = capsuleSDF(pos, vec3(0.19,0.25,-0.3), vec3(0.19,0.5,-0.3), 0.23);
	eye2 = max(-eyesub, eye2);

	float eye = min(eye1, eye2);
	total = min(total, eye);

	float cheeks = capsuleSDF(pos, vec3(-0.25,0.1,-0.5), vec3(0.25,0.1,-0.5), 0.21);
	total = min(total, cheeks);

	float neck = capsuleSDF(pos, vec3(0.0,0.0,-0.5), vec3(0.0,-0.4+abs(sin(u_Time*4.0)/10.0),-0.5), 0.4);
	total = min(total, neck);

	return total;
}

float whiteSDF(vec3 pos) {
	float eye1 = capsuleSDF(pos, vec3(-0.19,0.25,-0.3), vec3(-0.19,0.5,-0.3), 0.2);
	float eye2 = capsuleSDF(pos, vec3(0.19,0.25,-0.3), vec3(0.19,0.5,-0.3), 0.2);
	float head = min(eye1, eye2);

	float chin = sphereSDF(pos, vec3(0, -0.3+abs(sin(u_Time*4.0)/10.0), -0.3), 0.4);
	float cheek1 = sphereSDF(pos, vec3(-0.25, -0.2, -0.5), 0.25);
	float cheek2 = sphereSDF(pos, vec3(0.25, -0.2, -0.5), 0.25);
	float cheek = min(cheek1, cheek2);
	head = min(head, chin);
	head = min(head, cheek);

	float timeFactor = sin(u_Time*3.0);

	pos += vec3(0.3,0.3,0.3);
	float clouds = sphereSDF(pos, vec3(-1.5,0,0), 0.3+timeFactor/30.0);
	float clouda = sphereSDF(pos, vec3(-1.8,-0.05,0), 0.2+timeFactor/30.0);
	float cloudb = sphereSDF(pos, vec3(-1.2,-0.05,0), 0.2+timeFactor/30.0);
	clouds = min(min(clouda, cloudb), clouds);

	pos -= vec3(0.7,0.7,1.5);
	float cloudc = sphereSDF(pos, vec3(-1.5,0,0), 0.3+timeFactor/20.0);
	clouda = sphereSDF(pos, vec3(-1.8,-0.05,0), 0.2+timeFactor/20.0);
	cloudb = sphereSDF(pos, vec3(-1.2,-0.05,0), 0.2+timeFactor/20.0);
	clouds = min(min(clouda, cloudb), min(clouds, cloudc));

	pos -= vec3(2.3,-0.5,0);
	cloudc = sphereSDF(pos, vec3(-1.5,0,0), 0.3+timeFactor/25.0);
	clouda = sphereSDF(pos, vec3(-1.8,-0.05,0), 0.2+timeFactor/25.0);
	cloudb = sphereSDF(pos, vec3(-1.2,-0.05,0), 0.2+timeFactor/25.0);
	clouds = min(min(clouda, cloudb), min(clouds, cloudc));

	return min(head, clouds);
}

float redSDF(vec3 pos) {
	float timeFactor = sin(u_Time*4.0);
	return capsuleSDF(pos, vec3(0,-0.58+abs(timeFactor/10.0),-0.3), vec3(0,-0.6+abs(timeFactor/5.0),0.7-abs(timeFactor*1.0)), 0.13);
}

float blackSDF(vec3 pos) {
	float eye1 = capsuleSDF(pos, vec3(-0.19,0.25,-0.1), vec3(-0.19,0.5,-0.1), 0.1+abs(sin(1.62-u_Time*4.0)/22.0));
	float eye2 = capsuleSDF(pos, vec3(0.19,0.25,-0.1), vec3(0.19,0.5,-0.1), 0.1+abs(sin(1.62-u_Time*4.0)/22.0));

	return min(eye1, eye2);
}

vec4 sceneSDF(vec3 pos) {
	float white = whiteSDF(pos);
	float green = greenSDF(pos);
	float black = blackSDF(pos);
	float red = redSDF(pos);
	float dists[4] = float[](white, green, black, red);
	vec3 colors[4] = vec3[](vec3(1), vec3(0,1,0), vec3(0), vec3(1,0,0));

	vec4 result = vec4(0,0,0,1000000.0);
	for(int i = 0; i < 4; i++) {
		if(dists[i] < MAX_DIST && dists[i] < result.a) {
			result = vec4(colors[i], dists[i]);
		}
	}
	return result;
}

vec3 getNormal(vec3 pos, float eps) {
    vec3 nor;
    nor.y = sceneSDF(pos).a;
    nor.x = sceneSDF(vec3(pos.x+eps,pos.yz)).a - nor.y;
    nor.z = sceneSDF(vec3(pos.xy,pos.z+eps)).a - nor.y;
    nor.y = eps;
    return normalize(nor);
}

void main() {
	vec4 pos = vec4(fs_Pos.x*u_Aspect, fs_Pos.yzw);
	pos += vec4(sin(u_Time)/4.0, 0.0, 0.0, 0.0);

	vec2 uv = ((pos.xy/2.0) + 0.5);
	vec3 ray = normalize(pos.xyz-eye);
	vec3 normal;

	vec4 color = vec4(0.15, 0.5, 0.69, 1.0);
	float diffuseTerm = 1.0;
	vec4 specularColor = vec4(0.8, 0.8, 0.8, 1.0);
	float intensity = 10.0;

	float depth = MIN_DIST;
	for (int i = 0; i < MAX_STEPS; i++) {
	    vec4 sdf = sceneSDF(eye + depth * ray);
	    float dist = sdf.a;
	    if (dist < EPSILON) {
	    	color = vec4(sdf.rgb, 1.0);
	    	normal = getNormal(eye + depth * ray, EPSILON);
		    diffuseTerm = dot(normalize(normal), normalize(light));
		    diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);
		    diffuseTerm = floor(diffuseTerm*u_Cel)/u_Cel;
	        break;
	    }
	    depth += dist;

	    if (depth >= MAX_DIST) {
	    	normal = vec3(0,0,1);
	    	//specularColor = vec4(0.15, 0.5, 0.69, 1.0);
	    	intensity = -10.0;
	    	//color += vec4(0.15, 0.5, 0.69, 1.0)*fbm(vec4(pos.xyz, u_Time*0.1));
	        break;
	    }
	}

	vec4 refl = normalize(normalize(vec4(eye,1.0)-pos)+normalize(vec4(light,1)));
	float specularTerm = pow(max(dot(refl,vec4(normal,1)),0.0),intensity);
	specularTerm = floor(specularTerm*u_Cel)/u_Cel;

	out_Col = color * diffuseTerm + specularColor * specularTerm;
}
