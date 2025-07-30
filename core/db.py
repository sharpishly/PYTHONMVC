# core/db.py

class Database:
    def __init__(self):
        pass

    def get_data(self, collection_name):
        if collection_name == "home_page_data":
            return {
                "title": "Welcome to My MVC App!",
                "message": "This is a simple demonstration of the MVC pattern in Python.",
                "items": ["Item 1", "Item 2", "Item 3"]
            }
        return {}

db = Database()
