const WebSocket = require('ws');
const { v4: uuidv4 } = require('uuid');

class SicboTestClient {
  constructor(serverUrl, playerName) {
    this.serverUrl = serverUrl;
    this.playerName = playerName;
    this.playerId = uuidv4();
    this.ws = null;
  }

  connect() {
    return new Promise((resolve, reject) => {
      this.ws = new WebSocket(this.serverUrl);
      
      this.ws.on('open', () => {
        console.log(`${this.playerName} connected to server`);
        this.authenticate();
        resolve();
      });
      
      this.ws.on('message', (data) => {
        const message = JSON.parse(data.toString());
        this.handleMessage(message);
      });
      
      this.ws.on('error', (error) => {
        console.error(`${this.playerName} error:`, error);
        reject(error);
      });
      
      this.ws.on('close', () => {
        console.log(`${this.playerName} disconnected`);
      });
    });
  }

  authenticate() {
    this.sendMessage({
      id: uuidv4(),
      type: 'playerUpdate',
      fromPlayerId: this.playerId,
      data: {
        action: 'authenticate',
        player: {
          id: this.playerId,
          name: this.playerName,
          credits: 1000
        }
      },
      timestamp: new Date()
    });
  }

  createRoom(roomName) {
    this.sendMessage({
      id: uuidv4(),
      type: 'roomUpdate',
      fromPlayerId: this.playerId,
      data: {
        action: 'createRoom',
        roomName: roomName,
        maxPlayers: 8
      },
      timestamp: new Date()
    });
  }

  joinRoom(roomId) {
    this.sendMessage({
      id: uuidv4(),
      type: 'joinRoom',
      fromPlayerId: this.playerId,
      data: { roomId },
      timestamp: new Date()
    });
  }

  placeBet(roomId, betType, amount) {
    this.sendMessage({
      id: uuidv4(),
      type: 'placeBet',
      fromPlayerId: this.playerId,
      data: {
        roomId,
        bid: { type: betType, amount }
      },
      timestamp: new Date()
    });
  }

  rollDice(roomId) {
    this.sendMessage({
      id: uuidv4(),
      type: 'rollDice',
      fromPlayerId: this.playerId,
      data: { roomId },
      timestamp: new Date()
    });
  }

  sendChatMessage(roomId, text) {
    this.sendMessage({
      id: uuidv4(),
      type: 'chatMessage',
      fromPlayerId: this.playerId,
      data: { roomId, text },
      timestamp: new Date()
    });
  }

  sendMessage(message) {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify(message));
    }
  }

  handleMessage(message) {
    console.log(`${this.playerName} received:`, message.type, message.data);
  }

  disconnect() {
    if (this.ws) {
      this.ws.close();
    }
  }
}

// Test script
async function runTest() {
  const serverUrl = 'ws://localhost:8080';
  
  try {
    // Create test players
    const player1 = new SicboTestClient(serverUrl, 'Alice');
    const player2 = new SicboTestClient(serverUrl, 'Bob');
    
    // Connect players
    await player1.connect();
    await player2.connect();
    
    // Wait a bit for authentication
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    // Player 1 creates a room
    console.log('\n--- Creating Room ---');
    player1.createRoom('Test Game Room');
    
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    // Player 2 joins the room (you'd get room ID from server response)
    console.log('\n--- Joining Room ---');
    // In real scenario, you'd get the room ID from the room list
    // For testing, we'll use a placeholder
    // player2.joinRoom('room-id-here');
    
    // Place some bets
    console.log('\n--- Placing Bets ---');
    // player1.placeBet('room-id-here', 'big', 100);
    // player2.placeBet('room-id-here', 'small', 50);
    
    // Send chat messages
    console.log('\n--- Chat Messages ---');
    // player1.sendChatMessage('room-id-here', 'Good luck!');
    // player2.sendChatMessage('room-id-here', 'Thanks, you too!');
    
    // Wait a bit then disconnect
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    player1.disconnect();
    player2.disconnect();
    
    console.log('\nTest completed successfully!');
    
  } catch (error) {
    console.error('Test failed:', error);
  }
}

// Run the test if this file is executed directly
if (require.main === module) {
  runTest().then(() => {
    process.exit(0);
  }).catch((error) => {
    console.error('Test failed:', error);
    process.exit(1);
  });
}

module.exports = SicboTestClient;
