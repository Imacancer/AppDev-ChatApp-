from pymongo import MongoClient
from bson.objectid import ObjectId
from datetime import datetime

class Message:
    def __init__(
        self, 
        sender_id: str, 
        recipient_id: str, 
        message: str, 
        _id: ObjectId = None, 
        timestamp: datetime = None,
        viewed: bool = False,

    ):
        self._id = _id or ObjectId()
        self.sender_id = sender_id
        self.recipient_id = recipient_id
        self.message = message
        self.timestamp = timestamp or datetime.utcnow()
        self.viewed = viewed

    def to_dict(self):
        return {
            '_id': self._id,
            'senderId': self.sender_id,
            'recipientId': self.recipient_id,
            'message': self.message,
            'timestamp': self.timestamp,
            'viewed': self.viewed
        }