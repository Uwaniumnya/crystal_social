const WebSocket = require('ws');
const { v4: uuidv4 } = require('uuid');

class SicboMultiplayerServer {
  constructor() {
    this.players = new Map(); // playerId -> player object
    this.rooms = new Map();   // roomId -> room object
    this.connections = new Map(); // playerId -> WebSocket connection
  }

  start(port = 8080) {
    this.wss = new WebSocket.Server({ port });
    
    this.wss.on('connection', (ws) => {
      console.log('New client connected');
      
      ws.on('message', (data) => {
        try {
          const message = JSON.parse(data.toString());
          this.handleMessage(ws, message);
        } catch (error) {
          console.error('Error parsing message:', error);
          this.sendError(ws, 'Invalid message format');
        }
      });
      
      ws.on('close', () => {
        console.log('Client disconnected');
        this.handleDisconnection(ws);
      });
      
      ws.on('error', (error) => {
        console.error('WebSocket error:', error);
      });
    });
    
    console.log(`Sicbo Multiplayer Server running on port ${port}`);
  }

  handleMessage(ws, message) {
    const { type, fromPlayerId, data } = message;
    
    switch (type) {
      case 'playerUpdate':
        if (data.action === 'authenticate') {
          this.authenticatePlayer(ws, data.player);
        }
        break;
        
      case 'joinRoom':
        this.handleJoinRoom(fromPlayerId, data.roomId);
        break;
        
      case 'leaveRoom':
        this.handleLeaveRoom(fromPlayerId, data.roomId);
        break;
        
      case 'placeBet':
        this.handlePlaceBet(fromPlayerId, data.roomId, data.bid);
        break;
        
      case 'removeBet':
        this.handleRemoveBet(fromPlayerId, data.roomId, data.bidType);
        break;
        
      case 'startRound':
        this.handleStartRound(fromPlayerId, data.roomId);
        break;
        
      case 'rollDice':
        this.handleRollDice(fromPlayerId, data.roomId);
        break;
        
      case 'chatMessage':
        this.handleChatMessage(fromPlayerId, data.roomId, data.text);
        break;
        
      default:
        console.log('Unknown message type:', type);
    }
  }

  authenticatePlayer(ws, playerData) {
    const player = {
      id: playerData.id,
      name: playerData.name,
      credits: playerData.credits || 1000,
      status: 'online',
      lastSeen: new Date(),
      avatarUrl: playerData.avatarUrl
    };
    
    this.players.set(player.id, player);
    this.connections.set(player.id, ws);
    ws.playerId = player.id;
    
    console.log(`Player authenticated: ${player.name} (${player.id})`);
    
    // Send available rooms
    this.sendAvailableRooms(player.id);
  }

  createRoom(hostId, roomName, maxPlayers = 8) {
    const room = {
      id: uuidv4(),
      name: roomName,
      hostId: hostId,
      players: [],
      maxPlayers: maxPlayers,
      status: 'waiting',
      currentRound: null,
      bets: new Map(),
      rollHistory: [],
      createdAt: new Date()
    };
    
    this.rooms.set(room.id, room);
    this.broadcastRoomList();
    
    return room;
  }

  handleJoinRoom(playerId, roomId) {
    const room = this.rooms.get(roomId);
    const player = this.players.get(playerId);
    
    if (!room || !player) {
      this.sendError(playerId, 'Room or player not found');
      return;
    }
    
    if (room.players.length >= room.maxPlayers) {
      this.sendError(playerId, 'Room is full');
      return;
    }
    
    if (!room.players.find(p => p.id === playerId)) {
      room.players.push(player);
      console.log(`Player ${player.name} joined room ${room.name}`);
    }
    
    this.broadcastRoomUpdate(room);
    this.broadcastRoomList();
  }

  handleLeaveRoom(playerId, roomId) {
    const room = this.rooms.get(roomId);
    
    if (!room) return;
    
    room.players = room.players.filter(p => p.id !== playerId);
    
    // Delete room if empty
    if (room.players.length === 0) {
      this.rooms.delete(roomId);
    } else {
      this.broadcastRoomUpdate(room);
    }
    
    this.broadcastRoomList();
  }

  handlePlaceBet(playerId, roomId, betData) {
    const room = this.rooms.get(roomId);
    
    if (!room || room.status !== 'waiting') {
      this.sendError(playerId, 'Cannot place bet at this time');
      return;
    }
    
    if (!room.bets.has(playerId)) {
      room.bets.set(playerId, []);
    }
    
    const playerBets = room.bets.get(playerId);
    
    // Remove existing bet of same type
    const existingIndex = playerBets.findIndex(bet => bet.type === betData.type);
    if (existingIndex >= 0) {
      playerBets.splice(existingIndex, 1);
    }
    
    // Add new bet
    playerBets.push(betData);
    
    this.broadcastToRoom(roomId, {
      id: uuidv4(),
      type: 'placeBet',
      fromPlayerId: playerId,
      data: { roomId, bet: betData },
      timestamp: new Date()
    });
  }

  handleRemoveBet(playerId, roomId, bidType) {
    const room = this.rooms.get(roomId);
    
    if (!room) return;
    
    const playerBets = room.bets.get(playerId);
    if (playerBets) {
      const index = playerBets.findIndex(bet => bet.type === bidType);
      if (index >= 0) {
        playerBets.splice(index, 1);
      }
    }
    
    this.broadcastToRoom(roomId, {
      id: uuidv4(),
      type: 'removeBet',
      fromPlayerId: playerId,
      data: { roomId, bidType },
      timestamp: new Date()
    });
  }

