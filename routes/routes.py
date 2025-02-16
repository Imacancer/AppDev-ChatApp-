from flask import Blueprint
from controllers.auth import UserController
from controllers.message import message_bp
from controllers.webrtc import webrtc_bp

api = Blueprint('api', __name__)

api.add_url_rule('/add_user', view_func=UserController.add_user, methods=['POST'])
api.add_url_rule('/log_users', view_func=UserController.login_user, methods=['POST'])
api.add_url_rule('/get_users', view_func=UserController.get_users, methods=['GET'])
api.add_url_rule('/get_user/<userId>', view_func=UserController.get_user_by_id, methods=['GET'])
api.add_url_rule('/search_users', view_func=UserController.search_users, methods=['GET'])
api.add_url_rule('/get_public_key/<userId>', view_func=UserController.get_public_key, methods=['GET'])

api.register_blueprint(message_bp, url_prefix='/messages')
api.register_blueprint(webrtc_bp, url_prefix='/webrtc')

