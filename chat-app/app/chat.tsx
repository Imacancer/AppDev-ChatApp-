// Chat.tsx
import React, { useState, useEffect, useRef } from "react";
import {
  View,
  Text,
  FlatList,
  Image,
  StyleSheet,
  TouchableOpacity,
  SafeAreaView,
  Alert,
  ActivityIndicator,
  Animated,
  Dimensions,
  TextInput,
} from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { useRouter, useLocalSearchParams } from "expo-router";
import axios from "axios";
import * as SecureStore from "expo-secure-store";
import { GestureHandlerRootView } from "react-native-gesture-handler";
import { Platform } from "react-native";
import { WebRTCService } from "./websockets/socket";
import CryptoJS from "crypto-js";
import { decryptMessage } from "@/utils/encryption";

const isWeb = Platform.OS === "web";

const SCREEN_WIDTH = Dimensions.get("window").width;
const SIDEBAR_WIDTH = SCREEN_WIDTH * 0.8;

const getToken = async () => {
  if (Platform.OS === "web") {
    return sessionStorage.getItem("userToken");
  } else {
    return await SecureStore.getItemAsync("userToken");
  }
};

// Platform-specific user data retrieval
const getUserData = async () => {
  if (Platform.OS === "web") {
    const data = sessionStorage.getItem("userData");
    return data ? JSON.parse(data) : null;
  } else {
    const data = await SecureStore.getItemAsync("userData");
    return data ? JSON.parse(data) : null;
  }
};

// Platform-specific logout
const clearStorage = async () => {
  if (Platform.OS === "web") {
    sessionStorage.removeItem("userToken");
    sessionStorage.removeItem("userData");
  } else {
    await Promise.all([
      SecureStore.deleteItemAsync("userToken"),
      SecureStore.deleteItemAsync("userData"),
    ]);
  }
};

interface User {
  userId: string;
  name: string;
  username: string;
  profilePicture?: string;
  email: string;
}

interface ChatUser {
  id: string;
  name: string;
  avatar: string;
  lastMessage: string;
  lastMessageId: string;
  unreadCount: number;
  timestamp: string;
  viewed: boolean;
  lastMessageSenderName: string;
}

interface Message {
  _id: string;
  senderId: string;
  recipientId: string;
  message: string;
  timestamp: string;
  viewed: boolean;
}

