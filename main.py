from gevent import monkey
monkey.patch_all()

from flask import Flask, request
from flask_cors import CORS
from flask_socketio import SocketIO
from flask_jwt_extended import JWTManager
from routes.routes import api
from controllers.webrtc import socketio as webrtc_socketio
from utils.constants import jwt_secret_key

app = Flask(__name__)

app.config['JWT_SECRET_KEY'] = jwt_secret_key
jwt = JWTManager(app)
# CORS(app)
CORS(app, supports_credentials=True, resources={r"/*": {"origins": "*"}})
socketio = SocketIO(app, cors_allowed_origins="*", async_mode="eventlet")

webrtc_socketio.init_app(app, logger=True, engineio_logger=True)

app.register_blueprint(api, url_prefix='/api')
@app.before_request
def log_request():
    print(f"Incoming request: {request.method} {request.path} from origin {request.headers.get('Origin')}")
    print(f"Headers: {request.headers}")


if __name__ == '__main__':
    socketio.run(app, debug=True,host='0.0.0.0', port=5001)