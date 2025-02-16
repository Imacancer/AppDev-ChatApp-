from pymongo import MongoClient
from dotenv import load_dotenv
import os


load_dotenv()

class Database:
    def __init__(self):
        try:
            print("Initializing Database connection...")
            mongo_uri = os.getenv('MONGO_URI')
            mongo_db = os.getenv('MONGO_DB')   

            if not mongo_uri or not mongo_db:
                raise ValueError("MONGO_URI or MONGO_DB is not set in the .env file")

            # Connect to MongoDB
            self.client = MongoClient(mongo_uri)
            self.db = self.client[mongo_db]
            print(f"Connected to MongoDB at {mongo_uri}")
            print(f"Using database: {mongo_db}")
        except Exception as e:
            print(f"Error initializing Database: {str(e)}")
            raise

    def get_collection(self, collection_name):
        try:
            print(f"Accessing collection: {collection_name}")
            return self.db[collection_name]
        except Exception as e:
            print(f"Error accessing collection {collection_name}: {str(e)}")
            raise


db = Database()


users_collection = db.get_collection('users')  