const Chat: React.FC = () => {
  const [isSidebarVisible, setSidebarVisible] = useState(false);
  const [currentUser, setCurrentUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [chatUsers, setChatUsers] = useState<ChatUser[]>([]);
  const [selectedUserDetails, setSelectedUserDetails] = useState<User | null>(
    null
  );
  const [webRTCService, setWebRTCService] = useState<WebRTCService | null>(
    null
  );
  const [searchQuery, setSearchQuery] = useState("");
  const [searchResults, setSearchResults] = useState<User[]>([]);

  const router = useRouter();
  const { userId } = useLocalSearchParams<{ userId?: string }>();

  // Animated values
  const sidebarAnim = React.useRef(new Animated.Value(-SIDEBAR_WIDTH)).current;
  const overlayAnim = React.useRef(new Animated.Value(0)).current;

  const computeSharedSecret = async (recipientPublicKey: string) => {
    const privateKey = await SecureStore.getItemAsync("privateKey");
    if (!privateKey) {
      throw new Error("Private key not found");
    }
    // This is a placeholder. In production, use a proper ECDH library.
    const sharedSecret = CryptoJS.SHA256(
      privateKey + recipientPublicKey
    ).toString(CryptoJS.enc.Hex);
    return sharedSecret;
  };

  const animateSidebar = (show: boolean) => {
    Animated.parallel([
      Animated.timing(sidebarAnim, {
        toValue: show ? 0 : -SIDEBAR_WIDTH,
        duration: 300,
        useNativeDriver: true,
      }),
      Animated.timing(overlayAnim, {
        toValue: show ? 0.5 : 0,
        duration: 300,
        useNativeDriver: true,
      }),
    ]).start(() => {
      if (!show) setSidebarVisible(false);
    });
  };

  const toggleSidebar = () => {
    if (!isSidebarVisible) {
      setSidebarVisible(true);
    }
    animateSidebar(!isSidebarVisible);
  };

  const handleSearch = async (query: string) => {
    setSearchQuery(query);
    if (query.length > 0) {
      // Changed from 2 to 0 to search on every keystroke
      try {
        const token = await getToken();
        const response = await axios.get(
          `http://127.0.0.1:5001/api/search_users?query=${query}`,
          {
            headers: {
              Authorization: `Bearer ${token}`,
            },
          }
        );

        // Check if the response contains a users array
        if (response.data.users) {
          setSearchResults(response.data.users);
        } else {
          // If no users are found, set an empty array
          setSearchResults([]);
        }
      } catch (error) {
        console.error("Error searching users:", error);
        // Clear search results on error
        setSearchResults([]);
      }
    } else {
      // Clear search results if the query is empty
      setSearchResults([]);
    }
  };

  const handleUserSelect = (user: User) => {
    setSearchQuery("");
    setSearchResults([]);
    // Navigate to the conversation screen or open a new chat
    router.push(`/conversation/${user.userId}`);
  };

  const markMessageAsViewed = async (messageId: string) => {
    try {
      const token = await getToken();
      if (!token) {
        console.error("No auth token found");
        return;
      }

      console.log("Marking message as viewed:", messageId);

      const response = await axios.put(
        `http://127.0.0.1:5001/api/messages/view/${messageId}`,
        {},
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        }
      );

      console.log("API Response:", response.data);

      if (response.status === 200) {
        // Update local state to reflect the change
        setChatUsers((prevUsers) =>
          prevUsers.map((user) => {
            if (user.lastMessageId === messageId) {
              return {
                ...user,
                viewed: true,
                unreadCount: Math.max(0, user.unreadCount - 1),
              };
            }
            return user;
          })
        );
      }
    } catch (error) {
      console.error("Error marking message as viewed:", error);
      if (axios.isAxiosError(error)) {
        console.error("Response data:", error.response?.data);
        console.error("Status code:", error.response?.status);
      }
    }
  };

  const handleChatPress = async (chatUser: ChatUser) => {
    console.log("Chat pressed:", {
      messageId: chatUser.lastMessageId,
      viewed: chatUser.viewed,
      userId: currentUser?.userId,
      chatUserId: chatUser.id,
    });

    if (
      currentUser &&
      chatUser.lastMessageId &&
      !chatUser.viewed &&
      chatUser.id !== currentUser.userId
    ) {
      console.log("Attempting to mark message as viewed");
      await markMessageAsViewed(chatUser.lastMessageId);
    }

    // Navigate to the conversation screen
    router.push(`/conversation/${chatUser.id}`);

    if (webRTCService) {
      webRTCService.joinRoom(chatUser.id);
    }
  };

  const handleLogout = async () => {
    try {
      await clearStorage();
      router.replace("/");
    } catch (error) {
      console.error("Logout error:", error);
      Alert.alert("Error", "Failed to logout");
    }
  };

  useEffect(() => {
    const initializeData = async () => {
      try {
        const storedToken = await getToken();
        if (!storedToken) {
          router.replace("/");
          return;
        }

        const userJson = await getUserData();
        if (userJson) {
          const webRTCServiceInstance = new WebRTCService(userJson.userId);
          setWebRTCService(webRTCServiceInstance);
          setCurrentUser(userJson);
          await fetchUserMessages(storedToken, userJson.userId);

          webRTCServiceInstance.setOnProfileUpdateCallback((profile) => {
            setCurrentUser((prevUser) => {
              if (prevUser && prevUser.userId === profile.userId) {
                return {
                  ...prevUser,
                  profilePicture: profile.profilePicture,
                };
              }
              return prevUser;
            });
          });

          webRTCServiceInstance.setOnMessageCallback((message) => {
            // Update chat state with the new message
            setChatUsers((prevUsers) =>
              prevUsers.map((user) => {
                if (user.id === message.senderId) {
                  return {
                    ...user,
                    lastMessage: message.content,
                    lastMessageId: message.id,
                    timestamp: new Date().toLocaleTimeString(),
                    unreadCount: user.unreadCount + 1,
                    viewed: false,
                    lastMessageSenderName: user.name,
                  };
                }
                return user;
              })
            );
          });
        }

        if (userId) {
          await fetchUserDetails(storedToken, userId);
        }
      } catch (error) {
        console.error("Initialization error:", error);
        Alert.alert("Error", "Failed to initialize");
      } finally {
        setLoading(false);
      }
    };

    initializeData();

    return () => {
      console.log("Disconnecting WebRTC service...");
      webRTCService?.disconnect();
    };
  }, [userId, chatUsers]);

  const fetchUserMessages = async (
    authToken: string,
    currentUserId: string
  ) => {
    try {
      // First get all users the current user has interacted with
      const messagesResponse = await axios.get(
        `http://127.0.0.1:5001/api/messages/getMessages/${currentUserId}`,
        {
          headers: {
            Authorization: `Bearer ${authToken}`,
          },
        }
      );

      // Get unique user IDs from both sent and received messages
      const uniqueUserIds = new Set<string>();
      messagesResponse.data.forEach((message: Message) => {
        if (message.senderId === currentUserId) {
          uniqueUserIds.add(message.recipientId);
        } else {
          uniqueUserIds.add(message.senderId);
        }
      });

      const chatUsersData: ChatUser[] = await Promise.all(
        Array.from(uniqueUserIds).map(async (partnerId) => {
          // Get the full conversation between current user and partner
          const conversationResponse = await axios.get(
            `http://127.0.0.1:5001/api/messages/conversation/${currentUserId}/${partnerId}`,
            {
              headers: {
                Authorization: `Bearer ${authToken}`,
              },
            }
          );

          // Get partner user details
          const userResponse = await axios.get(
            `http://127.0.0.1:5001/api/get_user/${partnerId}`,
            {
              headers: {
                Authorization: `Bearer ${authToken}`,
              },
            }
          );

          const partner = userResponse.data.user;

          const sharedSecret = await computeSharedSecret(partner.publicKey);

          const decryptedMessages = conversationResponse.data.map(
            (msg: Message) => ({
              ...msg,
              message: decryptMessage(msg.message, sharedSecret),
            })
          );
          console.log(
            `Decrypted messages for partner ${partnerId}:`,
            decryptedMessages
          );

          //const messages = conversationResponse.data;

          // Sort messages by timestamp to get the latest message
          const sortedMessages = decryptedMessages.sort(
            (a: Message, b: Message) =>
              new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()
          );

          const latestMessage = sortedMessages[0];

          // Set the last message sender name
          const lastMessageSenderName =
            latestMessage.senderId === currentUserId ? "You" : partner.name;

          // Count unread messages where current user is the recipient
          const unreadCount = decryptedMessages.filter(
            (msg: Message) => msg.senderId === partnerId && !msg.viewed
          ).length;

          return {
            id: partner.userId,
            name: partner.name,
            avatar: partner.profilePicture || "../assets/images/wonhee.png",
            lastMessage: latestMessage.message,
            lastMessageId: latestMessage._id,
            unreadCount,
            timestamp: new Date(latestMessage.timestamp).toLocaleTimeString(),
            viewed:
              latestMessage.senderId === currentUserId || latestMessage.viewed,
            lastMessageSenderName,
          };
        })
      );

      setChatUsers(chatUsersData);
    } catch (error) {
      console.error("Error fetching user messages:", error);
      Alert.alert("Error", "Could not fetch messages");
    }
  };

  const fetchUserDetails = async (token: string, userId: string) => {
    try {
      const response = await axios.get(
        `http://127.0.0.1:5001/api/get_user/${userId}`,
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );
      setSelectedUserDetails(response.data.user);
    } catch (error) {
      console.error("Error fetching user details:", error);
      Alert.alert("Error", "Failed to fetch user details");
    }
  };

  const renderSearchResult = ({ item }: { item: User }) => (
    <TouchableOpacity
      style={styles.searchResultItem}
      onPress={() => handleUserSelect(item)}
    >
      <Image
        source={{
          uri: item.profilePicture || "https://via.placeholder.com/150",
        }}
        style={styles.searchResultAvatar}
      />
      <Text style={styles.searchResultName}>{item.name}</Text>
      <Text style={styles.searchResultUsername}>@{item.username}</Text>
    </TouchableOpacity>
  );

  const renderChatItem = ({ item }: { item: ChatUser }) => (
    <TouchableOpacity
      style={styles.chatItem}
      onPress={() => handleChatPress(item)}
    >
      <View style={styles.chatContainer}>
        <Image
          source={
            item.avatar
              ? { uri: item.avatar }
              : require("../assets/images/wonhee.png")
          }
          style={styles.avatar}
        />
        <View style={styles.chatInfo}>
          <Text style={styles.chatName}>{item.name}</Text>
          <Text
            style={[
              styles.lastMessage,
              !item.viewed &&
                item.id !== currentUser?.userId &&
                styles.unreadMessage,
            ]}
            numberOfLines={1}
          >
            <Text style={{ fontWeight: "bold" }}>
              {item.lastMessageSenderName}:{" "}
            </Text>
            {item.lastMessage}
          </Text>
        </View>
        <View style={styles.rightSection}>
          <Text style={styles.timestamp}>{item.timestamp}</Text>
          {item.unreadCount > 0 && (
            <View style={styles.unreadBadge}>
              <Text style={styles.unreadText}>{item.unreadCount}</Text>
            </View>
          )}
        </View>
      </View>
    </TouchableOpacity>
  );

  if (loading) {
    return (
      <SafeAreaView style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#007AFF" />
      </SafeAreaView>
    );
  }

  return (
    <GestureHandlerRootView style={styles.container}>
      <SafeAreaView style={styles.safeArea}>
        {/* Header */}
        <View style={styles.header}>
          <TouchableOpacity onPress={toggleSidebar}>
            <Image
              source={{
                uri:
                  currentUser?.profilePicture ||
                  "https://via.placeholder.com/150",
              }}
              style={styles.headerAvatar}
            />
          </TouchableOpacity>
          <Text style={styles.headerTitle}>Chats</Text>
          <TouchableOpacity>
            <Ionicons name="create-outline" size={24} color="#007AFF" />
          </TouchableOpacity>
        </View>

        <View style={styles.searchContainer}>
          <TextInput
            style={styles.searchInput}
            placeholder="Search users..."
            value={searchQuery}
            onChangeText={handleSearch}
          />
        </View>

        {searchResults.length > 0 ? (
          <FlatList
            data={searchResults}
            renderItem={renderSearchResult}
            keyExtractor={(item) => item.userId}
            style={styles.searchResultsList}
          />
        ) : (
          searchQuery.length > 0 && (
            <Text style={styles.noResultsText}>No users found.</Text>
          )
        )}

        {/* Chat List */}
        <FlatList
          data={chatUsers}
          renderItem={renderChatItem}
          keyExtractor={(item) => item.id}
          contentContainerStyle={styles.listContainer}
          ListEmptyComponent={
            <View style={styles.emptyContainer}>
              <Text style={styles.emptyText}>No messages yet</Text>
            </View>
          }
        />
      </SafeAreaView>

      {/* Overlay */}
      {isSidebarVisible && (
        <Animated.View style={[styles.overlay, { opacity: overlayAnim }]}>
          <TouchableOpacity
            style={styles.overlayTouch}
            activeOpacity={1}
            onPress={() => animateSidebar(false)}
          />
        </Animated.View>
      )}

      {/* Sidebar */}
      <Animated.View
        style={[
          styles.sidebar,
          {
            transform: [{ translateX: sidebarAnim }],
          },
        ]}
      >
        <SafeAreaView style={styles.sidebarSafeArea}>
          <View style={styles.sidebarContent}>
            <TouchableOpacity
              style={styles.closeButton}
              onPress={() => animateSidebar(false)}
            >
              <Ionicons name="close" size={24} color="#000" />
            </TouchableOpacity>

            <View style={styles.userInfo}>
              <Image
                source={{
                  uri:
                    currentUser?.profilePicture ||
                    "https://via.placeholder.com/150",
                }}
                style={styles.sidebarAvatar}
              />
              <Text style={styles.userName}>{currentUser?.name}</Text>
              <Text style={styles.userHandle}>@{currentUser?.username}</Text>
            </View>

            <TouchableOpacity
              style={styles.logoutButton}
              onPress={handleLogout}
            >
              <Text style={styles.logoutText}>Log Out</Text>
            </TouchableOpacity>
          </View>
        </SafeAreaView>
      </Animated.View>
    </GestureHandlerRootView>
  );
};

