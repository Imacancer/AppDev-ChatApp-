import io from 'socket.io-client';


export interface UserProfile {
  userId: string;
  profilePicture?: string;
}

export class WebRTCService {
  private socket: any;
  private peerConnections: Map<string, RTCPeerConnection> = new Map();
  private dataChannels: Map<string, RTCDataChannel> = new Map();
  private onMessageCallback: ((message: any) => void) | null = null;
  private onProfileUpdateCallback: ((profile: UserProfile) => void) | null = null;
  

  constructor(private userId: string) {
    this.socket = io('http://localhost:5001', {transports: ['websocket'], withCredentials: true});
    this.setupSocketListeners();
  }

  public setOnMessageCallback(callback: (message: any) => void) {
    this.onMessageCallback = callback;
  }


  public setOnProfileUpdateCallback(callback: (profile: UserProfile) => void) {
    this.onProfileUpdateCallback = callback;
  }

  private setupSocketListeners() {
    const socket = io('http://localhost:5001', { transports: ['websocket'], withCredentials: true });

    this.socket.on('connect', () => {
        console.log('Connected to server');
    });
    this.socket.on('disconnect', () => {
        console.log('Disconnected from server');
    });

    this.socket.on('reconnect', () => {
      console.log('Reconnected to server');
    });

    this.socket.on('user_joined', (data: { user_id: string }) => {
      this.createPeerConnection(data.user_id);
    });

    this.socket.on('profile_update', (profile: UserProfile) => {
      if (this.onProfileUpdateCallback) {
        this.onProfileUpdateCallback(profile);
      }
    });

    this.socket.on('connect_error', (error : any) => {
      console.error('Connection error:', error);
    });
    
    this.socket.on('error', (error : any) => {
      console.error('Socket error:', error);
    });
    

    this.socket.on('offer', async (data: { sender_id: string; offer: RTCSessionDescriptionInit }) => {
      console.log('Received offer from', data.sender_id);
      const peerConnection = this.createPeerConnection(data.sender_id);
      await peerConnection.setRemoteDescription(new RTCSessionDescription(data.offer));
      const answer = await peerConnection.createAnswer();
      await peerConnection.setLocalDescription(answer);
      console.log('Sending answer to', data.sender_id);
      this.socket.emit('answer', {
        sender_id: data.sender_id,
        answer
      });
    });

    this.socket.on('answer', async (data: { sender_id: string; answer: RTCSessionDescriptionInit }) => {
      console.log('Received answer from', data.sender_id);
      const peerConnection = this.peerConnections.get(data.sender_id);
      if (peerConnection) {
        await peerConnection.setRemoteDescription(new RTCSessionDescription(data.answer));
      }
    });

    this.socket.on('ice_candidate', async (data: { sender_id: string; candidate: RTCIceCandidateInit }) => {
      console.log('Received ICE candidate from', data.sender_id);
      const peerConnection = this.peerConnections.get(data.sender_id);
      if (peerConnection) {
        await peerConnection.addIceCandidate(new RTCIceCandidate(data.candidate));
      }
    });

    this.socket.on('message', (message: any) => {
      if (this.onMessageCallback) {
        this.onMessageCallback(message);
      }
    });
  
  }

  

  private createPeerConnection(recipientId: string): RTCPeerConnection {
    if (this.peerConnections.has(recipientId)) {
      return this.peerConnections.get(recipientId)!;
    }

    const configuration: RTCConfiguration = {
      iceServers: [
        { urls: 'stun:stun.l.google.com:19302' }
      ]
    };

    const peerConnection = new RTCPeerConnection(configuration);
    this.peerConnections.set(recipientId, peerConnection);

    // Create data channel
    const dataChannel = peerConnection.createDataChannel('messageChannel');
    this.setupDataChannel(dataChannel);
    this.dataChannels.set(recipientId, dataChannel);

    peerConnection.onicecandidate = (event) => {
      if (event.candidate) {
        console.log('ICE Candidate', event.candidate);
        this.socket.emit('ice_candidate', {
          recipient_id: recipientId,
          candidate: event.candidate
        });
      }
    };

    peerConnection.ondatachannel = (event) => {
      this.setupDataChannel(event.channel);
    };

    return peerConnection;
  }

  private setupDataChannel(dataChannel: RTCDataChannel) {
    dataChannel.onopen = () => {
      console.log('Data channel is open and ready to send data.');
    };
    dataChannel.onmessage = (event) => {
      console.log('Message received via data channel:', event.data);
      if (this.onMessageCallback) {
        this.onMessageCallback(JSON.parse(event.data));
      }
    };
    dataChannel.onclose = () => {
      console.log('Data channel is closed.');
    };
    dataChannel.onerror = (error) => {
      console.error('Data channel error:', error);
    };
  }

  public async updateProfile(profilePicture: string) {
    this.socket.emit('profile_update', {
      userId: this.userId,
      profilePicture
    });
  }

  public async joinRoom(roomId: string) {
    this.socket.emit('join_room', {
      user_id: this.userId,
      room: roomId
    });
  }

  public async sendMessage(recipientId: string, message: any) {
    try {
      const messageString = JSON.stringify(message);
      
      const dataChannel = this.dataChannels.get(recipientId);
      if (dataChannel?.readyState === 'open') {
        console.log('Sending encrypted message via WebRTC');
      } else {
        console.log('Falling back to WebSocket');
        this.socket.emit('message', {
          recipient_id: recipientId,
          message
        });
      }
    } catch (error) {
      console.error('Failed to send message:', error);
      throw error;
    }
  }
  
  public disconnect() {
    this.peerConnections.forEach((peerConnection, userId) => {
      peerConnection.close();
    });
    this.peerConnections.clear();
    this.dataChannels.clear();
    this.socket.disconnect();
  }
}