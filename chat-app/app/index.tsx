import React, { useState, useRef } from "react";
import {
  SafeAreaView,
  View,
  Text,
  TextInput,
  StyleSheet,
  TouchableOpacity,
  useColorScheme,
  Animated,
  Alert,
  Platform,
  ImageBackground,
  Image,
  useWindowDimensions,
  KeyboardAvoidingView,
} from "react-native";
import { ResizeMode, Video, AVPlaybackStatus } from "expo-av";
import { useRouter } from "expo-router";
import * as SecureStore from "expo-secure-store";
import * as ImagePicker from "expo-image-picker";
import * as Device from "expo-device";
import * as Notifications from "expo-notifications";
import {
  GestureHandlerRootView,
  ScrollView,
} from "react-native-gesture-handler";
import { generateECDHKeys } from "@/utils/encryption";

const getDeviceToken = async (): Promise<string | null> => {
  if (!Device.isDevice) {
    console.log("Must use physical device for Push Notifications");
    return null;
  }

  try {
    const { status: existingStatus } =
      await Notifications.getPermissionsAsync();
    let finalStatus = existingStatus;

    if (existingStatus !== "granted") {
      const { status } = await Notifications.requestPermissionsAsync();
      finalStatus = status;
    }

    if (finalStatus !== "granted") {
      console.log("Failed to get push token for push notification!");
      return null;
    }

    const token = (await Notifications.getExpoPushTokenAsync()).data;
    return token;
  } catch (error) {
    console.error("Error getting device token:", error);
    return null;
  }
};

// API helper function
const loginUser = async (email: string, password: string) => {
  try {
    const response = await fetch("http://127.0.0.1:5001/api/log_users", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ email, password }),
    });

    const data = await response.json();
    if (response.ok) {
      // Store the JWT token securely
      await SecureStore.setItemAsync("userToken", data.accessToken);

      return { success: true, data };
    } else {
      return { success: false, message: data.error };
    }
  } catch (error) {
    console.error("Error logging in:", error);
    return { success: false, message: "Network error" };
  }
};

const signUpUser = async (userData: {
  email: string;
  password: string;
  name: string;
  username: string;
  profilePicture?: string;
  publicKey?: string;
}) => {
  try {
    let profile_picture_base64 = undefined;

    const { privateKey, publicKey } = generateECDHKeys();

    if (userData.profilePicture) {
      profile_picture_base64 = await convertImageToBase64(
        userData.profilePicture
      );
    }

    const deviceToken = await getDeviceToken();
    const currentDate = new Date().toISOString();

    await SecureStore.setItemAsync("privateKey", privateKey);

    const requestBody = {
      email: userData.email,
      password: userData.password,
      name: userData.name,
      username: userData.username,
      profile_picture: profile_picture_base64,
      status: "active",
      device_tokens: deviceToken ? [deviceToken] : [],
      last_seen: currentDate,
      created_at: currentDate,
      updated_at: currentDate,
      public_key: publicKey,
    };

    const response = await fetch("http://127.0.0.1:5001/api/add_user", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(requestBody),
    });

    const data = await response.json();

    if (response.ok) {
      await SecureStore.setItemAsync("userToken", data.accessToken);
      const getPrivateKey = await SecureStore.getItemAsync("privateKey");
      console.log("privateKey", getPrivateKey);
      return {
        success: true,
        data: {
          user: {
            userId: data.userId,
            ...requestBody,
            profilePicture: data.profile_picture_url, // Use the URL returned from server
          },
          accessToken: data.accessToken,
        },
      };
    } else {
      return { success: false, message: data.error };
    }
  } catch (error) {
    console.error("Error signing up:", error);
    return { success: false, message: "Network error" };
  }
};

const getImageMimeType = async (uri: string): Promise<string> => {
  try {
    const response = await fetch(uri, { method: "HEAD" });
    return response.headers.get("Content-Type") || "image/jpeg";
  } catch (error) {
    console.error("Error getting mime type:", error);
    return "image/jpeg"; // fallback to jpeg
  }
};

const convertImageToBase64 = async (uri: string): Promise<string> => {
  try {
    const response = await fetch(uri);
    const blob = await response.blob();
    const mimeType = await getImageMimeType(uri);
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onloadend = () => {
        if (typeof reader.result === "string") {
          // Remove the data:image/jpeg;base64, prefix
          const base64Data = `data:${mimeType};base64,${
            reader.result.split(",")[1]
          }`;
          resolve(base64Data);
        } else {
          reject(new Error("Failed to convert image to base64"));
        }
      };
      reader.onerror = reject;
      reader.readAsDataURL(blob);
    });
  } catch (error) {
    console.error("Error converting image to base64:", error);
    throw error;
  }
};

