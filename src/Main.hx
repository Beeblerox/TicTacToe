package;

import haxe.ds.Vector;
import openfl.events.MouseEvent;
import openfl.events.Event;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.Lib;

enum Player
{
	X;
	O;
}

enum CellState
{
	Empty;
	X;
	O;
}

class Util
{
	public static function switchPlayer(player:Player):Player
	{
		return (player == Player.X) ? Player.O : Player.X;
	}
	
	public static function fromStateToPlayer(state:CellState):Player
	{
		return switch (state)
		{
			case CellState.X:
				Player.X;
			case CellState.O:
				Player.O;
			default:
				null;
		}
	}
	
	public static function fromPlayerToState(player:Player):CellState
	{
		return switch (player)
		{
			case Player.X:
				CellState.X;
			case Player.O:
				CellState.O;
		}
	}
}

class GameState
{
	public static inline var NUM_CELLS:Int = 9;
	
	private static inline var WIN_SCORE:Float = 10.0;
	private static inline var LOOSE_SCORE:Float = -10.0;
	
	private var board:Vector<CellState>;
	
	public function new()
	{
		board = new Vector<CellState>(NUM_CELLS);
		for (i in 0...board.length)
		{
			board[i] = Empty;
		}
	}
	
	public function equals(state:GameState):Bool
	{
		for (i in 0...board.length)
		{
			if (board[i] != state.board[i])
			{
				return false;
			}
		}
		
		return true;
	}
	
	public inline function getCellState(column:Int, row:Int):CellState
	{
		return board[column + row * 3];
	}
	
	public inline function setCellState(column:Int, row:Int, state:CellState):CellState
	{
		return board[column + row * 3] = state;
	}
	
	public inline function getCellStateByIndex(index:Int):CellState
	{
		return board[index];
	}
	
	public inline function setCellStateByIndex(index:Int, state:CellState):CellState
	{
		return board[index] = state;
	}
	
	public function copyFrom(state:GameState):Void
	{
		for (i in 0...board.length)
		{
			board[i] = state.board[i];
		}
	}
	
	public function getScore():Float
	{
		// Are any of the rows the same?
		for (j in 0...3)
		{
			var same:Bool = true;
			var v:CellState = getCellState(0, j);
			
			for (i in 1...3)
			{
				if (getCellState(i, j) != v)
				{
					same = false;
				}
			}

			if (same)
			{
				if (v == CellState.X)
				{
					return WIN_SCORE;
				}
				else if (v == CellState.O)
				{
					return LOOSE_SCORE;
				}
			}
		}
		
		// Are any of the columns the same?
		for (i in 0...3)
		{
			var same:Bool = true;
			var v:CellState = getCellState(i, 0);
			
			for (j in 1...3)
			{
				if (getCellState(i, j) != v)
				{
					same = false;
				}
			}
			
			if (same)
			{
				if (v == CellState.X)
				{
					return WIN_SCORE;
				}
				else if (v == CellState.O)
				{
					return LOOSE_SCORE;
				}
			}
		}

		// What about diagonals?
		if ((getCellState(0, 0) == getCellState(1, 1) && getCellState(0, 0) == getCellState(2, 2)) ||
			(getCellState(2, 0) == getCellState(1, 1) && getCellState(2, 0) == getCellState(0, 2)))
		{
			if (getCellState(1, 1) == CellState.X)
			{
				return WIN_SCORE;
			}
			else if (getCellState(1, 1) == CellState.O)
			{
				return LOOSE_SCORE;
			}
		}
		
		// We tied
		return 0.0;
	}
	
	public function winner():CellState
	{
		var score = getScore();
		
		if (score == WIN_SCORE)
		{
			return CellState.X;
		}
		else if (score == LOOSE_SCORE)
		{
			return CellState.O;
		}
		else
		{
			return CellState.Empty; // Tie
		}
	}
}

class GameTreeNode
{
	public var children:Array<GameTreeNode> = [];
	
	public var state(default, null):GameState;
	public var player(default, null):Player;
	
	public var minimaxValue:Null<Float>;
	public var nextNode:GameTreeNode;
	
	public function new(player:Player)
	{
		state = new GameState();
		this.player = player;
		
		minimaxValue = null;
		nextNode = null;
	}
	
