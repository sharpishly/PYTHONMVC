from models.users import UsersModel

class UsersController:
    def __init__(self):
        self.model = UsersModel()

    def index(self, render_template_func):
        data = self.model.get_home_page_data()
        items = data.get("items", [])
        items_html = ''.join(f"<li>{item}</li>" for item in items)
        context = {
            "page_title": data.get("title", "Default Title"),
            "welcome_message": data.get("message", "No message."),
            "items_html": items_html
        }
        return "users/index.html", context

    def show(self, render_template_func):
        data = self.model.get_home_page_data()
        items = data.get("items", [])
        items_html = ''.join(f"<li>{item}</li>" for item in items)
        context = {
            "page_title": data.get("title", "Default Title"),
            "welcome_message": data.get("message", "No message."),
            "items_html": items_html
        }
        return "users/show.html", context

    def greet(self, render_template_func, name="Guest"):
        context = {
            "page_title": f"Greetings, {name}!",
            "message": f"Hello there, {name}! Welcome to our custom MVC app."
        }
        return "users/greet.html", context
