from flask import request, jsonify
from models.users import User
from db.db import db
import cloudinary.uploader
import cloudinary.api
import cloudinary
import os
from werkzeug.security import generate_password_hash, check_password_hash
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from dotenv import load_dotenv

user_collection = db.get_collection("users")

load_dotenv()

cloudinary.config(
    cloud_name=os.getenv('CLOUDINARY_CLOUD_NAME'),
    api_key=os.getenv('API_KEY'),
    api_secret=os.getenv('API_SECRET')
)


class UserController:
    @staticmethod
    def add_user():
        try:
            data = request.get_json()
            required_fields = ['username', 'password', 'email', 'name', 'public_key']
            for field in required_fields:
                if field not in data:
                    return jsonify({"error": f"Missing field: {field}"}), 400

            # Hash the password
            hashed_password = generate_password_hash(data['password'], method='pbkdf2:sha256')

            # Handle profile picture upload
            profile_picture_url = None
            if 'profile_picture' in data and data['profile_picture']:
                try:
                    upload_result = cloudinary.uploader.upload(data['profile_picture'])
                    profile_picture_url = upload_result.get("secure_url")
                except Exception as upload_error:
                    print(f"Error uploading profile picture: {str(upload_error)}")
                    return jsonify({"error": "Failed to upload profile picture"}), 500

            user = User(
                username=data['username'],
                password=hashed_password,
                email=data['email'],
                name=data['name'],
                status=data.get('status', 'active'),
                profile_picture=profile_picture_url,
                device_tokens=data.get('device_tokens', []),
                last_seen=data.get('last_seen'),
                created_at=data.get('created_at'),
                updated_at=data.get('updated_at'),
                public_key=data.get('public_key')
            )
            user_doc = user.to_dict()

            # Insert user into the database
            user_collection.insert_one(user_doc)

            # Create an access token
            access_token = create_access_token(identity=user.username)
            return jsonify({
                "message": "User added successfully",
                "userId": user.userId,
                "accessToken": access_token
            }), 201
        except Exception as e:
            print(f"Error in add_user: {str(e)}")
            return jsonify({"error": "Internal server error"}), 500

    @staticmethod
    def login_user():
        try:
            data = request.get_json()
            email = data.get('email')
            password = data.get('password')

            # Validate input
            if not email or not password:
                return jsonify({"error": "email and password are required"}), 400

            # Find the user in the database
            user = user_collection.find_one({"email": email})
            if not user or not check_password_hash(user['password'], password):
                return jsonify({"error": "Invalid email or password"}), 401

            user['_id'] = str(user['_id'])

            # Generate JWT
            access_token = create_access_token(identity=email)
            return jsonify({
                "message": "Login successful",
                "accessToken": access_token,
                "user": user
            }), 200
        except Exception as e:
            print(f"Error in login_user: {str(e)}")
            return jsonify({"error": str(e)}), 500

    @staticmethod
    @jwt_required()
    def get_users():
        try:
            current_user = get_jwt_identity()  # Get the current user's identity from JWT
            print(f"Authenticated user: {current_user}")

            users = user_collection.find({}, {'_id': 0})  # Fetch all users, excluding '_id'
            users_list = list(users)
            return jsonify(users_list), 200
        except Exception as e:
            print(f"Error in get_users: {str(e)}")
            return jsonify({"error": str(e)}), 500

    @staticmethod
    @jwt_required()
    def get_user_by_id(userId):
        """
        Get user data by userId passed as a path parameter.
        Example: GET /api/get_user/5425342e3sd
        """
        try:
            if not userId:
                return jsonify({"error": "Missing userId"}), 400

            # Fetch the user from the database
            user = user_collection.find_one({"userId": userId})

            if not user:
                return jsonify({"error": "User not found"}), 404

            # Convert ObjectId to string for proper JSON serialization
            user['_id'] = str(user['_id'])

            return jsonify({
                "message": "User data fetched successfully",
                "user": user
            }), 200
        except Exception as e:
            print(f"Error in get_user_by_id: {str(e)}")
            return jsonify({"error": str(e)}), 500

    @staticmethod
    def search_users():
        try:
            # Get the 'query' parameter from the request URL
            query = request.args.get('query')
            if not query:
                return jsonify({"error": "Query parameter is required"}), 400

            # Perform a case-insensitive search for users whose usernames contain the query
            users = user_collection.find({"username": {"$regex": query, "$options": "i"}})
            
            # Convert the user documents to a list of dictionaries
            user_list = []
            for user in users:
                user_details = {
                    "userId": user.get("userId"),
                    "username": user.get("username"),
                    "name": user.get("name"),
                    "profilePicture": user.get("profilePicture"),
                    "email": user.get("email"),
                }
                user_list.append(user_details)

            return jsonify({"users": user_list}), 200

        except Exception as e:
            return jsonify({"error": str(e)}), 500
        
    @staticmethod
    def get_public_key(userId):
        try:
            if not userId:
                return jsonify({"error": "Missing userId"}), 400

            # Fetch the user from the database
            user = user_collection.find_one({"userId": userId})

            if not user:
                return jsonify({"error": "User not found"}), 404

            # Convert ObjectId to string for proper JSON serialization
            user['_id'] = str(user['_id'])
            user['publicKey'] = user['publicKey']

            return jsonify({
                "publicKey": user['publicKey']
            }), 200
        except Exception as e:
            print(f"Error in get_public_key: {str(e)}")