	public inline function getScore():Float
	{
		return state.getScore();
	}
	
	public inline function getWinner():CellState
	{
		return state.winner();
	}
	
	public function isTerminal():Bool
	{
		if (children.length == 0)
		{
			// No more moves left
			return true;
		}
		
		// someone has won or loose
		return (state.getScore() != 0.0);
	}
}

class MiniMax
{
	public static function generateGameTree(root:GameTreeNode):Void
	{
		var currentPlayer:Player = root.player;
		var nextStatePlayer:Player = Util.switchPlayer(currentPlayer);
		var cellState:CellState = Util.fromPlayerToState(currentPlayer);
		
		// i ~ x
		// j ~ y
		for (i in 0...3)
		{
			for (j in 0...3)
			{
				if (root.state.getCellState(i, j) == CellState.Empty)
				{
					var node:GameTreeNode = new GameTreeNode(nextStatePlayer);
					root.children.push(node);
					
					node.state.copyFrom(root.state);
					node.state.setCellState(i, j, cellState);
					
					generateGameTree(node);
				}
			}
		}
	}
	
	public static function minimax(node:GameTreeNode, alpha:Null<Float> = null, beta:Null<Float> = null):Float
	{
		if (alpha == null)
		{
			alpha = Math.NEGATIVE_INFINITY;
		}
		
		if (beta == null)
		{
			beta = Math.POSITIVE_INFINITY;
		}
		
		if (node.isTerminal())
		{
			node.minimaxValue = heuristic(node);
			return node.minimaxValue;
		}
		
		if (node.player == Player.X)
		{
			var maxValue:Float = Math.NEGATIVE_INFINITY;
			var nextNode:GameTreeNode = null;
			
			for (child in node.children)
			{
				var childValue:Float = minimax(child, alpha, beta);
				
				if (childValue > maxValue)
				{
					if (childValue >= beta)
					{
						return childValue;
					}
					
					maxValue = childValue;
					nextNode = child;
				}
				
				alpha = Math.max(maxValue, alpha);
			}
			
			node.nextNode = nextNode;
			node.minimaxValue = maxValue;
			return maxValue;
		}
		else
		{
			var minValue:Float = Math.POSITIVE_INFINITY;
			var nextNode:GameTreeNode = null;
			
			for (child in node.children)
			{
				var childValue:Float = minimax(child, alpha, beta);
				
				if (childValue < minValue)
				{
					if (childValue <= alpha)
					{
						return childValue;
					}
					
					minValue = childValue;
					nextNode = child;
				}
				
				beta = Math.min(minValue, beta);
			}
			
			node.nextNode = nextNode;
			node.minimaxValue = minValue;
			return minValue;
		}
	}
	
	private static function heuristic(node:GameTreeNode):Float
	{
		return node.getScore();
	}
}

class Cell extends Sprite
{
	public var cellSize(default, null):Float;
	public var state(default, null):CellState;
	
	public function new(size:Float)
	{
		super();
		
		this.cellSize = size;
		setState(Empty);
	}
	
	public function setState(state:CellState):Void
	{
		this.state = state;
		
		graphics.clear();
		graphics.lineStyle(2, 0xffffff);
		graphics.beginFill(0x0);
		graphics.drawRect(0, 0, cellSize, cellSize);
		graphics.endFill();
		
		switch (state)
		{
			case X:
				graphics.lineStyle(2, 0xff0000);
				graphics.moveTo(0.1 * cellSize, 0.1 * cellSize);
				graphics.lineTo(0.9 * cellSize, 0.9 * cellSize);
				graphics.moveTo(0.1 * cellSize, 0.9 * cellSize);
				graphics.lineTo(0.9 * cellSize, 0.1 * cellSize);
				
			case O:
				graphics.lineStyle(2, 0xff00ff);
				graphics.drawCircle(0.5 * cellSize, 0.5 * cellSize, 0.4 * cellSize);
				
			default:
				
		}
	}
}

class Board extends Sprite
{
	public var cells:Vector<Cell>;
	
