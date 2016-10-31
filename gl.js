var gl;

function start() {
  var canvas = document.getElementById("main_canvas");
  gl = initGl(canvas);

  var resolutionDownscale = 2;

  var controlPanel = document.getElementById("control_panel");
  controlPanel.addEventListener('click', function() {
    if (controlPanel.classList.contains('hidden')
        || event.target.id == 'control_panel'
        || event.target.classList.contains('disclosure')
        || event.target.classList.contains('arrow')) {
      controlPanel.classList.toggle('hidden');
    }
  });

  var resSlider = document.getElementById("resolution");
  resSlider.oninput = function() {
    resolutionDownscale = Math.pow(2, (-resSlider.value));
    window.onresize();
  }

  canvas.width = window.innerWidth/resolutionDownscale;
  canvas.height = window.innerHeight/resolutionDownscale;
  gl.viewport(0, 0, canvas.width, canvas.height);
  window.onresize = function() {
    canvas.width = window.innerWidth/resolutionDownscale;
    canvas.height = window.innerHeight/resolutionDownscale;
    gl.viewport(0, 0, canvas.width, canvas.height);
  };

  var program = initShaders(gl);

  var vBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, vBuffer);
  var vertices = new Float32Array([
      1.0,  1.0,
     -1.0,  1.0,
      1.0, -1.0,
     -1.0, -1.0]);
  gl.bufferData(gl.ARRAY_BUFFER, vertices, gl.STATIC_DRAW);
  gl.bindAttribLocation(program, 0, 'a_Position');
  gl.vertexAttribPointer(0, 2, gl.FLOAT, false, 0, 0);
  gl.enableVertexAttribArray(0);
  gl.clearColor(0.0,0.0,0.0,1.0);

  var startTime = new Date().getTime();
  var lastTime;
  var fpsWait = 0;
  var timeSum = 0;
  window.setInterval(function() {
    gl.clear(gl.COLOR_BUFFER_BIT);
    var time = ((new Date().getTime()-startTime) / 1000) % 100000;
    gl.uniform1f(gl.getUniformLocation(program, "iGlobalTime"), time);
    gl.uniform2fv(gl.getUniformLocation(program, "iResolution"), [canvas.width, canvas.height]);
    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);

    if (fpsWait >= 20) {
      var frameL = (timeSum/fpsWait);
      var fps = "";
      if (frameL != 0) {
        fps += Math.round(1/frameL);
      }
      document.getElementById("fps_counter").innerHTML = fps;
      fpsWait = 0;
      timeSum = 0;
    }
    if (lastTime !== undefined) {
      fpsWait++;
      var dt = time-lastTime
      timeSum += dt;

      if (dt > 2.0) {
        console.log("Displaying frame took over 2 seconds. Automatically reducing resolution.");
        resSlider.value -= 1;
        resSlider.oninput();
      }
    }
    lastTime = time;
  }, 16.66);
}

function initGl(canvas) {
  try {
    return canvas.getContext("webgl") || canvas.getContext("experimental-webgl");
  } catch(e) {
    alert("Unable to initialize WebGL. See console for details.");
    throw e;
  }
}

function initShaders(gl) {
  var program = gl.createProgram();

  var frag = loadText('rayworld.glsl');
  var fShader = gl.createShader(gl.FRAGMENT_SHADER);
  gl.shaderSource(fShader, frag);
  gl.compileShader(fShader);

  var vs = gl.createShader(gl.VERTEX_SHADER);
  gl.shaderSource(vs, loadText("ver.glsl"));
  gl.compileShader(vs);

  if (!gl.getShaderParameter(fShader, gl.COMPILE_STATUS)) {
    console.error("Shader compilation failed: "+gl.getShaderInfoLog(fShader));
    return null;
  }

  if (!gl.getShaderParameter(vs, gl.COMPILE_STATUS)) {
    console.error("Shader compilation failed: "+gl.getShaderInfoLog(vs));
    return null;
  }

  gl.attachShader(program, fShader);
  gl.attachShader(program, vs);
  gl.deleteShader(fShader);
  gl.deleteShader(vs);
  gl.linkProgram(program);

  var linked = gl.getProgramParameter(program, gl.LINK_STATUS)
  if(!linked) {
    console.error("Program linking failed: "+gl.getProgramInfoLog(program));
    gl.deleteProgram(program);
    return null;
  }

  gl.useProgram(program);
  return program;
}

function loadText(path) {
  request = new XMLHttpRequest();
  request.open("GET", path, false);
  request.send(null);

  if (request.status === 200) {
    return request.responseText;
  } else {
    console.err("Failed to load shader: "+path);
  }
}
