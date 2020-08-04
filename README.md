# Texture04

# 修改顶点着色器,纹理坐标(配置见：shaderv.vsh 文件)

attribute vec4 position;

attribute vec2 textCoordinate;

varying lowp vec2 varyTextCoord;

void main()

{

    varyTextCoord = vec2(textCoordinate.x,1.0-textCoordinate.y);

    gl_Position = position;

}