	public function new()
	{
		super();
		
		cells = new Vector<Cell>(GameState.NUM_CELLS);
		for (i in 0...cells.length)
		{
			var cell = new Cell(100);
			cell.x = (i % 3) * cell.cellSize;
			cell.y = Std.int(i / 3) * cell.cellSize;
			cells[i] = cell;
			addChild(cell);
		}
	}
	
	public function drawState(state:GameState):Void
	{
		for (i in 0...GameState.NUM_CELLS)
		{
			cells[i].setState(state.getCellStateByIndex(i));
		}
	}
}

class State extends Sprite
{
	private var game:Game;
	
	public function new(game:Game)
	{
		super();
		
		this.game = game;
	}
	
	public function onEnter():Void
	{
		
	}
	
	public function update(dt:Float):Void
	{
		
	}
	
	public function onExit():Void
	{
		removeChildren();
	}
}

class SelectGameState extends State
{
	var optionX:Cell;
	var optionO:Cell;
	var optionAi:Cell;
	
	public function new(game:Game)
	{
		super(game);
	}
	
	override public function onEnter():Void 
	{
		super.onEnter();
		
		var gameTypeText:TextField = new TextField();
		gameTypeText.width = 500;
		//gameTypeText.border = true;
		//gameTypeText.borderColor = 0xff00ff;
		gameTypeText.text = "Choose player:";
		var format:TextFormat = new TextFormat(null, 60, 0xffffff);
		format.align = TextFormatAlign.CENTER;
		gameTypeText.defaultTextFormat = format;
		gameTypeText.selectable = false;
		gameTypeText.x = 10;
		gameTypeText.y = 10;
		addChild(gameTypeText);
		
		var cellSize:Float = 100;
		
		optionX = new Cell(cellSize);
		optionX.setState(CellState.X);
		optionX.addEventListener(MouseEvent.CLICK, onClick);
		addChild(optionX);
		
		optionO = new Cell(cellSize);
		optionO.setState(CellState.O);
		optionO.addEventListener(MouseEvent.CLICK, onClick);
		addChild(optionO);
		
		optionAi = new Cell(cellSize);
		optionAi.addEventListener(MouseEvent.CLICK, onClick);
		addChild(optionAi);
		
		var aiText:TextField = new TextField();
		aiText.text = "AI";
		aiText.defaultTextFormat = new TextFormat(null, 72, 0xffffff);
		aiText.selectable = false;
		aiText.x = 10;
		optionAi.addChild(aiText);
		
		optionX.x = gameTypeText.x + 0.5 * (gameTypeText.width - 3 * cellSize);
		optionO.x = optionX.x + cellSize;
		optionAi.x = optionO.x + cellSize;
		optionX.y = optionO.y = optionAi.y = 100;
	}
	
	function onClick(e:MouseEvent):Void 
	{
		var gameType:CellState = null;
		if (Std.is(e.currentTarget, Cell))
		{
			gameType = cast(e.currentTarget, Cell).state;
		}
		
		if (gameType != null)
		{
			game.setState(new GamePlayState(game, gameType));
		}
	}
	
	override public function onExit():Void 
	{
		optionX.removeEventListener(MouseEvent.CLICK, onClick);
		optionO.removeEventListener(MouseEvent.CLICK, onClick);
		optionAi.removeEventListener(MouseEvent.CLICK, onClick);
		
		super.onExit();
	}
}

class GamePlayState extends State
{
	var gameType:CellState;
	var playerType:Player;
	
	var board:Board;
	var currentNode:GameTreeNode;
	
	var helperState:GameState;
	
	var timeAccumulator:Float = 0;
	
	public function new(game:Game, gameType:CellState)
	{
		super(game);
		
		this.gameType = gameType;
		playerType = Util.fromStateToPlayer(gameType);
	}
	
	override public function onEnter():Void 
	{
		super.onEnter();
		
		var root:GameTreeNode = new GameTreeNode(Player.X);
		
		/*
		var root:GameTreeNode = new GameTreeNode(Player.O);
		root.state.board[4] = CellState.X;
		*/
		
		board = new Board();
		board.x = board.y = 10;
		board.drawState(root.state);
		addChild(board);
		
		// generate whole game tree
		MiniMax.generateGameTree(root);
		currentNode = root;
		
		// and evaluate each move in the tree
		MiniMax.minimax(root);
		
		if (gameType != CellState.Empty)
		{
			for (cell in board.cells)
			{
				cell.addEventListener(MouseEvent.CLICK, onCellClick);
			}
		}
		
		helperState = new GameState();
	}
	
