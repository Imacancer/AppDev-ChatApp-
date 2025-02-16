import React, { useEffect } from "react";
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Image,
  Dimensions,
  StyleProp,
  ViewStyle,
} from "react-native";
import { Ionicons } from "@expo/vector-icons";
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  Easing,
} from "react-native-reanimated";
import {
  Gesture,
  GestureDetector,
  GestureHandlerRootView,
} from "react-native-gesture-handler";

const { width: SCREEN_WIDTH } = Dimensions.get("window");
const SIDEBAR_WIDTH = SCREEN_WIDTH * 0.8;

interface User {
  name: string;
  username: string;
  profilePicture?: string;
}

interface SlidingSidebarProps {
  isVisible: boolean;
  onClose: () => void;
  onLogout: () => void;
  currentUser: User | null;
  style?: StyleProp<ViewStyle>;
}

const SlidingSidebar: React.FC<SlidingSidebarProps> = ({
  isVisible,
  onClose,
  onLogout,
  currentUser,
  style,
}) => {
  const sidebarTranslateX = useSharedValue(-SIDEBAR_WIDTH);
  const overlayOpacity = useSharedValue(0);

  useEffect(() => {
    if (isVisible) {
      sidebarTranslateX.value = withTiming(0, {
        duration: 300,
        easing: Easing.out(Easing.cubic),
      });
      overlayOpacity.value = withTiming(0.5, {
        duration: 300,
        easing: Easing.out(Easing.cubic),
      });
    } else {
      sidebarTranslateX.value = withTiming(-SIDEBAR_WIDTH, {
        duration: 300,
        easing: Easing.out(Easing.cubic),
      });
      overlayOpacity.value = withTiming(0, {
        duration: 300,
        easing: Easing.out(Easing.cubic),
      });
    }
  }, [isVisible]);

  const animatedSidebarStyle = useAnimatedStyle(() => ({
    transform: [{ translateX: sidebarTranslateX.value }],
  }));

  const animatedOverlayStyle = useAnimatedStyle(() => ({
    opacity: overlayOpacity.value,
  }));

  const panGesture = Gesture.Pan()
    .onUpdate((event) => {
      if (event.translationX < 0) {
        sidebarTranslateX.value = Math.max(-SIDEBAR_WIDTH, event.translationX);
        overlayOpacity.value = Math.max(
          0,
          0.5 + (event.translationX / SIDEBAR_WIDTH) * 0.5
        );
      }
    })
    .onEnd((event) => {
      if (event.translationX < -SIDEBAR_WIDTH / 2) {
        sidebarTranslateX.value = withTiming(-SIDEBAR_WIDTH, {
          duration: 300,
          easing: Easing.out(Easing.cubic),
        });
        overlayOpacity.value = withTiming(0, {
          duration: 300,
          easing: Easing.out(Easing.cubic),
        });
        onClose();
      } else {
        sidebarTranslateX.value = withTiming(0, {
          duration: 300,
          easing: Easing.out(Easing.cubic),
        });
        overlayOpacity.value = withTiming(0.5, {
          duration: 300,
          easing: Easing.out(Easing.cubic),
        });
      }
    });

  const sidebarContent = (
    <Animated.View
      style={[
        styles.sidebar,
        animatedSidebarStyle,
        { width: SIDEBAR_WIDTH },
        style,
      ]}
    >
      <View style={styles.contentContainer}>
        {/* Wrap close button in View for better touch handling */}
        <View style={styles.closeButtonContainer}>
          <TouchableOpacity
            style={styles.closeButton}
            onPress={onClose}
            hitSlop={{ top: 10, right: 10, bottom: 10, left: 10 }}
          >
            <Ionicons name="close" size={28} color="#000" />
          </TouchableOpacity>
        </View>

        <View style={styles.profileSection}>
          <Image
            source={{
              uri:
                currentUser?.profilePicture ||
                "https://via.placeholder.com/150",
            }}
            style={styles.profileImage}
          />
          <Text style={styles.profileName}>{currentUser?.name}</Text>
          <Text style={styles.profileUsername}>@{currentUser?.username}</Text>
        </View>

        <View style={styles.sidebarActions}>
          <TouchableOpacity
            style={styles.sidebarActionButton}
            onPress={onLogout}
          >
            <Text style={styles.logoutButtonText}>Log Out</Text>
          </TouchableOpacity>

          <TouchableOpacity style={styles.sidebarActionButton}>
            <Text style={styles.sidebarActionButtonText}>Switch Account</Text>
          </TouchableOpacity>
        </View>
      </View>
    </Animated.View>
  );

  return (
    <View style={styles.container} pointerEvents="box-none">
      <GestureDetector gesture={panGesture}>
        <Animated.View
          style={[StyleSheet.absoluteFill, styles.gestureContainer]}
        >
          {sidebarContent}
        </Animated.View>
      </GestureDetector>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    ...StyleSheet.absoluteFillObject,
  },
  contentContainer: {
    flex: 1,
  },
  closeButtonContainer: {
    position: "absolute",
    top: 40,
    right: 20,
    zIndex: 1002,
    width: 40,
    height: 40,
    justifyContent: "center",
    alignItems: "center",
  },
  gestureContainer: {
    zIndex: 1000,
  },
  overlay: {
    backgroundColor: "black",
    zIndex: 1000,
  },
  sidebar: {
    position: "absolute",
    height: "100%",
    backgroundColor: "#FFFFFF",
    padding: 20,
    shadowColor: "#000",
    shadowOpacity: 0.1,
    shadowRadius: 10,
    shadowOffset: { width: 2, height: 0 },
    elevation: 5,
    zIndex: 1001,
  },
  closeButton: {
    position: "absolute",
    top: 40,
    right: 20,
    zIndex: 1002,
  },
  profileSection: {
    marginTop: 60,
    alignItems: "center",
  },
  profileImage: {
    width: 80,
    height: 80,
    borderRadius: 40,
    marginVertical: 16,
  },
  profileName: {
    fontSize: 18,
    fontWeight: "600",
    textAlign: "center",
  },
  profileUsername: {
    fontSize: 14,
    color: "#666",
    textAlign: "center",
    marginBottom: 24,
  },
  sidebarActions: {
    marginTop: 30,
  },
  sidebarActionButton: {
    paddingVertical: 15,
    borderBottomWidth: 1,
    borderBottomColor: "#E0E0E0",
  },
  sidebarActionButtonText: {
    fontSize: 16,
    color: "#007AFF",
    textAlign: "center",
  },
  logoutButtonText: {
    fontSize: 16,
    color: "#FF3B30",
    textAlign: "center",
  },
});

export default SlidingSidebar;
