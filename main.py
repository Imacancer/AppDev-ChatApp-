import eventlet
eventlet.monkey_patch()

from flask import Flask, request
from flask_cors import CORS
from routes.routes import api
from flask_socketio import SocketIO
from controllers.webrtc import socketio as webrtc_socketio
from flask_jwt_extended import JWTManager

app = Flask(__name__)

app.config['JWT_SECRET_KEY'] = 'ea4fa1f117e1192d2efd58c7a232452a636acf8bd9e452af1ab8a41eeb3b99e0'
jwt = JWTManager(app)
CORS(app)
socketio = SocketIO(app, cors_allowed_origins="*")

webrtc_socketio.init_app(app, logger=True, engineio_logger=True)

app.register_blueprint(api, url_prefix='/api')
@app.before_request
def log_request():
    print(f"Incoming request: {request.method} {request.path} from origin {request.headers.get('Origin')}")
    



if __name__ == '__main__':
    socketio.run(app, debug=True,host='0.0.0.0', port=5001)
