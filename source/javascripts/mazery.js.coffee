# steve jackson, 2011
# use at your own peril.

$(document).ready ->
  mazery()

  #$(document).keypress (event) -> 
  #  if event.which == 13
  #    mazery()

  # 'Generate' button handler
  $('#generate').click ->
    mazery()

mazery = ->
  # grab the context
  canvas = $('#mazecanvas').get(0)
  canvas.width = canvas.width
  canvasWidth = canvas.width
  canvasHeight = canvas.height

  # get the inputs from the form
  cellSize = parseInt($('#cellsize').val())
  framesPerSecond = parseInt($('#fps').val())

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
      @maze.drawAllCells()

      $('#generate').click ->
        clearInterval(mazeInterval)

    # start our loop!
    mazeInterval = setInterval(logicLoop, 1000 / framesPerSecond)

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

  getRandomCell: ->
    x = Math.floor(Math.random() * @width)
    y = Math.floor(Math.random() * @height)
    [x, y]

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

  drawAllCellBorders: (x, y) ->
    @context.strokeStyle = "#eaeaea"
    @context.globalAlpha = 1

    for x in [0..@width]
      for y in [0..@height]
        @context.beginPath()
        if @cells[x][y].north
          @context.moveTo(x * @cellSize, y * @cellSize)
          @context.lineTo(x * @cellSize + @cellSize, y * @cellSize)
        if @cells[x][y].south
          @context.moveTo(x * @cellSize, y * @cellSize + @cellSize)
          @context.lineTo(x * @cellSize + @cellSize, y * @cellSize + @cellSize)
        if @cells[x][y].east
          @context.moveTo(x * @cellSize + @cellSize, y * @cellSize)
          @context.lineTo(x * @cellSize + @cellSize, y * @cellSize + @cellSize)
        if @cells[x][y].west
          @context.moveTo(x * @cellSize, y * @cellSize)
          @context.lineTo(x * @cellSize, y * @cellSize + @cellSize)
        @context.closePath()
        @context.stroke()

  drawAllCells: ->
    for x in [0..@width]
      for y in [0..@height]
        @drawCell(x, y)
    @drawAllCellBorders()

  update: ->
    # maze generation logic
    return true if @complete

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
    # normal traversal mode
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
    # now let's actually hunt this row.
    for i in [0..@width]
      if not @cells[i][row].visited
        # if this cell is unvisited, is it next to a cell that IS visited?
        if @cells[i-1]?[row]?.visited or
        @cells[i+1]?[row]?.visited or
        @cells[i]?[row-1]?.visited or
        @cells[i]?[row+1]?.visited
          return [i, row]
    # we couldn't find valid prey.
    false

  getNeighbor: (x, y, visited) ->
    # 0 1 2 3 - north east south west
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

    # we couldn't find a valid neighbor
    false

class Cell
  constructor: (@x, @y) ->
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
    # slowly deplete the alpha values if they're active
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
