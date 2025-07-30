# controllers/home.py

from models.home import HomeModel

class HomeController:
    def __init__(self):
        self.model = HomeModel()

    def index(self, render_template_func):
        """
        Handles the request for the home page (e.g., / or /home/index).
        It retrieves data from the HomeModel and passes it to the view.
        """
        home_data = self.model.get_home_page_data()
        items = home_data.get("items", [])
        # Generate HTML for items directly in the controller for simplicity
        # In a larger app, this might be handled by a more sophisticated templating system
        items_html = ''.join(f"<li>{item}</li>" for item in items)

        context = {
            "page_title": home_data.get("title", "Default Title"),
            "welcome_message": home_data.get("message", "No message."),
            "items_html": items_html
        }

        # Returns the view path and the context dictionary
        return "home/index.html", context

    def show(self, render_template_func):
        """
        Handles the request for a 'show' page (e.g., /home/show).
        Currently, it retrieves general home page data and passes it to the view.
        Note: This method no longer accepts an 'item_id' directly from the URL.
        If you intend to display specific item details based on a URL parameter
        (e.g., /home/show/123), you would need to re-add 'item_id' as a parameter
        to this method's signature (e.g., `def show(self, render_template_func, item_id=None):`).
        """
        home_data = self.model.get_home_page_data()
        items = home_data.get("items", [])
        items_html = ''.join(f"<li>{item}</li>" for item in items)

        context = {
            "page_title": home_data.get("title", "Default Title"),
            "welcome_message": home_data.get("message", "No message."),
            "items_html": items_html
        }

        # Returns the view path and the context dictionary
        return "home/show.html", context

    def greet(self, render_template_func, name="Guest"):
        """
        Example method demonstrating an optional URL argument (e.g., /home/greet/John or /home/greet).
        If no name is provided in the URL, it defaults to "Guest".
        """
        context = {
            "page_title": f"Greetings, {name}!",
            "message": f"Hello there, {name}! Welcome to our custom MVC app."
        }
        return "home/greet.html", context # Assuming you have a views/home/greet.html
