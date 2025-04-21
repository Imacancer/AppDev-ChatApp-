// Conversation.tsx
import React, { useState, useEffect, useRef } from "react";
import {
  View,
  Text,
  TextInput,
  FlatList,
  Image,
  StyleSheet,
  TouchableOpacity,
  SafeAreaView,
  KeyboardAvoidingView,
  Platform,
  Animated,
  ActivityIndicator,
  Dimensions,
} from "react-native";
import { useRouter, useLocalSearchParams } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import axios from "axios";
import * as SecureStore from "expo-secure-store";
import { WebRTCService } from "../websockets/socket";
import CryptoJS from "crypto-js";
import { decryptMessage, encryptMessage } from "@/utils/encryption";
import { API_URL} from "@/constants/url";
import { LOCALHOST_URL } from "@/constants/url";
import { MY_API_IP_URL } from "@/constants/ip";
import * as ImagePicker from "expo-image-picker";
import { Video, ResizeMode } from "expo-av";
import * as MediaLibrary from "expo-media-library";
import { generateECDHKeys } from "@/utils/encryption"; 

const SCREEN_WIDTH = Dimensions.get("window").width;
const PROFILE_DRAWER_WIDTH = SCREEN_WIDTH * 0.8;


const getToken = async () => {
  if (Platform.OS === "web") {
    return sessionStorage.getItem("userToken");
  } else {
    return await SecureStore.getItemAsync("userToken");
  }
};

const getUserData = async () => {
  if (Platform.OS === "web") {
    const data = sessionStorage.getItem("userData");
    return data ? JSON.parse(data) : null;
  } else {
    const data = await SecureStore.getItemAsync("userData");
    return data ? JSON.parse(data) : null;
  }
};

interface Message {
  _id: string;
  senderId: string;
  recipientId: string;
  message: string;
  isMedia?: boolean;
  timestamp: string;
  viewed: boolean;
  classificationMessages?: ClassificationMessage[];
  flaggedUrls?: string[];
}

interface ClassificationMessage {
  url: string;
  classification: "benign" | "potentially malicious" | "malicious";
  score: number;
  message: string;
}


interface User {
  _id: string;
  userId: string;
  name: string;
  username: string;
  profilePicture?: string;
  email: string;
}

