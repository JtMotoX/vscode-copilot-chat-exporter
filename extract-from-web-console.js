(async function exportCopilotChats() {
  console.log('🚀 Starting Copilot Chat Export...\n');
  
  // Open the database
  const db = await new Promise((resolve, reject) => {
    const request = indexedDB.open('vscode-web-db');
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
  
  const tx = db.transaction(['vscode-userdata-store'], 'readonly');
  const store = tx.objectStore('vscode-userdata-store');
  
  // Get all keys
  const allKeys = await new Promise((resolve) => {
    const req = store.getAllKeys();
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => resolve([]);
  });
  
  // Filter for chat sessions
  const chatSessionKeys = allKeys.filter(key => 
    String(key).includes('/chatSessions/') && String(key).endsWith('.json')
  );
  
  console.log(`Found ${chatSessionKeys.length} chat session files\n`);
  
  const allChats = [];
  const decoder = new TextDecoder('utf-8');
  
  for (let i = 0; i < chatSessionKeys.length; i++) {
    const key = chatSessionKeys[i];
    const value = await new Promise((resolve) => {
      const req = store.get(key);
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => resolve(null);
    });
    
    if (value && value instanceof Uint8Array) {
      try {
        const jsonString = decoder.decode(value);
        const chatSession = JSON.parse(jsonString);
        
        if (chatSession.requests && chatSession.requests.length > 0) {
          for (let j = 0; j < chatSession.requests.length; j++) {
            const request = chatSession.requests[j];
            
            let userMessage = '';
            if (request.message && request.message.text) {
              userMessage = request.message.text.replace(/```[\w]*\n?/g, '').replace(/`([^`]+)`/g, '$1');
            }
            
            let copilotResponse = '';
            if (request.response && Array.isArray(request.response)) {
              const responseParts = request.response
                .filter(r => r && r.value && typeof r.value === 'string')
                .map(r => r.value.replace(/```[\w]*\n?/g, '').replace(/`([^`]+)`/g, '$1'));
              copilotResponse = responseParts.join(' ').trim();
            }
            
            if (userMessage.length > 10 && copilotResponse.length > 10) {
              allChats.push({
                key: `conversation-${j + 1}`,
                content: {
                  session: chatSession.sessionId.substring(0, 8),
                  date: new Date(chatSession.creationDate).toLocaleDateString(),
                  human: userMessage,
                  copilot: copilotResponse
                },
                type: 'conversation'
              });
            }
          }
        }
      } catch (error) {
        console.warn(`Error processing session: ${error.message}`);
      }
    }
  }
  
  console.log(`\n✅ Exported ${allChats.length} conversations`);
  
  // Download as JSON
  const jsonString = JSON.stringify(allChats, null, 2);
  const blob = new Blob([jsonString], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `copilot_export_${new Date().toISOString().replace(/[:.]/g, '-')}.json`;
  a.click();
  URL.revokeObjectURL(url);
  
  console.log('📥 Download started!');
  return allChats;
})();