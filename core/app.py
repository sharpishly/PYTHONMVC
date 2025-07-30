import os
import re
import logging
# Import all controllers here
from controllers.home import HomeController

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class App:
    def __init__(self, base_dir):
        self.base_dir = base_dir
        # Map controller names (from URL) to their instances
        self.controllers = {
            'home': HomeController(), # Instantiate HomeController
            # Add other controllers here as needed, e.g., 'users': UserController(),
        }

    def _replace_placeholders(self, content, context):
        """
        Replaces {{ placeholder }} strings in the content with values from the context dictionary.
        """
        pattern = re.compile(r'{{\s*(\w+)\s*}}')
        return pattern.sub(lambda match: str(context.get(match.group(1), match.group(0))), content)

    def _include_partials(self, content):
        """
        Includes partial HTML files specified by {{ partials/path/to/partial }} in the content.
        """
        while '{{ partials/' in content:
            start = content.find('{{ partials/')
            end = content.find(' }}', start)
            if start != -1 and end != -1:
                partial_name = content[start + len('{{ partials/'):end].strip()
                # Construct the path to the partial, assuming it's in the 'views' directory
                # and follows the partials/directory/file.html structure.
                partial_path = os.path.join(self.base_dir, 'views', *partial_name.split('/')) + '.html'
                try:
                    with open(partial_path, 'r') as p_f:
                        partial_content = p_f.read()
                    content = content[:start] + partial_content + content[end + len(' }}'):]
                except FileNotFoundError:
                    logger.warning(f"Partial '{partial_name}.html' not found at '{partial_path}'.")
                    content = content[:start] + f"<!-- Partial '{partial_name}.html' not found -->" + content[end + len(' }}'):]
            else:
                break # No more partials found or malformed tag
        return content

    def _render_template(self, view_path, context={}):
        """
        Renders an HTML template by reading its content, including partials,
        and replacing placeholders with provided context data.
        """
        full_path = os.path.join(self.base_dir, 'views', view_path)
        try:
            with open(full_path, 'r') as f:
                content = f.read()

            content = self._include_partials(content)
            content = self._replace_placeholders(content, context)

            return content
        except FileNotFoundError:
            logger.error(f"View '{view_path}' not found at '{full_path}'.")
            return f"Error: View '{view_path}' not found."
        except Exception as e:
            logger.error(f"Error rendering view '{view_path}': {e}")
            return f"Error rendering view: {e}"

    def handle_request(self, path):
        """
        Handles incoming HTTP requests by parsing the URL path to determine
        the controller, method, and arguments, then dispatches the request.
        """
        # Clean and split the path into segments.
        # Example: '/home/index/param1' -> ['home', 'index', 'param1']
        # Handles leading/trailing slashes and ensures no empty segments.
        segments = [s for s in path.strip('/').split('/') if s]

        controller_name = 'home' # Default controller if path is '/' or empty
        method_name = 'index'    # Default method if path is '/' or only controller specified
        args = []                # Arguments for the method, extracted from URL segments

        if segments:
            # The first segment is the controller name
            controller_name = segments[0].lower()
            if len(segments) > 1:
                # The second segment is the method name
                method_name = segments[1].lower()
            # Any remaining segments are arguments for the method
            args = segments[2:]

        # Retrieve the controller instance from the registered controllers
        controller_instance = self.controllers.get(controller_name)

        if not controller_instance:
            logger.warning(f"Controller '{controller_name}' not found for path '{path}'.")
            return "404 Not Found: Controller not found"

        # Get the method from the controller instance using getattr
        # getattr allows dynamic access to methods by string name
        handler_method = getattr(controller_instance, method_name, None)

        # Check if the found attribute is indeed a callable method
        if not handler_method or not callable(handler_method):
            logger.warning(f"Method '{method_name}' not found or not callable in controller '{controller_name}' for path '{path}'.")
            return "404 Not Found: Method not found"

        try:
            # Call the handler method.
            # The first argument passed to the controller method will be the _render_template function.
            # Subsequent arguments will be the URL parameters.
            # The controller method is expected to return a tuple: (view_name, context_dictionary).
            view_name, context = handler_method(self._render_template, *args)
            # Render the final HTML response using the returned view name and context
            return self._render_template(view_name, context)
        except TypeError as te:
            # Catch TypeError specifically for cases where method signature doesn't match arguments
            logger.error(f"TypeError when calling {controller_name}.{method_name} with args {args}: {te}. Check method signature in controller.")
            return f"500 Internal Server Error: Invalid arguments for method. Please check the URL or controller method definition. Error: {te}"
        except Exception as e:
            # Catch any other unexpected errors during request handling
            logger.error(f"Error handling request for '{path}' by {controller_name}.{method_name}: {e}")
            return f"500 Internal Server Error: {e}"

if __name__ == "__main__":
    # Determine the project root directory
    current_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(current_dir)

    # Initialize the App with the project root
    app = App(base_dir=project_root)

    # --- Simulating various requests to test the routing ---

    print("--- Simulating a request to / (default home/index) ---")
    response = app.handle_request('/')
    print(response)

    print("\n--- Simulating a request to /home (default home/index) ---")
    response = app.handle_request('/home')
    print(response)

    print("\n--- Simulating a request to /home/index ---")
    response = app.handle_request('/home/index')
    print(response)

    print("\n--- Simulating a request to /nonexistent/method (should be 404 controller) ---")
    response_404_controller = app.handle_request('/nonexistent/method')
    print(response_404_controller)

    print("\n--- Simulating a request to /home/nonexistent_method (should be 404 method) ---")
    response_404_method = app.handle_request('/home/nonexistent_method')
    print(response_404_method)

    # To fully test argument passing, ensure your HomeController has a method like 'show'
    # For example, in controllers/home.py, you might add:
    #
    # class HomeController:
    #     def index(self, render_template):
    #         return 'home/index.html', {'title': 'Welcome Home'}
    #
    #     def show(self, render_template, item_id):
    #         # This method expects one argument, 'item_id', from the URL
    #         return 'home/show.html', {'item_id': item_id, 'message': f'Displaying item with ID: {item_id}'}
    #
    # Then you can uncomment and test the following:
    # print("\n--- Simulating a request to /home/show/123 (with argument) ---")
    # response_with_args = app.handle_request('/home/show/123')
    # print(response_with_args)
