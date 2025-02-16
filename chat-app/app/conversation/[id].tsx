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
  timestamp: string;
  viewed: boolean;
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
    const initializeWebRTC = async () => {
      if (currentUser?.userId && recipient?.userId && sharedSecret) {
        const service = new WebRTCService(currentUser.userId);
        service.setOnMessageCallback((message) => {
          console.warn("sharedSecret in callback:", sharedSecret);
          const decryptedMessage = {
            ...message,
            message: decryptMessage(message.message, sharedSecret),
          };
          setMessages((prev) => [...prev, decryptedMessage]);
        });
        await service.joinRoom(
          `chat_${currentUser.userId}_${recipient.userId}`
        );
        setWebRTCService(service);
      }
    };

    initializeWebRTC();
    return () => {
      if (webRTCService) {
        webRTCService.setOnMessageCallback(() => {});
      }
    };
  }, [currentUser?.userId, recipient?.userId, sharedSecret]);

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

      //const userData = JSON.parse(userDataStr);
      setCurrentUser(userDataStr);

      // Fetch recipient details
      const recipientResponse = await axios.get(
        `http://127.0.0.1:5001/api/get_user/${id}`,
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );
      console.warn("Recipient response:", recipientResponse);
      const recipientData = recipientResponse.data.user;

      setRecipient(recipientData);

      if (recipientData.publicKey) {
        const sharedSecret = await computeSharedSecret(recipientData.publicKey);
        console.warn("sharedSecret:", sharedSecret);
        setSharedSecret(sharedSecret);
        await fetchMessages(token, userDataStr.userId, sharedSecret);
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
    userId: string,
    sharedSecret: string | null
  ) => {
    try {
      const response = await axios.get(
        `http://127.0.0.1:5001/api/messages/conversation/${userId}/${id}`,
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );

      const decryptedMessages = response.data.map((msg: Message) => {
        // Make sure sharedSecret is available; otherwise, you might delay this process.
        if (!sharedSecret) {
          console.warn("Shared secret not available; cannot decrypt message.");
          return msg;
        }
        return {
          ...msg,
          message: decryptMessage(msg.message, sharedSecret),
        };
      });

      setMessages(decryptedMessages);
      markUnreadMessagesAsViewed(decryptedMessages, token);
    } catch (error) {
      console.error("Error fetching messages:", error);
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
            `http://127.0.0.1:5001/api/messages/view/${msg._id}`,
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
    if (!newMessage.trim() || !currentUser || !webRTCService || !sharedSecret)
      return;

    try {
      const messageObj: Message = {
        _id: Date.now().toString(), // Temporary ID until server confirms
        senderId: currentUser.userId,
        recipientId: id,
        message: newMessage.trim(),
        timestamp: new Date().toISOString(),
        viewed: false,
      };

      const encryptedMessage = encryptMessage(messageObj.message, sharedSecret);

      // Send via WebRTC
      await webRTCService.sendMessage(id, {
        ...messageObj,
        message: encryptedMessage,
      });

      // Update local state
      setMessages((prev) => [...prev, messageObj]);
      setNewMessage("");
      flatListRef.current?.scrollToEnd();
    } catch (error) {
      console.error("Error sending message:", error);
    }
  };

  const renderMessage = ({ item }: { item: Message }) => {
    const isOwnMessage = item.senderId === currentUser?.userId;

    return (
      <View
        style={[
          styles.messageContainer,
          isOwnMessage ? styles.ownMessage : styles.otherMessage,
        ]}
      >
        {!isOwnMessage && (
          <Image
            source={{
              uri:
                recipient?.profilePicture || "https://via.placeholder.com/40",
            }}
            style={styles.messageAvatar}
          />
        )}
        <View
          style={[
            styles.messageBubble,
            isOwnMessage ? styles.ownBubble : styles.otherBubble,
          ]}
        >
          <Text
            style={[
              styles.messageText,
              isOwnMessage ? styles.ownMessageText : styles.otherMessageText,
            ]}
          >
            {item.message}
          </Text>
          <Text
            style={[
              styles.timestamp,
              {
                color: isOwnMessage ? "white" : "gray", // Adjust timestamp color
              },
            ]}
          >
            {new Date(item.timestamp).toLocaleTimeString([], {
              hour: "2-digit",
              minute: "2-digit",
            })}
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
          <TextInput
            style={styles.input}
            value={newMessage}
            onChangeText={setNewMessage}
            placeholder="Message..."
            multiline
            maxLength={1000}
          />
          <TouchableOpacity
            style={styles.sendButton}
            onPress={sendMessage}
            disabled={!newMessage.trim()}
          >
            <Ionicons
              name="send"
              size={24}
              color={newMessage.trim() ? "#007AFF" : "#A5A5A5"}
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
});

export default Conversation;
