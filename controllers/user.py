# controllers/user.py

from models.user import UserModel

class UserController:
    def __init__(self):
        self.model = UserModel()

    def index(self, render_template_func):
        """
        Handles the request for the user page (e.g., /user or /user/index).
        It retrieves data from the UserModel and passes it to the view.
        """
        user_data = self.model.get_user_page_data() # This now correctly calls the method in UserModel
        items = user_data.get("items", [])
        # Generate HTML for items directly in the controller for simplicity
        # In a larger app, this might be handled by a more sophisticated templating system
        items_html = ''.join(f"<li>{item}</li>" for item in items)

        context = {
            "page_title": user_data.get("title", "Default User Title"),
            "welcome_message": user_data.get("message", "No user message."),
            "items_html": items_html
        }

        # Returns the view path and the context dictionary
        return "user/index.html", context

    # You can add other methods here, e.g., show(self, render_template_func, user_id)
    # def show(self, render_template_func, user_id):
    #     user_details = self.model.get_user_details(user_id)
    #     return "user/show.html", {"user": user_details}
