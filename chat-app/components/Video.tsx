import React, { useEffect, useRef } from "react";
import { StyleSheet, Platform } from "react-native";
import { Video, ResizeMode, AVPlaybackStatus } from "expo-av";

interface BackgroundVideoProps {
  source: number; // For require() video sources
  isMuted?: boolean;
  isLooping?: boolean;
}

const BackgroundVideo: React.FC<BackgroundVideoProps> = ({
  source,
  isMuted = true,
  isLooping = true,
}) => {
  const videoRef = useRef<Video>(null);

  useEffect(() => {
    loadVideo();
  }, []);

  const loadVideo = async () => {
    try {
      if (videoRef.current) {
        // Reset the video player
        await videoRef.current.unloadAsync();

        // Load and play the video with specific settings for iOS
        await videoRef.current.loadAsync(source, {}, false);
        await videoRef.current.playAsync();

        // Ensure proper iOS background video settings
        if (Platform.OS === "ios") {
          await videoRef.current.setIsMutedAsync(isMuted);
          await videoRef.current.setIsLoopingAsync(isLooping);
          // Set position to 0 to ensure smooth looping
          await videoRef.current.setPositionAsync(0);
        }
      }
    } catch (error) {
      console.warn("Error loading video:", error);
    }
  };

  return (
    <Video
      ref={videoRef}
      source={source}
      style={styles.backgroundVideo}
      resizeMode={ResizeMode.COVER}
      shouldPlay={true}
      isLooping={isLooping}
      isMuted={isMuted}
      useNativeControls={false}
      posterSource={source} // Use the same source as poster to prevent flicker
    />
  );
};

const styles = StyleSheet.create({
  backgroundVideo: {
    position: "absolute",
    top: 0,
    left: 0,
    bottom: 0,
    right: 0,
    zIndex: 0,
  },
});

export default BackgroundVideo;
