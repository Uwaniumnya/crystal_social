const WebSocket = require('ws');
const { v4: uuidv4 } = require('uuid');

// Card deck and game logic
const SUITS = ['hearts', 'diamonds', 'clubs', 'spades'];
const VALUES = ['ace', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten', 'jack', 'queen', 'king'];

class BlackjackServer {
  constructor() {
    this.wss = new WebSocket.Server({ port: 8080 });
    this.players = new Map(); // playerId -> player data
    this.rooms = new Map(); // roomId -> room data
    
    this.wss.on('connection', this.handleConnection.bind(this));
    console.log('Blackjack WebSocket server started on port 8080');
  }

  handleConnection(ws) {
    console.log('New client connected');
    
    ws.on('message', (data) => {
      try {
        const message = JSON.parse(data.toString());
        this.handleMessage(ws, message);
      } catch (error) {
        console.error('Invalid message format:', error);
        this.sendError(ws, 'Invalid message format');
      }
    });

    ws.on('close', () => {
      console.log('Client disconnected');
      this.handleDisconnect(ws);
    });

    ws.on('error', (error) => {
      console.error('WebSocket error:', error);
    });
  }

  handleMessage(ws, message) {
    const { type, data } = message;
    
    switch (type) {
      case 'playerJoin':
        this.handlePlayerJoin(ws, data);
        break;
      case 'createRoom':
        this.handleCreateRoom(ws, data);
        break;
      case 'joinRoom':
        this.handleJoinRoom(ws, data);
        break;
      case 'leaveRoom':
        this.handleLeaveRoom(ws, data);
        break;
      case 'placeBet':
        this.handlePlaceBet(ws, data);
        break;
      case 'hit':
        this.handleHit(ws, data);
        break;
      case 'stand':
        this.handleStand(ws, data);
        break;
      case 'doubleDown':
        this.handleDoubleDown(ws, data);
        break;
      case 'split':
        this.handleSplit(ws, data);
        break;
      case 'surrender':
        this.handleSurrender(ws, data);
        break;
      case 'chat':
        this.handleChat(ws, data);
        break;
      default:
        this.sendError(ws, `Unknown message type: ${type}`);
    }
  }

  handlePlayerJoin(ws, data) {
    const { player } = data;
    const playerId = player.id;
    
    this.players.set(playerId, {
      ...player,
      ws: ws,
      roomId: null
    });
    
    ws.playerId = playerId;
    
    this.sendMessage(ws, {
      type: 'playerJoined',
      data: { player, success: true }
    });
    
    // Send available rooms
    this.sendAvailableRooms(ws);
    console.log(`Player ${player.name} joined`);
  }

  handleCreateRoom(ws, data) {
    const { name, minBet = 10, maxBet = 1000 } = data;
    const playerId = ws.playerId;
    const player = this.players.get(playerId);
    
    if (!player) {
      this.sendError(ws, 'Player not found');
      return;
    }

    const roomId = uuidv4();
    const room = {
      id: roomId,
      name,
      hostId: playerId,
      players: [player],
      maxPlayers: 6,
      status: 'waiting',
      createdAt: new Date(),
      currentPlayerId: null,
      playerHands: [],
      dealerHand: null,
      deck: [],
      minBet,
      maxBet,
      playerBets: {},
      gameHistory: []
    };

    this.rooms.set(roomId, room);
    player.roomId = roomId;

    this.sendMessage(ws, {
      type: 'roomCreated',
      data: { room, success: true }
    });

    this.broadcastAvailableRooms();
    console.log(`Room ${name} created by ${player.name}`);
  }

  handleJoinRoom(ws, data) {
    const { roomId } = data;
    const playerId = ws.playerId;
    const player = this.players.get(playerId);
    const room = this.rooms.get(roomId);

    if (!player) {
      this.sendError(ws, 'Player not found');
      return;
    }

    if (!room) {
      this.sendError(ws, 'Room not found');
      return;
    }

    if (room.players.length >= room.maxPlayers) {
      this.sendError(ws, 'Room is full');
      return;
    }

    // Add player to room
    room.players.push(player);
    player.roomId = roomId;

    this.sendMessage(ws, {
      type: 'roomJoined',
      data: { room, success: true }
    });

    // Notify other players in room
    this.broadcastToRoom(roomId, {
      type: 'playerJoinedRoom',
      data: { player, room }
    }, playerId);

    this.broadcastAvailableRooms();
    console.log(`Player ${player.name} joined room ${room.name}`);
  }

  handleLeaveRoom(ws, data) {
    const playerId = ws.playerId;
    const player = this.players.get(playerId);
    
    if (!player || !player.roomId) {
      this.sendError(ws, 'Player not in room');
      return;
    }

    const room = this.rooms.get(player.roomId);
    if (!room) {
      this.sendError(ws, 'Room not found');
      return;
    }

    // Remove player from room
    room.players = room.players.filter(p => p.id !== playerId);
    player.roomId = null;

    // If room is empty, delete it
    if (room.players.length === 0) {
      this.rooms.delete(room.id);
    } else {
      // If host left, assign new host
      if (room.hostId === playerId && room.players.length > 0) {
        room.hostId = room.players[0].id;
      }
      
      // Notify remaining players
      this.broadcastToRoom(room.id, {
        type: 'playerLeftRoom',
        data: { playerId, room }
      });
    }

    this.sendMessage(ws, {
      type: 'roomLeft',
      data: { success: true }
    });

    this.broadcastAvailableRooms();
    console.log(`Player ${player.name} left room`);
  }

  handlePlaceBet(ws, data) {
    const { amount } = data;
    const playerId = ws.playerId;
    const player = this.players.get(playerId);
    
    if (!player || !player.roomId) {
      this.sendError(ws, 'Player not in room');
      return;
    }

    const room = this.rooms.get(player.roomId);
    if (!room) {
      this.sendError(ws, 'Room not found');
      return;
    }

    if (room.status !== 'betting') {
      this.sendError(ws, 'Not in betting phase');
      return;
    }

    if (amount < room.minBet || amount > room.maxBet) {
      this.sendError(ws, `Bet must be between ${room.minBet} and ${room.maxBet}`);
      return;
    }

    if (player.credits < amount) {
      this.sendError(ws, 'Insufficient credits');
      return;
    }

    // Place bet
    room.playerBets[playerId] = amount;
    player.credits -= amount;

    this.broadcastToRoom(room.id, {
      type: 'betPlaced',
      data: { playerId, amount, room }
    });

    // Check if all players have bet
    if (Object.keys(room.playerBets).length === room.players.length) {
      this.startDealing(room);
    }

    console.log(`Player ${player.name} bet ${amount}`);
  }

  startDealing(room) {
    room.status = 'dealing';
    room.deck = this.createDeck();
    room.playerHands = [];
    room.dealerHand = { playerId: 'dealer', cards: [], handValue: 0, isBust: false, isBlackjack: false, isStanding: false };

    // Deal initial cards
    room.players.forEach(player => {
      const hand = {
        playerId: player.id,
        cards: [this.drawCard(room.deck), this.drawCard(room.deck)],
        handValue: 0,
        isBust: false,
        isBlackjack: false,
        isStanding: false
      };
      hand.handValue = this.calculateHandValue(hand.cards);
      hand.isBlackjack = hand.handValue === 21;
      room.playerHands.push(hand);
    });

    // Deal dealer cards
    room.dealerHand.cards = [this.drawCard(room.deck), this.drawCard(room.deck)];
    room.dealerHand.handValue = this.calculateHandValue(room.dealerHand.cards);

    room.status = 'playing';
    room.currentPlayerId = room.players[0].id;

    this.broadcastToRoom(room.id, {
      type: 'dealingComplete',
      data: { room }
    });

    console.log(`Dealing started in room ${room.name}`);
  }

  handleHit(ws, data) {
    const playerId = ws.playerId;
    const player = this.players.get(playerId);
    
    if (!player || !player.roomId) {
      this.sendError(ws, 'Player not in room');
      return;
    }

    const room = this.rooms.get(player.roomId);
    if (!room || room.status !== 'playing' || room.currentPlayerId !== playerId) {
      this.sendError(ws, 'Not your turn');
      return;
    }

    const playerHand = room.playerHands.find(h => h.playerId === playerId);
    if (!playerHand || playerHand.isStanding || playerHand.isBust) {
      this.sendError(ws, 'Cannot hit');
      return;
    }

    // Deal card
    const card = this.drawCard(room.deck);
    playerHand.cards.push(card);
    playerHand.handValue = this.calculateHandValue(playerHand.cards);
    
    if (playerHand.handValue > 21) {
      playerHand.isBust = true;
    }

    this.broadcastToRoom(room.id, {
      type: 'cardDealt',
      data: { playerId, card, room }
    });

    // Move to next player if bust or 21
    if (playerHand.isBust || playerHand.handValue === 21) {
      this.nextPlayer(room);
    }

    console.log(`Player ${player.name} hit, hand value: ${playerHand.handValue}`);
  }

  handleStand(ws, data) {
    const playerId = ws.playerId;
    const player = this.players.get(playerId);
    
    if (!player || !player.roomId) {
      this.sendError(ws, 'Player not in room');
      return;
    }

    const room = this.rooms.get(player.roomId);
    if (!room || room.status !== 'playing' || room.currentPlayerId !== playerId) {
      this.sendError(ws, 'Not your turn');
      return;
    }

    const playerHand = room.playerHands.find(h => h.playerId === playerId);
    if (!playerHand) {
      this.sendError(ws, 'Hand not found');
      return;
    }

    playerHand.isStanding = true;

    this.broadcastToRoom(room.id, {
      type: 'playerStood',
      data: { playerId, room }
    });

    this.nextPlayer(room);

    console.log(`Player ${player.name} stood with hand value: ${playerHand.handValue}`);
  }

  handleDoubleDown(ws, data) {
    const playerId = ws.playerId;
    const player = this.players.get(playerId);
    
    if (!player || !player.roomId) {
      this.sendError(ws, 'Player not in room');
      return;
    }

    const room = this.rooms.get(player.roomId);
    const playerHand = room.playerHands.find(h => h.playerId === playerId);
    
    if (!playerHand || playerHand.cards.length !== 2) {
      this.sendError(ws, 'Cannot double down');
      return;
    }

    const currentBet = room.playerBets[playerId];
    if (player.credits < currentBet) {
      this.sendError(ws, 'Insufficient credits to double down');
      return;
    }

    // Double the bet
    room.playerBets[playerId] *= 2;
    player.credits -= currentBet;

    // Deal one card and stand
    const card = this.drawCard(room.deck);
    playerHand.cards.push(card);
    playerHand.handValue = this.calculateHandValue(playerHand.cards);
    playerHand.isStanding = true;
    
    if (playerHand.handValue > 21) {
      playerHand.isBust = true;
    }

    this.broadcastToRoom(room.id, {
      type: 'playerDoubledDown',
      data: { playerId, card, room }
    });

    this.nextPlayer(room);

    console.log(`Player ${player.name} doubled down`);
  }

  handleChat(ws, data) {
    const { message } = data;
    const playerId = ws.playerId;
    const player = this.players.get(playerId);
    
    if (!player || !player.roomId) {
      this.sendError(ws, 'Player not in room');
      return;
    }

    this.broadcastToRoom(player.roomId, {
      type: 'chatMessage',
      data: {
        id: uuidv4(),
        playerId,
        playerName: player.name,
        message,
        timestamp: new Date().toISOString()
      }
    });

    console.log(`Chat from ${player.name}: ${message}`);
  }

  nextPlayer(room) {
    const currentIndex = room.players.findIndex(p => p.id === room.currentPlayerId);
    const nextIndex = currentIndex + 1;
    
    if (nextIndex >= room.players.length) {
      // All players finished, dealer's turn
      this.dealerTurn(room);
    } else {
      room.currentPlayerId = room.players[nextIndex].id;
      this.broadcastToRoom(room.id, {
        type: 'nextPlayer',
        data: { room }
      });
    }
  }

  dealerTurn(room) {
    room.status = 'dealerTurn';
    
    // Dealer hits until 17 or bust
    while (room.dealerHand.handValue < 17) {
      const card = this.drawCard(room.deck);
      room.dealerHand.cards.push(card);
      room.dealerHand.handValue = this.calculateHandValue(room.dealerHand.cards);
    }
    
    if (room.dealerHand.handValue > 21) {
      room.dealerHand.isBust = true;
    }

    // Calculate results and payouts
    this.calculateResults(room);
    
    room.status = 'complete';
    
    this.broadcastToRoom(room.id, {
      type: 'gameComplete',
      data: { room }
    });

    // Reset for next round after 5 seconds
    setTimeout(() => {
      this.resetRoom(room);
    }, 5000);

    console.log(`Dealer finished with hand value: ${room.dealerHand.handValue}`);
  }

  calculateResults(room) {
    const dealerValue = room.dealerHand.handValue;
    const dealerBust = room.dealerHand.isBust;

    room.players.forEach(player => {
      const playerHand = room.playerHands.find(h => h.playerId === player.id);
      const bet = room.playerBets[player.id];
      let winnings = 0;

      if (playerHand.isBust) {
        // Player busted, lose bet (already deducted)
        winnings = 0;
      } else if (playerHand.isBlackjack && !room.dealerHand.isBlackjack) {
        // Player blackjack, dealer no blackjack
        winnings = bet * 2.5; // 3:2 payout
      } else if (dealerBust || playerHand.handValue > dealerValue) {
        // Dealer bust or player higher
        winnings = bet * 2;
      } else if (playerHand.handValue === dealerValue) {
        // Push
        winnings = bet;
      }
      // Otherwise player loses (winnings = 0)

      player.credits += winnings;
      
      // Update stats
      if (winnings > bet) {
        player.gamesWon = (player.gamesWon || 0) + 1;
      } else if (winnings === 0) {
        player.gamesLost = (player.gamesLost || 0) + 1;
      }
      
      player.totalBet = (player.totalBet || 0) + bet;
      player.totalWon = (player.totalWon || 0) + winnings;
    });
  }

  resetRoom(room) {
    room.status = 'betting';
    room.currentPlayerId = null;
    room.playerHands = [];
    room.dealerHand = null;
    room.deck = [];
    room.playerBets = {};

    this.broadcastToRoom(room.id, {
      type: 'roomReset',
      data: { room }
    });

    console.log(`Room ${room.name} reset for next round`);
  }

  createDeck() {
    const deck = [];
    for (const suit of SUITS) {
      for (const value of VALUES) {
        deck.push({ suit, value });
      }
    }
    return this.shuffleDeck(deck);
  }

  shuffleDeck(deck) {
    for (let i = deck.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [deck[i], deck[j]] = [deck[j], deck[i]];
    }
    return deck;
  }

  drawCard(deck) {
    return deck.pop();
  }

  calculateHandValue(cards) {
    let value = 0;
    let aces = 0;
    
    for (const card of cards) {
      if (card.value === 'ace') {
        aces++;
        value += 11;
      } else if (['jack', 'queen', 'king'].includes(card.value)) {
        value += 10;
      } else {
        value += parseInt(card.value) || this.getCardValue(card.value);
      }
    }
    
    // Adjust for aces
    while (value > 21 && aces > 0) {
      value -= 10;
      aces--;
    }
    
    return value;
  }

  getCardValue(value) {
    const valueMap = {
      'two': 2, 'three': 3, 'four': 4, 'five': 5, 'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10
    };
    return valueMap[value] || 0;
  }

  handleDisconnect(ws) {
    const playerId = ws.playerId;
    if (!playerId) return;

    const player = this.players.get(playerId);
    if (player && player.roomId) {
      // Handle leaving room
      this.handleLeaveRoom(ws, {});
    }

    this.players.delete(playerId);
    console.log(`Player ${playerId} disconnected`);
  }

  sendMessage(ws, message) {
    if (ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify(message));
    }
  }

  sendError(ws, error) {
    this.sendMessage(ws, {
      type: 'error',
      data: { error }
    });
  }

  broadcastToRoom(roomId, message, excludePlayerId = null) {
    const room = this.rooms.get(roomId);
    if (!room) return;

    room.players.forEach(player => {
      if (player.id !== excludePlayerId && player.ws.readyState === WebSocket.OPEN) {
        this.sendMessage(player.ws, message);
      }
    });
  }

  sendAvailableRooms(ws) {
    const rooms = Array.from(this.rooms.values()).map(room => ({
      ...room,
      players: room.players.map(p => ({ id: p.id, name: p.name, credits: p.credits }))
    }));

    this.sendMessage(ws, {
      type: 'availableRooms',
      data: { rooms }
    });
  }

  broadcastAvailableRooms() {
    const rooms = Array.from(this.rooms.values()).map(room => ({
      ...room,
      players: room.players.map(p => ({ id: p.id, name: p.name, credits: p.credits }))
    }));

    const message = {
      type: 'availableRooms',
      data: { rooms }
    };

    this.players.forEach(player => {
      if (!player.roomId && player.ws.readyState === WebSocket.OPEN) {
        this.sendMessage(player.ws, message);
      }
    });
  }
}

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

// Start server
new BlackjackServer();