const Conversation: React.FC = () => {
  const [messages, setMessages] = useState<Message[]>([]);
  const [newMessage, setNewMessage] = useState("");
  const [currentUser, setCurrentUser] = useState<User | null>(null);
  const [recipient, setRecipient] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [isProfileVisible, setProfileVisible] = useState(false);
  const flatListRef = useRef<FlatList>(null);
  const profileDrawerAnim = useRef(new Animated.Value(SCREEN_WIDTH)).current;
  const [webRTCService, setWebRTCService] = useState<WebRTCService | null>(
    null
  );
  const [sharedSecret, setSharedSecret] = useState<string | null>(null);
  const [selectedMedia, setSelectedMedia] = useState<string | null>(null);

  const router = useRouter();
  const { id } = useLocalSearchParams<{ id: string }>();

  const computeSharedSecret = async (recipientPublicKey: string) => {
    const privateKey = await SecureStore.getItemAsync("privateKey");
    if (!privateKey) {
      throw new Error("Private key not found");
    }
    // This is a placeholder. In production, use a proper ECDH library.
    // const sharedSecret = CryptoJS.SHA256(
    //   privateKey + recipientPublicKey
    // ).toString(CryptoJS.enc.Hex);

    const keys = [privateKey, recipientPublicKey].sort();
    const sharedSecret = CryptoJS.SHA256(keys.join("")).toString(
      CryptoJS.enc.Hex
    );
    return sharedSecret;
  };


  useEffect(() => {
    console.log("Messages updated:", messages);
  }, [messages]);
  
  useEffect(() => {
    console.log("Dependencies check:", {
      currentUserId: currentUser?.userId,
      recipientId: id, // Use the route parameter directly
      hasSharedSecret: !!sharedSecret
    });
  
    const initializeWebRTC = async () => {
      if (currentUser?.userId && id) { // Use id instead of recipient?.userId
        console.log("Initializing WebRTC service...");
        const service = new WebRTCService(currentUser.userId);
        service.setOnMessageCallback((message) => {
          setMessages((prev) => [...prev, message]);
        });
        await service.joinRoom(
          `chat_${currentUser.userId}_${id}`
        );
        setWebRTCService(service);
        console.log("WebRTC service initialized successfully");
      } else {
        console.log("Can't initialize WebRTC - missing userId");
      }
    };
  
    initializeWebRTC();
    return () => {
      if (webRTCService) {
        webRTCService.setOnMessageCallback(() => {});
      }
    };
  }, [currentUser?.userId, id]); 
  

  // Animation for profile drawer
  const toggleProfile = () => {
    Animated.timing(profileDrawerAnim, {
      toValue: isProfileVisible
        ? SCREEN_WIDTH
        : SCREEN_WIDTH - PROFILE_DRAWER_WIDTH,
      duration: 300,
      useNativeDriver: true,
    }).start(() => setProfileVisible(!isProfileVisible));
  };

  useEffect(() => {
    initializeConversation();
  }, [id]);

  const initializeConversation = async () => {
    try {
      const token = await getToken();
      const userDataStr = await getUserData();
  
      if (!token || !userDataStr) {
        router.replace("/");
        return;
      }
  
      setCurrentUser(userDataStr);
  
      // Fetch recipient details
      const recipientResponse = await axios.get(
        //`http://127.0.0.1:5001/api/get_user/${id}`,
        //`${LOCALHOST_URL}/get_user/${id}`,
        `${API_URL}/get_user/${id}`, // Use this if you are using android emulator
        //`${MY_API_IP_URL}/get_user/${id}`, // Use this one if you are using a physical android device
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );
      console.warn("Recipient response:", recipientResponse);
      const recipientData = recipientResponse.data.user;
  
      setRecipient(recipientData);
  
      if (recipientData.publicKey) {
        // Removed shared secret generation logic
        console.warn("Recipient public key found, but no encryption needed.");
        await fetchMessages(token, userDataStr.userId);
      } else {
        console.warn("Recipient public key not found.");
      }
    } catch (error) {
      console.error("Initialization error:", error);
    } finally {
      setLoading(false);
    }
  };  

  const fetchMessages = async (
    token: string,
    userId: string
  ) => {
    try {
      const response = await axios.get(
        `${API_URL}/messages/conversation/${userId}/${id}`,
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );
  

      const messages = response.data.map((msg: Message) => {
        const raw = msg.message;
  
        return { ...msg, message: raw }; 
      });
  
      setMessages(messages);
    } catch (error) {
      console.error("Error fetching user messages:", error);
    }
  };  

  const markUnreadMessagesAsViewed = async (
    messages: Message[],
    token: string
  ) => {
    try {
      const unreadMessages = messages.filter(
        (msg) => msg.recipientId === currentUser?.userId && !msg.viewed
      );

      await Promise.all(
        unreadMessages.map((msg) =>
          axios.put(
            //`http://127.0.0.1:5001/api/messages/view/${msg._id}`,
            //`${LOCALHOST_URL}/messages/view/${msg._id}`,
            `${API_URL}/messages/view/${msg._id}`, // Use this if you are using an android emulator
            //`${MY_API_IP_URL}/messages/view/${msg._id}`, // Use this if you are using physical android device
            {},
            {
              headers: { Authorization: `Bearer ${token}` },
            }
          )
        )
      );
    } catch (error) {
      console.error("Error marking messages as viewed:", error);
    }
  };

  const sendMessage = async () => {
    if ((!newMessage.trim() && !selectedMedia) || !currentUser) {
      console.log("Message not sent: missing content or user data", {
        newMessage: newMessage.trim(),
        selectedMedia,
        currentUser
      });
      return;
    }
  
    console.log("WebRTC service status:", !!webRTCService);
    
    let mediaUrl = null;

    if (selectedMedia) {
      console.log("Uploading media...", selectedMedia);
      mediaUrl = await uploadMedia(selectedMedia);
      if (!mediaUrl) {
        alert("Failed to upload media.");
        return;
      }
    }
  
    console.log("Media uploaded:", mediaUrl);
  
    try {
      const messageObj = {
        _id: Date.now().toString(),
        senderId: currentUser.userId,
        recipientId: id,
        message: mediaUrl || newMessage.trim(),
        isMedia: !!mediaUrl,
        timestamp: new Date().toISOString(),
        viewed: false,
      };
  
      const response = await axios.post(`${API_URL}/messages/send`, {
        sender_id: currentUser.userId,
        recipient_id: id,
        message: mediaUrl || newMessage.trim(),
        isMedia: !!mediaUrl,
        file_url: mediaUrl,
      });
  
      if (response.data.blocked) {
        alert(`🚫 Message blocked due to high-risk link:\n${response.data.url}\nConfidence: ${(response.data.probability * 100).toFixed(2)}%\n\n${response.data.classificationMessage}`);
        return;
      }
  
      if (response.data.malicious && response.data.classificationMessages?.length > 0) {
        const warnings = response.data.classificationMessages.map((msg: { url: string; message: string }) =>
          `🔗 ${msg.url}\n⚠️ ${msg.message}`
        ).join("\n\n");
  
        alert(`Caution: The message contains potentially risky links.\n\n${warnings}`);
      }
      
      // Send message via WebRTC if available
      /*
      if (webRTCService) {
        try {
          await webRTCService.sendMessage(id, messageObj);
          console.log("Message sent via WebRTC");
        } catch (rtcError) {
          console.error("Error sending via WebRTC, but HTTP successful:", rtcError);
        }
      } else {
        console.log("WebRTC not available, message sent via HTTP only");
      }
      */

      // Update local state
      setMessages((prev) => [...prev, messageObj]);
      setNewMessage("");
      setSelectedMedia(null);
      flatListRef.current?.scrollToEnd();
    } catch (error: any) {
      console.error("Error sending message:", error);

      if (error.response?.status === 400 && error.response?.data?.blocked) {
        const data = error.response.data;
        alert(`🚫 Message blocked due to high-risk link:\n${data.url}\nConfidence: ${(data.probability * 100).toFixed(2)}%\n\n${data.classificationMessage}`);
        return;
      }
      
      alert("Failed to send message. Please try again.");
    }
  };

  const pickMedia = async () => {
    let result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ["images", "videos"], 
      allowsEditing: false,
      quality: 1,
    });

    console.log("Image Picker Result:", JSON.stringify(result, null, 2));

    if (result.assets && result.assets.length > 0) {
      const croppedUri = result.assets[0].uri;
      console.log("Selected Media URI:", croppedUri);
      setSelectedMedia(croppedUri);
    }
};


  const uploadMedia = async (mediaUri: string) => {
    try {
      const formData = new FormData();
  
      const response = await fetch(mediaUri);
      
      if (!response.ok) {
        throw new Error(`Failed to fetch media. Status: ${response.status}`);
      }
  
      const blob = await response.blob();
      const fileType = blob.type || (mediaUri.endsWith(".mp4") ? "video/mp4" : "image/jpeg");
      const fileExtension = fileType.split("/")[1] || "jpg"; 
  
      formData.append("file", {
        uri: mediaUri,
        type: fileType,
        name: `upload.${fileExtension}`,
      } as any);

      console.log("FormData before upload:", formData); 
  
      console.log("Uploading media to:", `${API_URL}/messages/upload`);
      
      const uploadResponse = await axios.post(
        `${API_URL}/messages/upload`, 
        formData,
        {
          headers: {
            "Content-Type": "multipart/form-data",
          },
        }
      );
  
      console.log("Upload successful:", uploadResponse.data);
      return uploadResponse.data.url; 
    } catch (error) {
      console.error("Error uploading media:",error);
      return null;
    }
  };
  
  
  const renderMessage = ({ item }: { item: Message }) => {
    const isOwnMessage = item.senderId === currentUser?.userId;
    const hasPotentialMalicious = item.classificationMessages?.some(
      (msg: { classification: string }) => msg.classification === "potentially malicious"
    );
  
    return (
      <View style={[styles.messageContainer, isOwnMessage ? styles.ownMessage : styles.otherMessage]}>
        {!isOwnMessage && (
          <Image
            source={{ uri: recipient?.profilePicture || "https://via.placeholder.com/40" }}
            style={styles.messageAvatar}
          />
        )}
  
        <View style={[styles.messageBubble, isOwnMessage ? styles.ownBubble : styles.otherBubble]}>
          {item.message?.includes("https://res.cloudinary.com") ? (
            item.message.endsWith(".mp4") ? (
              <Video
                source={{ uri: item.message }}
                style={styles.videoMessage}
                useNativeControls
                resizeMode={ResizeMode.CONTAIN}
              />
            ) : (
              <Image
                source={{ uri: item.message }}
                style={styles.imageMessage}
                resizeMode="contain"
                onError={(error) => {
                  console.log("Image Load Error:", error.nativeEvent.error);
                  console.log("Failed URL:", item.message);
                }}
              />
            )
          ) : (
            <Text style={[styles.messageText, isOwnMessage ? styles.ownMessageText : styles.otherMessageText]}>
              {item.message}
            </Text>
          )}
  
          {hasPotentialMalicious && (
          <View style={styles.warningBox}>
            <Text style={styles.warningText}>⚠️ This message contains a potentially harmful link.</Text>
            {item.classificationMessages?.map((msg: any, index: number) => (
              msg.classification === "potentially malicious" && (
                <Text key={index} style={styles.warningDetail}>
                  🔗 {msg.url} — {msg.message}
                </Text>
              )
            ))}
          </View>
        )}

  
          <Text style={styles.timestamp}>
            {new Date(item.timestamp).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}
          </Text>
        </View>
      </View>
    );
  };
  

  if (loading) {
    return (
      <SafeAreaView style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#007AFF" />
      </SafeAreaView>
    );
  }

  if (!messages) return null;

  return (
    <SafeAreaView style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()}>
          <Ionicons name="chevron-back" size={24} color="#007AFF" />
        </TouchableOpacity>

        <TouchableOpacity style={styles.headerProfile} onPress={toggleProfile}>
          <Image
            source={{
              uri:
                recipient?.profilePicture || "https://via.placeholder.com/40",
            }}
            style={styles.headerAvatar}
          />
          <Text style={styles.headerName}>{recipient?.name}</Text>
        </TouchableOpacity>
      </View>

      {/* Messages */}
      <FlatList
        ref={flatListRef}
        data={messages}
        renderItem={renderMessage}
        keyExtractor={(item) => item._id}
        contentContainerStyle={styles.messagesList}
        onContentSizeChange={() => flatListRef.current?.scrollToEnd()}
        inverted={false}
      />

      {/* Input Area */}
      <KeyboardAvoidingView
        behavior={Platform.OS === "ios" ? "padding" : undefined}
        keyboardVerticalOffset={Platform.OS === "ios" ? 90 : 0}
      >
        <View style={styles.inputContainer}>
          {/* Media Picker Button */}
          <TouchableOpacity style={styles.mediaButton} onPress={pickMedia}>
            <Ionicons name="image" size={24} color="#007AFF" />
          </TouchableOpacity>

          {/* Text Input */}
          <TextInput
            style={styles.input}
            value={newMessage}
            onChangeText={setNewMessage}
            placeholder="Message..."
            multiline
            maxLength={1000}
          />

          {/* Send Button */}
          <TouchableOpacity
            style={styles.sendButton}
            onPress={sendMessage}
            disabled={!newMessage?.trim() && !selectedMedia}
          >
            <Ionicons
              name="send"
              size={24}
              color={newMessage.trim() || selectedMedia ? "#007AFF" : "#A5A5A5"}
            />
          </TouchableOpacity>
        </View>
      </KeyboardAvoidingView>


      {/* Profile Drawer */}
      <Animated.View
        style={[
          styles.profileDrawer,
          {
            transform: [{ translateX: profileDrawerAnim }],
          },
        ]}
      >
        <View style={styles.profileContent}>
          <TouchableOpacity style={styles.closeProfile} onPress={toggleProfile}>
            <Ionicons name="close" size={24} color="#000" />
          </TouchableOpacity>

          <View style={styles.profileInfo}>
            <Image
              source={{
                uri:
                  recipient?.profilePicture ||
                  "https://via.placeholder.com/120",
              }}
              style={styles.profileAvatar}
            />
            <Text style={styles.profileName}>{recipient?.name}</Text>
            <Text style={styles.profileUsername}>@{recipient?.username}</Text>
            <Text style={styles.profileEmail}>{recipient?.email}</Text>
          </View>
        </View>
      </Animated.View>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fff",
  },
  loadingContainer: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },
  header: {
    flexDirection: "row",
    alignItems: "center",
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: "#E5E5E5",
  },
  headerProfile: {
    flex: 1,
    flexDirection: "row",
    alignItems: "center",
    marginLeft: 12,
  },
  headerAvatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
    marginRight: 12,
  },
  headerName: {
    fontSize: 17,
    fontWeight: "600",
  },
  messagesList: {
    padding: 16,
  },
  messageContainer: {
    flexDirection: "row",
    marginBottom: 16,
    maxWidth: "80%",
  },
  ownMessage: {
    alignSelf: "flex-end",
    flexDirection: "row-reverse",
  },
  otherMessage: {
    alignSelf: "flex-start",
  },
  messageAvatar: {
    width: 32,
    height: 32,
    borderRadius: 16,
    marginRight: 8,
  },
  messageBubble: {
    padding: 12,
    borderRadius: 20,
    maxWidth: "100%",
  },
  ownBubble: {
    backgroundColor: "#007AFF",
    marginLeft: 8,
    borderTopRightRadius: 4,
  },
  otherBubble: {
    backgroundColor: "#E5E5E5",
    marginRight: 8,
    borderTopLeftRadius: 4,
  },
  messageText: {
    fontSize: 16,
    marginBottom: 4,
  },
  ownMessageText: {
    color: "#FFF",
  },
  otherMessageText: {
    color: "#000",
  },
  timestamp: {
    fontSize: 11,
    color: "#8E8E93",
    alignSelf: "flex-end",
  },
  inputContainer: {
    flexDirection: "row",
    alignItems: "center",
    padding: 8,
    borderTopWidth: 1,
    borderTopColor: "#E5E5E5",
    backgroundColor: "#FFF",
  },
  input: {
    flex: 1,
    minHeight: 40,
    maxHeight: 100,
    backgroundColor: "#F1F1F1",
    borderRadius: 20,
    paddingHorizontal: 16,
    paddingVertical: 8,
    marginRight: 8,
    fontSize: 16,
  },
  sendButton: {
    width: 40,
    height: 40,
    justifyContent: "center",
    alignItems: "center",
  },
  profileDrawer: {
    position: "absolute",
    top: 0,
    right: 0,
    bottom: 0,
    width: PROFILE_DRAWER_WIDTH,
    backgroundColor: "#FFF",
    shadowColor: "#000",
    shadowOffset: {
      width: -2,
      height: 0,
    },
    shadowOpacity: 0.25,
    shadowRadius: 3.84,
    elevation: 5,
  },
  profileContent: {
    flex: 1,
    padding: 20,
  },
  closeProfile: {
    alignSelf: "flex-end",
    padding: 10,
  },
  profileInfo: {
    alignItems: "center",
    marginTop: 20,
  },
  profileAvatar: {
    width: 120,
    height: 120,
    borderRadius: 60,
    marginBottom: 16,
  },
  profileName: {
    fontSize: 24,
    fontWeight: "600",
    marginBottom: 8,
  },
  profileUsername: {
    fontSize: 18,
    color: "#666",
    marginBottom: 8,
  },
  profileEmail: {
    fontSize: 16,
    color: "#666",
  },

  imageMessage: {
    width: 200,
    height: 200,
    borderRadius: 10,
  },

  videoMessage: {
    width: 250,
    height: 250,
    borderRadius: 10,
  },

  mediaButton: {
    marginRight: 10,
    padding: 8,
  },
  
  warningBox: {
    marginTop: 5,
    backgroundColor: '#FFF3CD',
    borderColor: '#FFA000',
    borderWidth: 1,
    borderRadius: 8,
    padding: 8,
  },
  warningText: {
    color: '#856404',
    fontWeight: 'bold',
  },
  warningDetail: {
    color: '#856404',
    fontSize: 12,
    marginTop: 4,
  },
  
});

export default Conversation;