	function onCellClick(e):Void 
	{
		// not the players turn...
		if (currentNode.player != playerType)
		{
			return;
		}
		
		if (Std.is(e.currentTarget, Cell))
		{
			var cell:Cell = cast(e.currentTarget, Cell);
			
			if (cell.state == CellState.Empty)
			{
				// find next state...
				helperState.copyFrom(currentNode.state);
				
				// find cell index (vector doesn't have indexOf() method)
				var cellIndex:Int = -1;
				for (i in 0...board.cells.length)
				{
					if (cell == board.cells[i])
					{
						cellIndex = i;
					}
				}
				
				if (cellIndex >= 0)
				{
					// find next game state in children nodes of the current node
					helperState.setCellStateByIndex(cellIndex, gameType);
					for (child in currentNode.children)
					{
						if (child.state.equals(helperState))
						{
							currentNode = child;
							board.drawState(currentNode.state);
							
							// calculate game tree
							MiniMax.minimax(currentNode);
							
							timeAccumulator = 0;
						}
					}
				}
			}
		}
	}
	
	override public function update(dt:Float):Void 
	{
		super.update(dt);
		
		timeAccumulator += dt;
		if (timeAccumulator >= 1000)
		{
			timeAccumulator = 0;
			
			if (!currentNode.isTerminal())
			{
				if (playerType != currentNode.player)
				{
					currentNode = currentNode.nextNode;
					board.drawState(currentNode.state);
				}
			}
			else
			{
				// game over
				game.setState(new GameOverState(game, currentNode.getWinner()));
			}
		}
	}
	
	override public function onExit():Void 
	{
		super.onExit();
		
		helperState = null;
		
		for (cell in board.cells)
		{
			cell.removeEventListener(MouseEvent.CLICK, onCellClick);
		}
	}
}

class GameOverState extends State
{
	var winner:CellState;
	
	public function new(game:Game, winner:CellState)
	{
		super(game);
		
		this.winner = winner;
	}
	
	override public function onEnter():Void 
	{
		super.onEnter();
		
		var gameOverText:TextField = new TextField();
		gameOverText.width = 500;
		gameOverText.height = 300;
		gameOverText.multiline = true;
		
		gameOverText.text = switch (winner)
		{
			case CellState.X:
				"X has won!";
			case CellState.O:
				"O has won!";
			case CellState.Empty:
				"Tie!";
		}
		
		gameOverText.text += "\nClick to play again.";
		
		var format:TextFormat = new TextFormat(null, 60, 0xffffff);
		format.align = TextFormatAlign.CENTER;
		gameOverText.defaultTextFormat = format;
		gameOverText.selectable = false;
		gameOverText.x = 10;
		gameOverText.y = 10;
		addChild(gameOverText);
		
		Lib.current.stage.addEventListener(MouseEvent.CLICK, onClick);
	}
	
	function onClick(e):Void 
	{
		game.setState(new SelectGameState(game));
	}
	
	override public function onExit():Void 
	{
		super.onExit();
		Lib.current.stage.removeEventListener(MouseEvent.CLICK, onClick);
	}
}

class Game extends Sprite
{
	private var state:State;
	
	private var prevTime:Float;
	
	public function new()
	{
		super();
		
		prevTime = Lib.getTimer();
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}
	
	function onEnterFrame(e):Void 
	{
		var time:Float = Lib.getTimer();
		var dt:Float = time - prevTime;
		
		if (state != null)
		{
			state.update(dt);
		}
		
		prevTime = time;
	}
	
	public function setState(newState:State):Void
	{
		if (state != null)
		{
			state.onExit();
			removeChild(state);
		}
		
		state = newState;
		
		if (state != null)
		{
			addChild(state);
			state.onEnter();
		}
	}
}

class Main extends Sprite 
{
	var game:Game;
	
	public function new() 
	{
		super();
		
		game = new Game();
		game.setState(new SelectGameState(game));
		addChild(game);
	}
}
