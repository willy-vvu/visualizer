###
HexGeometry.coffee
Creates a THREE.BufferGeometry and fills it with hexagon points.
Then, links the points up with triangles, and fills the attribute arrays with necessary information.
###
SQRT3 = Math.sqrt(3)
hexPositions = [
  new THREE.Vector2(0,SQRT3/3)
  new THREE.Vector2(0.5,SQRT3/6)
  new THREE.Vector2(0.5,-SQRT3/6)
  new THREE.Vector2(0,-SQRT3/3)
  new THREE.Vector2(-0.5,-SQRT3/6)
  new THREE.Vector2(-0.5,SQRT3/6)
]

module.exports = (hexSide) ->
  geometry = new THREE.BufferGeometry()
  positions = new Float32Array(hexSide*hexSide*7*3)
  #TODO:Update the num of indices below later to save memory
  order = 0;
  indices = new Uint16Array((hexSide-1)*(hexSide-1)*16*3)

  indicePusher = new IndicePusher(indices)
  vertexPusher = new VertexPusher(positions)

  for o in [0..hexSide*hexSide-1]
    # Create the center of the hexagon
    row = o // hexSide
    x = o % hexSide + 0.5*(row%2)
    y = 0.5*SQRT3 * (row)
    centerPoint = vertexPusher.pushPoint(x,y,order++)
    # Create and connect edges of the hexagon
    for h in [0..hexPositions.length-1]
      hexPos = hexPositions[h]
      vertexPusher.pushPoint(x+hexPos.x,y+hexPos.y,order++)
      indicePusher.pushTri(centerPoint,centerPoint+(h+1)%6+1,centerPoint+h+1)
    # Connect between hexagons
    bottomRow = o < hexSide
    terminalLeft = o%(2*hexSide) == 0
    terminalRight = (o+1)%(2*hexSide) == 0
    if o % hexSide > 0
      # Connect left
      indicePusher.pushQuad(
        centerPoint+5,
        centerPoint+6,
        centerPoint-7+2,
        centerPoint-7+3
      )
    if (o + 1) % hexSide > 0
      # Connect right
      indicePusher.pushQuad(
        centerPoint+6,
        centerPoint+1,
        centerPoint+7+3,
        centerPoint+7+4
      )
    if not bottomRow
      if not terminalLeft
        # Connect to lower left
        indicePusher.pushQuad(
          centerPoint+4,
          centerPoint+5,
          centerPoint-7*hexSide+(row%2)*7-7+1
          centerPoint-7*hexSide+(row%2)*7-7+2,
        )
      if not terminalRight
        # Connect to lower right
        indicePusher.pushQuad(
          centerPoint+3,
          centerPoint+4,
          centerPoint-7*hexSide+(row%2)*7+6
          centerPoint-7*hexSide+(row%2)*7+1,
        )
  geometry.addAttribute("index", new THREE.BufferAttribute(indices, 1))
  geometry.addAttribute("position", new THREE.BufferAttribute(positions, 3))
  #geometry.addAttribute("position", new THREE.BufferAttribute(positions, 3))
  return geometry

# Helper class to push points for faces into an array. I originally called it FacePusher.
VertexPusher = (@positions) ->
  @index = 0
  return

VertexPusher :: pushPoint = (x, y, z) ->
  @positions[3*@index] = x
  @positions[3*@index+1] = y
  @positions[3*@index+2] = z
  return @index++

# Helper class to push vertex indices for faces into an array.
IndicePusher = (@indices) ->
  @index = 0
  return

IndicePusher :: push = (n) ->
  if @index>=@indices.length
    throw "Index "+@index+" out of range"
  @indices[@index++] = n
  return

IndicePusher :: pushTri = (a, b, c) ->
  @push(a)
  @push(b)
  @push(c)
  return

IndicePusher :: pushQuad = (a, b, c, d) ->
  @pushTri(a,b,c)
  @pushTri(a,c,d)
  return
