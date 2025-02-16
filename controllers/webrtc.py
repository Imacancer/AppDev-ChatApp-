# webrtc.py (Updated)
from flask import Blueprint, request, jsonify
from flask_socketio import SocketIO, emit, join_room, leave_room
from db.db import db
from models.messages import Message

webrtc_bp = Blueprint('webrtc', __name__)
socketio = SocketIO()
message_collection = db.get_collection("messages")

@socketio.on('connect')
def handle_connect():
    print(f"Client connected: {request.sid}")

@socketio.on('disconnect')
def handle_disconnect():
    print(f"Client disconnected: {request.sid}")

@socketio.on('join_room')
def handle_join_room(data):
    try:
        user_id = data.get('user_id')
        room = data.get('room')
        
        if not user_id or not room:
            return {'error': 'Invalid room or user_id'}
        
        join_room(room)
        emit('user_joined', {'user_id': user_id}, room=room)
        print(f"User {user_id} joined room {room}")
        return {'status': 'success'}
    except Exception as e:
        print(f"Error in join_room: {str(e)}")
        return {'error': str(e)}

@socketio.on('message')
def handle_message(data):
    try:
        recipient_id = data.get('recipient_id')
        message = data.get('message')
        
        if not recipient_id or not message:
            return {'error': 'Missing recipient or message'}
        
        # Save message to database
        message_obj = Message(
            sender_id=message['senderId'],
            recipient_id=recipient_id,
            message=message['message']
        )
        message_doc = message_obj.to_dict()
        message_collection.insert_one(message_doc)
        
        # Emit to recipient
        room = f"chat_{recipient_id}_{message['senderId']}"
        emit('message', message, room=room)
        return {'status': 'success'}
    except Exception as e:
        print(f"Error in handle_message: {str(e)}")
        return {'error': str(e)}

@socketio.on('offer')
def handle_offer(data):
    try:
        recipient_id = data.get('recipient_id')
        offer = data.get('offer')
        
        if not recipient_id or not offer:
            return {'error': 'Missing recipient or offer'}
        
        emit('offer', {
            'sender_id': request.sid,
            'offer': offer
        }, room=recipient_id)
        return {'status': 'success'}
    except Exception as e:
        print(f"Error in handle_offer: {str(e)}")
        return {'error': str(e)}

@socketio.on('answer')
def handle_answer(data):
    try:
        sender_id = data.get('sender_id')
        answer = data.get('answer')
        
        if not sender_id or not answer:
            return {'error': 'Missing sender or answer'}
        
        emit('answer', {
            'sender_id': request.sid,
            'answer': answer
        }, room=sender_id)
        return {'status': 'success'}
    except Exception as e:
        print(f"Error in handle_answer: {str(e)}")
        return {'error': str(e)}

@socketio.on('ice_candidate')
def handle_ice_candidate(data):
    try:
        recipient_id = data.get('recipient_id')
        candidate = data.get('candidate')
        
        if not recipient_id or not candidate:
            return {'error': 'Missing recipient or candidate'}
        
        emit('ice_candidate', {
            'sender_id': request.sid,
            'candidate': candidate
        }, room=recipient_id)
        return {'status': 'success'}
    except Exception as e:
        print(f"Error in handle_ice_candidate: {str(e)}")
        return {'error': str(e)}
    

socketio.on('profile_update')
def handle_profile_update(data):
    try:
        user_id = data.get('userId')
        profile_picture = data.get('profilePicture')
        
        if not user_id or not profile_picture:
            return {'error': 'Missing user_id or profile_picture'}
        
        # Update user profile in database
        users_collection = db.get_collection("users")
        users_collection.update_one(
            {"userId": user_id},
            {"$set": {"profilePicture": profile_picture}}
        )
        
        # Broadcast profile update to all connected clients
        emit('profile_update', {
            'userId': user_id,
            'profilePicture': profile_picture
        }, broadcast=True)
        
        return {'status': 'success'}
    except Exception as e:
        print(f"Error in handle_profile_update: {str(e)}")
        return {'error': str(e)}