$(document).ready ->
  mazery()

mazery = ->
  # grab the context
  canvas = $('#mazecanvas').get(0)
  canvasWidth = canvas.width
  canvasHeight = canvas.height
  cellSize = 30
 
  # get the real canvas size that we can fit.
  for x in [0.5..canvasWidth]
    if x + cellSize > canvasWidth
      canvasWidth = x
    x += cellSize
  for y in [0.5..canvasHeight]
    if y + cellSize > canvasHeight
      canvasHeight = y
    y += cellSize
  
  if canvas.getContext
    context = canvas.getContext('2d')

    # draw a grid.
    context.strokeStyle = "#eaeaea"
    for x in [0.5..canvasWidth]
      context.beginPath()
      context.moveTo(x, 0)
      context.lineTo(x, canvasHeight)
      context.fill()
      context.closePath()
      context.stroke()
      x += cellSize

    for y in [0.5..canvasHeight]
      context.beginPath()
      context.moveTo(0, y)
      context.lineTo(canvasWidth, y)
      context.fill()
      context.closePath()
      context.stroke()
      y += cellSize
