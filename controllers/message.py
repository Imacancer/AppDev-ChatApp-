from flask import Blueprint, request, jsonify
from models.messages import Message
from models.users import User
from db.db import db
from bson.objectid import ObjectId
from datetime import datetime
from malicious_url_detector.detector import is_malicious

import cloudinary
import cloudinary.uploader
import re

message_bp = Blueprint('message', __name__)
message_collection = db.get_collection("messages")

class MessageController:
    @staticmethod
    def extract_urls(text):
        url_pattern = r'https?://[^\s]+'
        return re.findall(url_pattern, text)

    @staticmethod
    @message_bp.route('/send', methods=['POST'])
    def send_message():
        try:
            data = request.get_json()
            print("Incoming data:", data)

            message = Message(
                sender_id=data['sender_id'],
                recipient_id=data['recipient_id'],
                message=data.get('message', ''),  # Text fallback
                is_media=data.get('isMedia', False)
            )

            if 'file_url' in data and data['file_url']:
                message.message = data['file_url']

            message_text = message.message or ""
            urls = MessageController.extract_urls(message_text)

            trusted_domains = ['res.cloudinary.com']
            urls = [
                url for url in urls 
                if not any(domain in url for domain in trusted_domains)
            ]
            if not urls:
                message_doc = message.to_dict()
                message_doc['malicious'] = False
                result = message_collection.insert_one(message_doc)

                return jsonify({
                    "message": "Message sent",
                    "message_id": str(result.inserted_id),
                    "malicious": False,
                    "flaggedUrls": [],
                    "classificationMessages": []
                }), 201

            malicious_flag = False
            malicious_prob = None
            classification_messages = []
            flagged_urls = []

            for url in urls:
                try:
                    is_mal, prob, classification_message, classification = is_malicious(url)

                    if prob is not None and prob >= 0.9:
                        return jsonify({
                            "blocked": True,
                            "message": "Message blocked. Link is highly malicious.",
                            "url": url,
                            "probability": prob,
                            "classificationMessage": classification_message or "Highly malicious"
                        }), 400

                    if is_mal:
                        malicious_flag = True
                        malicious_prob = prob
                        flagged_urls.append({"url": url, "probability": prob})

                    classification_messages.append({
                        "url": url,
                        "classification": classification,
                        "message": classification_message or "Flagged as suspicious"
                    })

                except Exception as e:
                    print(f"[FALLBACK] Error during classification for URL {url}: {str(e)}")
                    classification_messages.append({
                        "url": url,
                        "classification": "unknown",
                        "message": "Could not classify this link due to an internal error."
                    })
                    continue

            # Insert the message into the database
            message_doc = message.to_dict()
            message_doc['malicious'] = malicious_flag
            if malicious_flag:
                message_doc['flaggedUrls'] = flagged_urls

            result = message_collection.insert_one(message_doc)

            return jsonify({
                "message": "Message sent",
                "message_id": str(result.inserted_id),
                "malicious": malicious_flag,
                "flaggedUrls": flagged_urls,
                "classificationMessages": classification_messages
            }), 201

        except Exception as e:
            print("Error in send_message:", str(e))  
            return jsonify({"error": str(e)}), 500


    @message_bp.route('/upload', methods=['POST'])
    def upload_media():
        try:
            file = request.files['file']
            if not file:
                return jsonify({"error": "No file uploaded"}), 400

            upload_result = cloudinary.uploader.upload(file)
            return jsonify({"url": upload_result['secure_url']}), 200

        except Exception as e:
            return jsonify({"error": str(e)}), 500
    
    @staticmethod
    @message_bp.route('/get/<recipient_id>', methods=['GET'])
    def get_messages(recipient_id):
        try:
            messages = list(message_collection.find({
                'recipient_id': recipient_id
            }).sort('timestamp', 1))

            for msg in messages:
                msg['_id'] = str(msg['_id'])

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
            messages = list(message_collection.find({
                "$or": [
                    {"senderId": sender_id, "recipientId": recipient_id},
                    {"senderId": recipient_id, "recipientId": sender_id}
                ]
            }).sort('timestamp', 1))

            for msg in messages:
                msg['_id'] = str(msg['_id'])
                msg['message'] = msg.get('message', '[Unreadable message]')
                
                msg['malicious'] = msg.get('malicious', False)
                msg['flaggedUrls'] = msg.get('flaggedUrls', [])
                msg['classificationMessages'] = msg.get('classificationMessages', [])


            return jsonify(messages), 200

        except Exception as e:
            print(f"Error in get_conversation: {str(e)}")
            return jsonify({"error": "Internal server error"}), 500
        
    @staticmethod
    @message_bp.route('/getMessages/<user_id>', methods=['GET'])
    def get_user_messages(user_id):
        try:
            messages = list(message_collection.find({
                "$or": [
                    {"senderId": user_id},
                    {"recipientId": user_id}
                ]
            }).sort('timestamp', 1))

            for msg in messages:
                msg['_id'] = str(msg['_id'])

            return jsonify(messages), 200
        except Exception as e:
            return jsonify({"error": str(e)}), 500
