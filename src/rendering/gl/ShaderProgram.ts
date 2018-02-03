import {vec2, vec4, mat4} from 'gl-matrix';
import Drawable from './Drawable';
import {gl} from '../../globals';

var activeProgram: WebGLProgram = null;

export class Shader {
  shader: WebGLShader;

  constructor(type: number, source: string) {
    this.shader = gl.createShader(type);
    gl.shaderSource(this.shader, source);
    gl.compileShader(this.shader);

    if (!gl.getShaderParameter(this.shader, gl.COMPILE_STATUS)) {
      throw gl.getShaderInfoLog(this.shader);
    }
  }
};

class ShaderProgram {
  time: number;

  prog: WebGLProgram;

  attrPos: number;

  unifView: WebGLUniformLocation;

  unifTime: WebGLUniformLocation;

  unifAspect: WebGLUniformLocation;

  unifCel: WebGLUniformLocation;

  constructor(shaders: Array<Shader>) {
    this.prog = gl.createProgram();

    for (let shader of shaders) {
      gl.attachShader(this.prog, shader.shader);
    }
    gl.linkProgram(this.prog);
    if (!gl.getProgramParameter(this.prog, gl.LINK_STATUS)) {
      throw gl.getProgramInfoLog(this.prog);
    }

    // Raymarcher only draws a quad in screen space! No other attributes
    this.attrPos = gl.getAttribLocation(this.prog, "vs_Pos");

    this.unifView = gl.getUniformLocation(this.prog, "u_View");

    this.unifAspect = gl.getUniformLocation(this.prog, "u_Aspect");

    this.unifTime = gl.getUniformLocation(this.prog, "u_Time");

    this.unifCel = gl.getUniformLocation(this.prog, "u_Cel");
    
    this.time = 0.0;
  }

  use() {
    if (activeProgram !== this.prog) {
      gl.useProgram(this.prog);
      activeProgram = this.prog;
    }
  }

  setCelFactor(cel: number) {
    this.use();
    if (this.unifCel !== -1) {
      gl.uniform1f(this.unifCel, cel);
    }
  }

  draw(d: Drawable) {
    this.use();

    gl.uniform1f(this.unifTime, this.time);
    this.time += 0.01;

    var w = Math.max(document.documentElement.clientWidth, window.innerWidth || 0);
    var h = Math.max(document.documentElement.clientHeight, window.innerHeight || 0);
    gl.uniform1f(this.unifAspect, w/h);

    if (this.attrPos != -1 && d.bindPos()) {
      gl.enableVertexAttribArray(this.attrPos);
      gl.vertexAttribPointer(this.attrPos, 4, gl.FLOAT, false, 0, 0);
    }

    d.bindIdx();
    gl.drawElements(d.drawMode(), d.elemCount(), gl.UNSIGNED_INT, 0);

    if (this.attrPos != -1) gl.disableVertexAttribArray(this.attrPos);

  }
};

export default ShaderProgram;