  handleStartRound(playerId, roomId) {
    const room = this.rooms.get(roomId);
    
    if (!room || room.hostId !== playerId) {
      this.sendError(playerId, 'Only room host can start round');
      return;
    }
    
    room.status = 'playing';
    room.currentRound = {
      id: uuidv4(),
      startTime: new Date(),
      bets: new Map(room.bets)
    };
    
    this.broadcastToRoom(roomId, {
      id: uuidv4(),
      type: 'startRound',
      fromPlayerId: playerId,
      data: { roomId },
      timestamp: new Date()
    });
    
    this.broadcastRoomUpdate(room);
  }

  handleRollDice(playerId, roomId) {
    const room = this.rooms.get(roomId);
    
    if (!room || room.status !== 'playing') {
      this.sendError(playerId, 'Cannot roll dice at this time');
      return;
    }
    
    // Generate random dice roll
    const roll = [
      Math.floor(Math.random() * 6) + 1,
      Math.floor(Math.random() * 6) + 1,
      Math.floor(Math.random() * 6) + 1
    ];
    
    const total = roll.reduce((sum, die) => sum + die, 0);
    
    room.rollHistory.push({
      roll,
      total,
      timestamp: new Date()
    });
    
    // Calculate payouts
    this.calculatePayouts(room, roll, total);
    
    room.status = 'waiting';
    room.currentRound = null;
    room.bets.clear();
    
    this.broadcastToRoom(roomId, {
      id: uuidv4(),
      type: 'rollDice',
      fromPlayerId: playerId,
      data: { roomId, roll, total },
      timestamp: new Date()
    });
    
    this.broadcastRoomUpdate(room);
  }

  calculatePayouts(room, roll, total) {
    // Simplified payout calculation
    for (const [playerId, bets] of room.bets) {
      const player = this.players.get(playerId);
      if (!player) continue;
      
      let totalWinnings = 0;
      
      for (const bet of bets) {
        const won = this.checkBetWin(bet, roll, total);
        if (won) {
          const payout = this.calculateBetPayout(bet);
          totalWinnings += payout;
        } else {
          totalWinnings -= bet.amount;
        }
      }
      
      player.credits += totalWinnings;
    }
  }

  checkBetWin(bet, roll, total) {
    switch (bet.type) {
      case 'big': return total >= 11 && total <= 17;
      case 'small': return total >= 4 && total <= 10;
      case 'odd': return total % 2 === 1;
      case 'even': return total % 2 === 0;
      default: return false;
    }
  }

  calculateBetPayout(bet) {
    // Simple 1:1 payout for basic bets
    const payouts = {
      'big': bet.amount * 2,
      'small': bet.amount * 2,
      'odd': bet.amount * 2,
      'even': bet.amount * 2
    };
    
    return payouts[bet.type] || bet.amount;
  }

  handleChatMessage(playerId, roomId, text) {
    const player = this.players.get(playerId);
    
    if (!player) return;
    
    this.broadcastToRoom(roomId, {
      id: uuidv4(),
      type: 'chatMessage',
      fromPlayerId: playerId,
      data: {
        roomId,
        text,
        playerName: player.name
      },
      timestamp: new Date()
    });
  }

  broadcastToRoom(roomId, message) {
    const room = this.rooms.get(roomId);
    if (!room) return;
    
    for (const player of room.players) {
      const ws = this.connections.get(player.id);
      if (ws && ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify(message));
      }
    }
  }

  broadcastRoomUpdate(room) {
    this.broadcastToRoom(room.id, {
      id: uuidv4(),
      type: 'roomUpdate',
      data: { room },
      timestamp: new Date()
    });
  }

  broadcastRoomList() {
    const roomList = Array.from(this.rooms.values()).map(room => ({
      id: room.id,
      name: room.name,
      players: room.players,
      maxPlayers: room.maxPlayers,
      status: room.status
    }));
    
    for (const [playerId, ws] of this.connections) {
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({
          id: uuidv4(),
          type: 'roomUpdate',
          data: { rooms: roomList },
          timestamp: new Date()
        }));
      }
    }
  }

  sendAvailableRooms(playerId) {
    const ws = this.connections.get(playerId);
    if (!ws || ws.readyState !== WebSocket.OPEN) return;
    
    const roomList = Array.from(this.rooms.values()).map(room => ({
      id: room.id,
      name: room.name,
      players: room.players,
      maxPlayers: room.maxPlayers,
      status: room.status
    }));
    
    ws.send(JSON.stringify({
      id: uuidv4(),
      type: 'roomUpdate',
      data: { rooms: roomList },
      timestamp: new Date()
    }));
  }

  sendError(playerIdOrWs, errorMessage) {
    let ws;
    
    if (typeof playerIdOrWs === 'string') {
      ws = this.connections.get(playerIdOrWs);
    } else {
      ws = playerIdOrWs;
    }
    
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify({
        id: uuidv4(),
        type: 'error',
        data: { message: errorMessage },
        timestamp: new Date()
      }));
    }
  }

  handleDisconnection(ws) {
    const playerId = ws.playerId;
    if (!playerId) return;
    
    // Remove player from all rooms
    for (const room of this.rooms.values()) {
      const playerIndex = room.players.findIndex(p => p.id === playerId);
      if (playerIndex >= 0) {
        room.players.splice(playerIndex, 1);
        
        if (room.players.length === 0) {
          this.rooms.delete(room.id);
        } else {
          this.broadcastRoomUpdate(room);
        }
      }
    }
    
    // Clean up player data
    this.players.delete(playerId);
    this.connections.delete(playerId);
    
    this.broadcastRoomList();
  }
}

// Start server
const server = new SicboMultiplayerServer();
server.start(8080);
