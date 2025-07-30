# models/home.py

from core.db import db

class HomeModel:
    def get_home_page_data(self):
        return db.get_data("home_page_data")
