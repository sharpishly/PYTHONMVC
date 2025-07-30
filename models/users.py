from core.db import db

class UsersModel:
    def get_home_page_data(self):
        return db.get_data("users_page_data")
