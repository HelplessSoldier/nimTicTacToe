include karax/prelude
import sugar

type
  Game = ref object
    board: array[3, array[3, string]]
    currentPlayerX: bool
    running: bool
    draw: bool
    winner: string


proc initGame(): Game =
  ## creates a game instance with starting values
  return Game(board: [
    [" ", " ", " "], 
    [" ", " ", " "], 
    [" ", " ", " "]],
    currentPlayerX: true,
    running: true,
    draw: false,
    winner: "")


proc renderTurnWinText(game: Game): VNode =
  ## renders the current player if the game's still going
  ## if the game's over, say who won, or a draw
  var turnText: string

  if game.winner != "":
    turnText = "Winner: " & $game.winner
  elif game.draw:
    turnText = "It's a draw!"
  else:
    turnText = "Current player: " & 
    (if game.currentPlayerX: "X" else: "O")

  return buildHtml(tdiv(id="turnWinContainer")):
    p(id="turnWinText"):
      text turnText


proc renderResetButton(game: var Game): VNode =
  ## button to reset the game's variables
  proc resetBoard(game: var Game) =
    game.running = true
    game.currentPlayerX = true
    game.draw = false
    game.winner = ""
    for i in 0..2:
      for j in 0..2:
        game.board[i][j] = " "

  return buildHtml(tdiv):
    button(id="resetButton", 
           onclick=()=>resetBoard(game)):
      text "Reset"


proc cell(i, j: int, game: var Game): VNode =
  ## a single cell of the game board, 
  ## has a method to add X or O to the board on click
  proc placePiece(i: int, j: int, game: var Game): proc() =
    return proc() =
      if game.board[i][j] == " " and game.running:
        game.board[i][j] = if game.currentPlayerX: "X" else: "O"
        game.currentPlayerX = not game.currentPlayerX
  
  return buildHtml(tdiv(class="cellContainer")):
    p(class= "cell", onclick=placePiece(i, j, game)):
      text game.board[i][j]


proc renderBoard(game: var Game): VNode =
  ## makes the dom elements for the board
  result = buildHtml(tdiv(id="board")):
    for i in 0..2:
      for j in 0..2:
        cell(i, j, game)


proc endConditions(game: var Game) =
  proc checkWin(game: var Game) =
    ## looks at each possible line for a win state.
    ## stops the game and sets the winner var if win state
    proc checkLine(startX: int, startY: int, dX: int, dY: int) =
        let symbol = game.board[startX][startY]
        if symbol != " " and
            symbol == game.board[startX + dX][startY + dY] and
            symbol == game.board[startX + 2 * dX][startY + 2 * dY]:
            game.running = false
            game.winner = symbol

    for i in 0..2:
        checkLine(i, 0, 0, 1)  # vertical
        checkLine(0, i, 1, 0)  # horizontal

    checkLine(0, 0, 1, 1)  # diagonal (top-left to bottom-right)
    checkLine(0, 2, 1, -1)  # diagonal (top-right to bottom-left)


  proc checkDraw(game: var Game) =
    ## checks if all cells are filled
    ## stops game and sets draw condition to true if so
    if game.winner == "":
      var filledCells = 0
      for i in 0..2:
        for j in 0..2:
          if game.board[i][j] != " ":
            filledCells += 1

      if filledCells == 9 and game.winner == "":
        game.running = false
        game.draw = true

  # check for win first.
  # other way favors draw on filled board, 
  # even if winner exists
  checkWin(game)
  checkDraw(game)

# entry point
var game = initGame()
proc main: VNode =
  endConditions(game)
  result = buildHtml(tdiv):
    renderTurnWinText(game)
    renderBoard(game)
    renderResetButton(game)

setRenderer main

