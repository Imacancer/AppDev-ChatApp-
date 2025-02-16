from flask import Blueprint, request, jsonify
from models.messages import Message
from models.users import User
from db.db import db
from bson.objectid import ObjectId
from datetime import datetime
from utils.encryption import encrypt_message, decrypt_message  # Import the encryption utilities

message_bp = Blueprint('message', __name__)
message_collection = db.get_collection("messages")

class MessageController:
    @staticmethod
    @message_bp.route('/send', methods=['POST'])
    def send_message():
        try:
            data = request.get_json()
            
            # Validate required fields
            required_fields = ['sender_id', 'recipient_id', 'message']
            for field in required_fields:
                if field not in data:
                    print(f"Missing Field {field}")
                    return jsonify({"error": f"Missing {field}"}), 400
            
            # Encrypt the message before storing it
            #encrypted_message = encrypt_message(data['message'])
            
            # Create message object
            message = Message(
                sender_id=data['sender_id'],
                recipient_id=data['recipient_id'],
                message=data['message'] 
                #message=encrypted_message  # Store the encrypted message
            )
            
            # Insert message into database
            message_doc = message.to_dict()
            result = message_collection.insert_one(message_doc)
            
            return jsonify({
                "message": "Message sent successfully",
                "message_id": str(result.inserted_id)
            }), 201
        
        except Exception as e:
            return jsonify({"error": str(e)}), 500
    
    @staticmethod
    @message_bp.route('/get/<recipient_id>', methods=['GET'])
    def get_messages(recipient_id):
        try:
            # Retrieve messages for a specific recipient
            messages = list(message_collection.find({
                'recipient_id': recipient_id
            }).sort('timestamp', 1))
            
            # Decrypt the messages before returning them
            for msg in messages:
                msg['_id'] = str(msg['_id'])
                #msg['message'] = decrypt_message(msg['message'])  # Decrypt the message
            
            return jsonify(messages), 200
        
        except Exception as e:
            return jsonify({"error": str(e)}), 500
        
    @staticmethod
    @message_bp.route('/view/<message_id>', methods=['PUT'])
    def mark_message_as_viewed(message_id):
        try:
            # Validate the ObjectId format
            if not ObjectId.is_valid(message_id):
                return jsonify({"error": "Invalid message ID"}), 400

            # Update the specific message's 'viewed' field to True
            result = message_collection.update_one(
                {"_id": ObjectId(message_id)},  # Filter by message ID
                {"$set": {"viewed": True}}    # Update the 'viewed' field
            )

            if result.matched_count == 0:
                return jsonify({"error": "Message not found"}), 404

            return jsonify({"message": "Message marked as viewed successfully"}), 200

        except Exception as e:
            return jsonify({"error": str(e)}), 500
        
    @staticmethod
    @message_bp.route('/conversation/<sender_id>/<recipient_id>', methods=['GET'])
    def get_conversation(sender_id, recipient_id):
        try:
            # Retrieve messages for a specific sender and recipient
            messages = list(message_collection.find({
                "$or": [
                    {"senderId": sender_id, "recipientId": recipient_id},
                    {"senderId": recipient_id, "recipientId": sender_id}
                ]
            }).sort('timestamp', 1))

            for msg in messages:
                msg['_id'] = str(msg['_id'])

            return jsonify(messages), 200
        except Exception as e:
            return jsonify({"error": str(e)}), 500
        
    @staticmethod
    @message_bp.route('/getMessages/<user_id>', methods=['GET'])
    def get_user_messages(user_id):
        try:
            # Retrieve messages where the user is either the sender or the recipient
            messages = list(message_collection.find({
                "$or": [
                    {"senderId": user_id},
                    {"recipientId": user_id}
                ]
            }).sort('timestamp', 1))

            # Decrypt the messages before returning them
            for msg in messages:
                msg['_id'] = str(msg['_id'])
                #msg['message'] = decrypt_message(msg['message'])  # Decrypt the message

            return jsonify(messages), 200
        except Exception as e:
            return jsonify({"error": str(e)}), 500