const styles = StyleSheet.create({
  noResultsText: {
    fontSize: 16,
    color: "#666",
    textAlign: "center",
  },
  container: {
    flex: 1,
    backgroundColor: "#fff",
  },
  safeArea: {
    flex: 1,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },
  header: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: "#E5E5E5",
  },
  headerAvatar: {
    width: 32,
    height: 32,
    borderRadius: 16,
  },
  headerTitle: {
    fontSize: 17,
    fontWeight: "600",
  },
  searchContainer: {
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: "#E5E5E5",
  },
  searchInput: {
    height: 40,
    borderColor: "#E5E5E5",
    borderWidth: 1,
    borderRadius: 8,
    paddingHorizontal: 10,
  },
  searchResultsList: {
    maxHeight: 200,
    borderBottomWidth: 1,
    borderBottomColor: "#E5E5E5",
  },
  searchResultItem: {
    flexDirection: "row",
    alignItems: "center",
    padding: 10,
    borderBottomWidth: 1,
    borderBottomColor: "#E5E5E5",
  },
  searchResultAvatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
    marginRight: 10,
  },
  searchResultName: {
    fontSize: 16,
    fontWeight: "500",
  },
  searchResultUsername: {
    fontSize: 14,
    color: "#666",
  },
  listContainer: {
    flexGrow: 1,
  },
  chatItem: {
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: "#E5E5E5",
  },
  chatContainer: {
    flexDirection: "row",
    alignItems: "center",
  },
  avatar: {
    width: 48,
    height: 48,
    borderRadius: 24,
    marginRight: 12,
  },
  chatInfo: {
    flex: 1,
  },
  chatName: {
    fontSize: 16,
    fontWeight: "500",
    marginBottom: 4,
  },
  lastMessage: {
    fontSize: 14,
    color: "#666",
  },
  rightSection: {
    alignItems: "flex-end",
  },
  timestamp: {
    fontSize: 12,
    color: "#999",
    marginBottom: 4,
  },
  unreadBadge: {
    backgroundColor: "#007AFF",
    borderRadius: 10,
    minWidth: 20,
    height: 20,
    justifyContent: "center",
    alignItems: "center",
    paddingHorizontal: 6,
  },
  unreadCount: {
    color: "#fff",
    fontSize: 12,
    fontWeight: "500",
  },
  overlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "#000",
  },
  overlayTouch: {
    flex: 1,
  },
  sidebar: {
    position: "absolute",
    top: 0,
    left: 0,
    bottom: 0,
    width: SIDEBAR_WIDTH,
    height: "100%",
    backgroundColor: "#fff",
    shadowColor: "#000",
    shadowOffset: {
      width: 2,
      height: 0,
    },
    shadowOpacity: 0.25,
    shadowRadius: 3.84,
    elevation: 5,
  },
  sidebarSafeArea: {
    flex: 1,
  },
  sidebarContent: {
    flex: 1,
    padding: 20,
  },
  closeButton: {
    alignSelf: "flex-end",
    padding: 10,
  },
  userInfo: {
    alignItems: "center",
    marginTop: 20,
  },
  sidebarAvatar: {
    width: 80,
    height: 80,
    borderRadius: 40,
    marginBottom: 16,
  },
  userName: {
    fontSize: 20,
    fontWeight: "600",
    marginBottom: 4,
  },
  userHandle: {
    fontSize: 16,
    color: "#666",
  },
  logoutButton: {
    marginTop: "auto",
    paddingVertical: 12,
    backgroundColor: "#FF3B30",
    borderRadius: 8,
    alignItems: "center",
  },
  logoutText: {
    color: "#fff",
    fontSize: 16,
    fontWeight: "600",
  },
  emptyContainer: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    paddingTop: 40,
  },
  emptyText: {
    fontSize: 16,
    color: "#666",
  },
  unreadMessage: {
    fontWeight: "bold",
    color: "#000",
  },
  unreadText: {
    color: "white",
    fontSize: 10,
    fontWeight: "bold",
  },
});

export default Chat;
