from core.db import db

class ProductsModel:
    def get_home_page_data(self):
        return db.get_data("products_page_data")
