import CryptoJS from "crypto-js";


export const generateECDHKeys = () => {
  // In a real-world scenario, use an ECDH library.
  const privateKey = CryptoJS.lib.WordArray.random(32).toString(CryptoJS.enc.Hex);
  const publicKey = CryptoJS.SHA256(privateKey).toString(CryptoJS.enc.Hex); // Simulated ECDH public key

  return { privateKey, publicKey };
};

export const encryptMessage = (message: string, secret: string) => {
  return CryptoJS.AES.encrypt(message, secret).toString();
};

export const decryptMessage = (encryptedMessage: string, secret: string) => {
  const bytes = CryptoJS.AES.decrypt(encryptedMessage, secret);
  return bytes.toString(CryptoJS.enc.Utf8);
};