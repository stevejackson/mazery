$(document).ready ->
  mazery()

mazery = ->
  # grab the context
  canvas = $('#mazecanvas').get(0)
  canvasWidth = canvas.width
  canvasHeight = canvas.height
  cellSize = 30

  # get the real canvas size that we can fit.
  for x in [0..canvasWidth]
    if x + cellSize * 2 > canvasWidth
      mazeWidth = x
      break
    x += cellSize
  for y in [0..canvasHeight]
    if y + cellSize * 2 > canvasHeight
      mazeHeight = y
      break
    y += cellSize

  if canvas.getContext
    context = canvas.getContext('2d')
    @maze = new Maze context, Math.floor(mazeWidth / cellSize), Math.floor(mazeHeight / cellSize), cellSize
    
    logicLoop = ->
      # clear the screen every frame.
      context.clearRect(0, 0, canvas.width, canvas.height)
      # rendering / logic
      @maze.drawGrid()
      @maze.drawAllCells()

    # start our loop!
    framesPerSecond = 5
    setInterval(logicLoop, 1000 / framesPerSecond)

class Maze
  constructor: (@context, @width, @height, @cellSize) ->
    @cells = new Array(@width)

    for i in [0..@width]
      @cells[i] = new Array(@height)

    for i in [0..@width]
      for j in [0..@height]
        @cells[i][j] = new Cell(i, j)

    @cells[5][5].state = "obstacle"
    @cells[5][5].alpha = 0.5

  drawGrid: ->
    @context.strokeStyle = "#eaeaea"
    for x in [0.5..@width * @cellSize + 0.5]
      @context.beginPath()
      @context.moveTo(x, 0)
      @context.lineTo(x, @height * @cellSize)
      @context.fill()
      @context.closePath()
      @context.stroke()
      x += @cellSize

    for y in [0.5..@height * @cellSize + 0.5]
      @context.beginPath()
      @context.moveTo(0, y)
      @context.lineTo(@width * @cellSize, y)
      @context.fill()
      @context.closePath()
      @context.stroke()
      y += @cellSize
  
  getRandomColor: (x, y) ->
    red = Math.floor(Math.random() * 256)
    green = Math.floor(Math.random() * 256)
    blue = Math.floor(Math.random() * 256)
    "rgba(" + red + "," + green + "," + blue + ",1)"

  getCellColor: (x, y) ->
    #//return "rgba(255, 255, 0, 1)"
    return @getRandomColor(x, y)
    if @cells[x][y].state == "empty"
      return "white"
    else if @cells[x][y].state == "obstacle"
      return "black"

    "red"

  drawCell: (x, y) ->
    @context.clearRect(locX, locY, @cellSize, @cellSize)
    @context.fill()

    @cells[x][y].update()
    @context.globalAlpha = @cells[x][y].alpha
    @context.fillStyle = @getCellColor(x, y)

    locX = x * @cellSize
    locY = y * @cellSize
    @context.fillRect(locX, locY, @cellSize, @cellSize)
    @context.fill()

  drawAllCells: ->
    for x in [0..@width]
      for y in [0..@height]
        @drawCell(x, y)

class Cell
  constructor: (@x, @y) ->
    @state = "empty"
    @alpha = 1.0

  setState: (@state) ->
    @state = @state

  update: ->
    @alpha = 1#//Math.random()
