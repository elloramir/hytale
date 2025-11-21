attribute float AmbientOcclusion; // Custom attribute

uniform mat4 projectionMatrix; // handled by the camera
uniform mat4 viewMatrix;       // handled by the camera
uniform mat4 modelMatrix;      // models send their own model matrices when drawn
uniform bool isCanvasEnabled;  // detect when this model is being rendered to a canvas

// define some varying vectors that are useful for writing custom fragment shaders
varying vec4 worldPosition;
varying vec4 viewPosition;
varying vec4 screenPosition;
varying vec4 vertexColor;
varying float ao;

vec4 position(mat4 transformProjection, vec4 vertexPosition) {
    // calculate the positions of the transformed coordinates on the screen
    // save each step of the process, as these are often useful when writing custom fragment shaders
    worldPosition = modelMatrix * vertexPosition;
    viewPosition = viewMatrix * worldPosition;
    screenPosition = projectionMatrix * viewPosition;
    ao = AmbientOcclusion;

    // save some data from this vertex for use in fragment shaders
    vertexColor = VertexColor;

    // for some reason models are flipped vertically when rendering to a canvas
    // so we need to detect when this is being rendered to a canvas, and flip it back
    if (isCanvasEnabled) {
        screenPosition.y *= -1.0;
    }

    return screenPosition;
}
