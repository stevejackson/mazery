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
      @maze.update()
      #@maze.drawGrid()
      @maze.drawAllCells()

    # start our loop!
    framesPerSecond = 60
    setInterval(logicLoop, 1000 / framesPerSecond)

class Maze
  constructor: (@context, @width, @height, @cellSize) ->
    @cells = new Array(@width)

    for i in [0..@width]
      @cells[i] = new Array(@height)

    for i in [0..@width]
      for j in [0..@height]
        @cells[i][j] = new Cell(i, j)

    @location = @getRandomCell()
    @cells[@location[0]][@location[1]].visited = true
    @hunting = false
    @complete = false

  drawGrid: ->
    @context.strokeStyle = "#eaeaea"
    for x in [-0.5..@width * @cellSize + 0.5]
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
    red = 255#Math.floor(Math.random() * 256)
    green = Math.floor(Math.random() * 0)
    blue = Math.floor(Math.random() * 0)
    opacity = 1 #Math.random() * 1.5
    "rgba(" + red + "," + green + "," + blue + "," + opacity + ")"

  getRandomCell: ->
    x = Math.floor(Math.random() * @width)
    y = Math.floor(Math.random() * @height)
    return [x, y]

  getCellColor: (x, y) ->
    if @cells[x][y].visited
      return "#161621"
    else
      return "white"

    "red"

  drawCell: (x, y) ->
    # draw order:
    #  * EITHER "empty" cell color, or "traversed" cell color
    #  * "recently visited" cell color, fades away
    #  * "hunted" cell color, fades away
    
    @cells[x][y].update()
    @context.globalAlpha = @cells[x][y].alpha
    locX = x * @cellSize
    locY = y * @cellSize
    
    # draw either "empty" cell color, or "traversed" cell color
    @context.fillStyle = @getCellColor(x, y)
    @context.fillRect(locX, locY, @cellSize, @cellSize)
    @context.fill()

    # draw the "recently visited" cell color, fades away
    if @cells[x][y].recentlyVisited
      @context.fillStyle = "#e63c9f"
      @context.globalAlpha = @cells[x][y].visitedAlpha
      @context.fillRect(locX, locY, @cellSize, @cellSize)
      @context.fill()

    # draw the "hunted" cell color, fades away
    if @cells[x][y].hunted
      @context.fillStyle = "#e63c9f"
      @context.globalAlpha = @cells[x][y].huntedAlpha
      @context.fillRect(locX, locY, @cellSize, @cellSize)
      @context.fill()
    
    @drawCellBorders(x, y)

  drawCellBorders: (x, y) ->
    @context.strokeStyle = "#eaeaea"
    @context.globalAlpha = 1

    # top border:
    if @cells[x][y].north
      @context.beginPath()
      @context.moveTo(x * @cellSize, y * @cellSize)
      @context.lineTo(x * @cellSize + @cellSize, y * @cellSize)
      @context.fill()
      @context.closePath()
      @context.stroke()
    if @cells[x][y].south
      @context.beginPath()
      @context.moveTo(x * @cellSize, y * @cellSize + @cellSize)
      @context.lineTo(x * @cellSize + @cellSize, y * @cellSize + @cellSize)
      @context.fill()
      @context.closePath()
      @context.stroke()
    if @cells[x][y].east
      @context.beginPath()
      @context.moveTo(x * @cellSize + @cellSize, y * @cellSize)
      @context.lineTo(x * @cellSize + @cellSize, y * @cellSize + @cellSize)
      @context.fill()
      @context.closePath()
      @context.stroke()
    if @cells[x][y].west
      @context.beginPath()
      @context.moveTo(x * @cellSize, y * @cellSize)
      @context.lineTo(x * @cellSize, y * @cellSize + @cellSize)
      @context.fill()
      @context.closePath()
      @context.stroke()

  drawAllCells: ->
    for x in [0..@width]
      for y in [0..@height]
        @drawCell(x, y)

  update: ->
    # maze generation logic
    if @complete
      return true

    if @hunting
      # when we're hunting, we're sweeping down row by row to find a cell that is
      # unvisited, and adjacent to a visited cell.
      hunt = @huntInRow(@location[1])
      if hunt
        @hunting = false
        @location = hunt
        neighbor = @getNeighbor(@location[0], @location[1], true)
        unless not neighbor
          @cells[neighbor[0]][neighbor[1]].visited = true
          @cells[neighbor[0]][neighbor[1]].recentlyVisited = true
          @cells[neighbor[0]][neighbor[1]].visitedAlpha = 1
          @location = neighbor
      else
        unless @location[1] == @height
          @location[1] += 1
        else
          @complete = true
    else
      neighbor = @getNeighbor(@location[0], @location[1], false)
      unless not neighbor
        @cells[neighbor[0]][neighbor[1]].visited = true
        @cells[neighbor[0]][neighbor[1]].recentlyVisited = true
        @cells[neighbor[0]][neighbor[1]].visitedAlpha = 1
        @location = neighbor
      else
        @hunting = true
        @location = [0, 0]

  huntInRow: (row) =>
    # let's visually mark this row as hunted for drawing purposes.
    for i in [0..@width]
      @cells[i][row].hunted = true
      @cells[i][row].huntedAlpha = 1
    for i in [0..@width]
      if not @cells[i][row].visited
        # if this cell is unvisited, is it next to a cell that IS visited?
        if @cells[i-1]?[row]?.visited or
        @cells[i+1]?[row]?.visited or
        @cells[i]?[row-1]?.visited or
        @cells[i]?[row+1]?.visited
          return [i, row]
    return false

  getNeighbor: (x, y, visited) ->
    # 0 1 2 3 4 - north east south west
    # store which sides we've checked.
    checkedSides = []

    # have we found a successful neighbor yet?
    until checkedSides.length == 4
      sideToCheck = Math.floor(Math.random() * 4)
      if sideToCheck in checkedSides
        continue
      else
        # Check if this is a valid direction for us to go. If so, remove the edge.
        if sideToCheck == 0 and @cells[x]?[y - 1]?.visited == visited
          @cells[x][y].north = false
          @cells[x][y - 1].south = false
          return [x, y - 1]
        else if sideToCheck == 1 and @cells[x + 1]?[y]?.visited == visited
          @cells[x][y].east = false
          @cells[x + 1][y].west = false
          return [x + 1, y]
        else if sideToCheck == 2 and @cells[x]?[y + 1]?.visited == visited
          @cells[x][y].south = false
          @cells[x][y + 1].north = false
          return [x, y + 1]
        else if sideToCheck == 3 and @cells[x - 1]?[y]?.visited == visited
          @cells[x][y].west = false
          @cells[x - 1][y].east = false
          return [x - 1, y]

        checkedSides.push(sideToCheck)

    false

  validCellLocation: (x, y) ->
    return x >= 0 and x <= @width and y >= 0 and y <= @height

class Cell
  constructor: (@x, @y) ->
    @states = []
    @alpha = 1.0
    @visited = false
    @north = true
    @east = true
    @south = true
    @west = true
    @visitedAlpha = 0
    @huntedAlpha = 0
    
    @recentlyVisited = false
    @hunted = false

  update: ->
    if @recentlyVisited
      @visitedAlpha = if @visitedAlpha == 0 then 0 else @visitedAlpha - 0.03
      if @visitedAlpha <= 0
        @visitedAlpha = 0
        @recentlyVisited = false

    if @hunted
      @huntedAlpha = if @huntedAlpha == 0 then 0 else @huntedAlpha - 0.03
      if @huntedAlpha <= 0
        @hunted = false
        @huntedAlpha = 0