export default function LoginScreen() {
  const { width } = useWindowDimensions();
  const colorScheme = useColorScheme();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [name, setName] = useState("");
  const [profilePicture, setProfilePicture] = useState<string | undefined>(
    undefined
  );
  const [loading, setLoading] = useState(false);
  const isDarkMode = colorScheme === "dark";
  const router = useRouter();
  const [isLogin, setIsLogin] = useState(true);
  const fadeAnim = useRef(new Animated.Value(1)).current;
  const containerWidth = Math.min(width * 0.9, 450);
  const formWidth = containerWidth - 40;

  const storage = {
    async setItem(key: string, value: string) {
      try {
        if (Platform.OS === "web") {
          sessionStorage.setItem(key, value);
        } else {
          await SecureStore.setItemAsync(key, value);
        }
      } catch (error) {
        console.error("Error storing data:", error);
        throw error;
      }
    },

    async getItem(key: string) {
      try {
        if (Platform.OS === "web") {
          return sessionStorage.getItem(key);
        }
        return await SecureStore.getItemAsync(key);
      } catch (error) {
        console.error("Error retrieving data:", error);
        throw error;
      }
    },

    async removeItem(key: string) {
      try {
        if (Platform.OS === "web") {
          sessionStorage.removeItem(key);
        } else {
          await SecureStore.deleteItemAsync(key);
        }
      } catch (error) {
        console.error("Error removing data:", error);
        throw error;
      }
    },
  };

  const loginUser = async (email: string, password: string) => {
    try {
      const response = await fetch("http://127.0.0.1:5001/api/log_users", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ email, password }),
      });

      const data = await response.json();
      if (response.ok) {
        // Store the JWT token using the platform-specific storage
        await storage.setItem("userToken", data.accessToken);
        return { success: true, data };
      } else {
        return { success: false, message: data.error };
      }
    } catch (error) {
      console.error("Error logging in:", error);
      return { success: false, message: "Network error" };
    }
  };

  const handleLogin = async () => {
    if (!email || !password) {
      Alert.alert("Error", "Please enter both email and password.");
      return;
    }

    setLoading(true);

    try {
      const { success, data, message } = await loginUser(email, password);

      if (success) {
        // Store user data using the platform-specific storage
        const userData = {
          userId: data.user.userId,
          name: data.user.name,
          username: data.user.username,
          email: data.user.email,
          profilePicture: data.user.profilePicture,
        };

        await storage.setItem("userData", JSON.stringify(userData));
        router.push("/chat");
      } else {
        Alert.alert("Login Failed", message);
      }
    } catch (error) {
      console.error("Error during login:", error);
      Alert.alert("Error", "An unexpected error occurred during login");
    } finally {
      setLoading(false);
    }
  };

  const handleSignUp = async () => {
    if (!email || !password || !name) {
      Alert.alert("Error", "Please fill in all fields.");
      return;
    }

    setLoading(true);

    try {
      const userData = {
        email,
        password,
        name,
        profilePicture,
        username: email.split("@")[0],
      };

      const { success, data, message } = await signUpUser(userData);

      if (success) {
        const userData = {
          userId: data?.user.userId,
          name: data?.user.name,
          username: data?.user.username,
          email: data?.user.email,
          profilePicture: data?.user.profilePicture,
        };

        await SecureStore.setItemAsync("userData", JSON.stringify(userData));
        router.push("/chat");
      } else {
        Alert.alert("Sign Up Failed", message);
      }
    } catch (error) {
      console.error("Error during sign up:", error);
      Alert.alert("Error", "An unexpected error occurred during sign up");
    } finally {
      setLoading(false);
    }
  };

  const toggleForm = () => {
    // Fade out
    Animated.timing(fadeAnim, {
      toValue: 0,
      duration: 200,
      useNativeDriver: true,
    }).start(() => {
      setIsLogin(!isLogin);
      // Reset form fields
      setEmail("");
      setPassword("");
      setName("");
      // Fade in
      Animated.timing(fadeAnim, {
        toValue: 1,
        duration: 200,
        useNativeDriver: true,
      }).start();
    });
  };

  const pickImage = async () => {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      allowsEditing: true,
      aspect: [1, 1],
      quality: 1,
    });

    if (!result.canceled) {
      setProfilePicture(result.assets[0].uri);
    }
  };

  const createFocusAnimation = (animValue: any) => ({
    transform: [
      {
        scale: animValue.interpolate({
          inputRange: [0, 1],
          outputRange: [1, 1.02],
        }),
      },
    ],
    borderBottomColor: animValue.interpolate({
      inputRange: [0, 1],
      outputRange: ["rgba(255,255,255,0.3)", "#BB86FC"],
    }),
    shadowOpacity: animValue.interpolate({
      inputRange: [0, 1],
      outputRange: [0, 0.2],
    }),
  });

  const handleFocus = (animValue: any) => {
    Animated.timing(animValue, {
      toValue: 1,
      duration: 200,
      useNativeDriver: false,
    }).start();
  };

  const handleBlur = (animValue: any) => {
    Animated.timing(animValue, {
      toValue: 0,
      duration: 200,
      useNativeDriver: false,
    }).start();
  };

  return (
    <GestureHandlerRootView style={styles.flex}>
      <KeyboardAvoidingView
        behavior={Platform.OS === "ios" ? "padding" : "height"}
        style={[styles.flex, styles.container]}
      >
        <ScrollView
          contentContainerStyle={styles.scrollContent}
          style={styles.flex}
        >
          <View style={styles.contentContainer}>
            {/* Logo and Title Section */}
            <View style={styles.headerContainer}>
              <View style={styles.logoContainer}>
                <Text style={styles.logoText}>📱</Text>
              </View>
              <Text style={styles.title}>Chateur</Text>
              <Text style={styles.subtitle}>
                Send your feelings safely to loved ones
              </Text>
            </View>

            {/* Main Card */}
            <View style={[styles.card, { width: containerWidth }]}>
              {/* Toggle Buttons */}
              <View style={styles.toggleContainer}>
                <TouchableOpacity
                  onPress={() => !isLogin && toggleForm()}
                  style={[styles.toggleButton, isLogin && styles.activeToggle]}
                >
                  <Text
                    style={[
                      styles.toggleText,
                      isLogin && styles.activeToggleText,
                    ]}
                  >
                    Login
                  </Text>
                </TouchableOpacity>
                <TouchableOpacity
                  onPress={() => isLogin && toggleForm()}
                  style={[styles.toggleButton, !isLogin && styles.activeToggle]}
                >
                  <Text
                    style={[
                      styles.toggleText,
                      !isLogin && styles.activeToggleText,
                    ]}
                  >
                    Sign Up
                  </Text>
                </TouchableOpacity>
              </View>

              {/* Form Container */}
              <Animated.View
                style={[styles.formContainer, { opacity: fadeAnim }]}
              >
                {!isLogin && (
                  <>
                    <TextInput
                      style={styles.input}
                      placeholder="Name"
                      value={name}
                      onChangeText={setName}
                      placeholderTextColor="#9CA3AF"
                    />
                    <TouchableOpacity
                      style={styles.imagePickerButton}
                      onPress={pickImage}
                    >
                      <Text style={styles.imagePickerText}>
                        {profilePicture
                          ? "Change Profile Picture"
                          : "Upload Profile Picture"}
                      </Text>
                    </TouchableOpacity>
                  </>
                )}
                <TextInput
                  style={styles.input}
                  placeholder="Email"
                  value={email}
                  onChangeText={setEmail}
                  keyboardType="email-address"
                  autoCapitalize="none"
                  placeholderTextColor="#9CA3AF"
                />
                <TextInput
                  style={styles.input}
                  placeholder="Password"
                  value={password}
                  onChangeText={setPassword}
                  secureTextEntry
                  placeholderTextColor="#9CA3AF"
                />
                <TouchableOpacity
                  style={styles.button}
                  onPress={isLogin ? handleLogin : handleSignUp}
                >
                  <Text style={styles.buttonText}>
                    {loading
                      ? isLogin
                        ? "Logging in..."
                        : "Signing up..."
                      : isLogin
                      ? "Login"
                      : "Sign Up"}
                  </Text>
                </TouchableOpacity>
              </Animated.View>
            </View>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </GestureHandlerRootView>
  );
}

