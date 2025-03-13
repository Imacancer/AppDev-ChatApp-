from pymongo import MongoClient
from bson.objectid import ObjectId
from datetime import datetime

class Message:
    def __init__(self, sender_id, recipient_id, message, is_media=False, _id=None, timestamp=None, viewed=False):
        self._id = _id or ObjectId()
        self.sender_id = sender_id
        self.recipient_id = recipient_id
        self.message = message
        self.is_media = is_media 
        self.timestamp = timestamp or datetime.utcnow()
        self.viewed = viewed

    def to_dict(self):
        return {
            '_id': self._id,
            'senderId': self.sender_id,
            'recipientId': self.recipient_id,
            'message': self.message,
            'isMedia': self.is_media, 
            'timestamp': self.timestamp,
            'viewed': self.viewed
        }
