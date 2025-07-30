# models/user.py

from core.db import db

class UserModel:
    def get_home_page_data(self):
        return db.get_data("home_page_data")
