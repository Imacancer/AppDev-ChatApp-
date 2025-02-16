from dataclasses import dataclass, field
from datetime import datetime
from typing import List, Optional
from bson import ObjectId

@dataclass
class User:
    email: str
    username: str
    name: str
    _id: ObjectId = field(default_factory=ObjectId)
    profile_picture: Optional[str] = None
    status: str = 'offline'
    device_tokens: List[str] = None
    last_seen: datetime = None
    created_at: datetime = None
    updated_at: datetime = None
    password: str = None
    public_key: Optional[str] = None

    @property
    def userId(self) -> str:
        """
        Derive a numeric representation of the ObjectId.
        """
        return ''.join(filter(str.isdigit, str(self._id)))
    
    def to_dict(self):
        return {
            '_id': self._id,
            'userId': self.userId,
            'username': self.username,
            'email': self.email,
            'name': self.name,
            'profilePicture': self.profile_picture,
            'status': self.status,
            'deviceTokens': self.device_tokens or [],
            'lastSeen': self.last_seen or datetime.now(),
            'createdAt': self.created_at or datetime.now(),
            'updatedAt': self.updated_at or datetime.now(),
            'password': self.password,
            'publicKey': self.public_key
        }
    