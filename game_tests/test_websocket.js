const WebSocket = require('ws');

const ws = new WebSocket('ws://localhost:3000');

ws.on('open', function open() {
  console.log('✅ Connected to server');
  
  // Send initial message
  ws.send('');
});

ws.on('message', function message(data) {
  console.log('📨 Received:', data.toString());
  
  // Test commands in sequence
  setTimeout(() => {
    console.log('📤 Sending /say command');
    ws.send('/say Hello from Node.js!');
  }, 500);
  
  setTimeout(() => {
    console.log('📤 Sending /witness command');
    ws.send('/witness');
  }, 1000);
  
  setTimeout(() => {
    console.log('🔌 Closing connection');
    ws.close();
  }, 2000);
});

ws.on('error', function error(err) {
  console.log('❌ Error:', err.message);
});

ws.on('close', function close() {
  console.log('🔌 Connection closed');
});