const screenWidth = 350;

const styles = StyleSheet.create({
  flex: {
    flex: 1,
  },
  container: {
    backgroundColor: "#FFFFFF",
  },
  scrollContent: {
    flexGrow: 1,
  },
  contentContainer: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    padding: 24,
  },
  headerContainer: {
    alignItems: "center",
    marginBottom: 32,
  },
  logoContainer: {
    width: 80,
    height: 80,
    marginBottom: 16,
    alignItems: "center",
    justifyContent: "center",
    borderRadius: 40,
    backgroundColor: "#F3E8FF",
  },
  logoText: {
    fontSize: 40,
  },
  title: {
    fontSize: 28,
    fontWeight: "bold",
    color: "#7C3AED",
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 14,
    color: "#6B7280",
    textAlign: "center",
    maxWidth: 250,
  },
  card: {
    backgroundColor: "#FFFFFF",
    borderRadius: 24,
    padding: 24,
    shadowColor: "#000",
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 4,
  },
  toggleContainer: {
    flexDirection: "row",
    marginBottom: 32,
  },
  toggleButton: {
    flex: 1,
    paddingVertical: 12,
    borderBottomWidth: 2,
    borderBottomColor: "transparent",
  },
  activeToggle: {
    borderBottomColor: "#7C3AED",
  },
  toggleText: {
    textAlign: "center",
    color: "#9CA3AF",
    fontSize: 16,
  },
  activeToggleText: {
    color: "#7C3AED",
    fontWeight: "bold",
  },
  formContainer: {
    width: "100%",
  },
  input: {
    backgroundColor: "#F9FAFB",
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderRadius: 12,
    marginBottom: 16,
    fontSize: 16,
    color: "#1F2937",
  },
  imagePickerButton: {
    backgroundColor: "#F3E8FF",
    paddingVertical: 12,
    borderRadius: 12,
    marginBottom: 16,
  },
  imagePickerText: {
    color: "#7C3AED",
    textAlign: "center",
    fontSize: 16,
    fontWeight: "500",
  },
  button: {
    backgroundColor: "#7C3AED",
    paddingVertical: 16,
    borderRadius: 12,
    marginTop: 8,
  },
  buttonText: {
    color: "#FFFFFF",
    textAlign: "center",
    fontSize: 16,
    fontWeight: "bold",
  },
});
