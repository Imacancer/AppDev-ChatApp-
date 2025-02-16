import os
import base64
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.backends import default_backend

# Use the same key as frontend
ENCRYPTION_KEY = os.getenv('ENCRYPTION_KEY', 'SYNB9LqvtYUcoUWeQ0xIFkghaHIkea36')

def derive_key(key: str) -> bytes:
    """Derive a Fernet-compatible key from the input key."""
    if len(key) < 32:
        key = key.ljust(32, '0')  # Pad key if too short
    elif len(key) > 32:
        key = key[:32]  # Truncate if too long
        
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=32,
        salt=b'fixed_salt',  # Using a fixed salt for consistency
        iterations=1,
        backend=default_backend()
    )
    derived = kdf.derive(key.encode())
    return base64.urlsafe_b64encode(derived)

# Initialize Fernet with derived key
cipher_suite = Fernet(derive_key(ENCRYPTION_KEY))

def encrypt_message(message: str) -> str:
    """Encrypt a message."""
    try:
        return cipher_suite.encrypt(message.encode()).decode()
    except Exception as e:
        print(f"Encryption error: {e}")
        raise Exception("Failed to encrypt message")

def decrypt_message(encrypted_message: str) -> str:
    """Decrypt a message."""
    try:
        return cipher_suite.decrypt(encrypted_message.encode()).decode()
    except Exception as e:
        print(f"Decryption error: {e}")
        raise Exception("Failed to decrypt message")