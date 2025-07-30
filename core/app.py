import os
import re
import logging
# Import the autoload function
from core.autoload import load_controllers

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class App:
    def __init__(self, base_dir):
        self.base_dir = base_dir
        # Dynamically load all controllers
        self.controllers = load_controllers(base_dir)

        # Ensure a default 'home' controller exists, or handle its absence
        if 'home' not in self.controllers:
            logger.error("Default 'home' controller not found. Application may not function correctly.")
            # You might want to raise an error or provide a fallback here
            # For now, we'll let it proceed, but requests to '/' will fail.


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
        segments = [s for s in path.strip('/').split('/') if s]

        controller_name = 'home' # Default controller if path is '/' or empty
        method_name = 'index'    # Default method if path is '/' or only controller specified
        args = []                # Arguments for the method, extracted from URL segments

        if segments:
            controller_name = segments[0].lower()
            if len(segments) > 1:
                method_name = segments[1].lower()
            args = segments[2:]

        controller_instance = self.controllers.get(controller_name)

        if not controller_instance:
            logger.warning(f"Controller '{controller_name}' not found for path '{path}'.")
            return "404 Not Found: Controller not found"

        handler_method = getattr(controller_instance, method_name, None)

        if not handler_method or not callable(handler_method):
            logger.warning(f"Method '{method_name}' not found or not callable in controller '{controller_name}' for path '{path}'.")
            return "404 Not Found: Method not found"

        try:
            view_name, context = handler_method(self._render_template, *args)
            return self._render_template(view_name, context)
        except TypeError as te:
            logger.error(f"TypeError when calling {controller_name}.{method_name} with args {args}: {te}. Check method signature in controller.")
            return f"500 Internal Server Error: Invalid arguments for method. Please check the URL or controller method definition. Error: {te}"
        except Exception as e:
            logger.error(f"Error handling request for '{path}' by {controller_name}.{method_name}: {e}")
            return f"500 Internal Server Error: {e}"

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(current_dir)

    app = App(base_dir=project_root)

    print("--- Simulating a request to / ---")
    response = app.handle_request('/')
    print(response)

    print("\n--- Simulating a request to /home/index ---")
    response = app.handle_request('/home/index')
    print(response)

    print("\n--- Simulating a request to /user/index ---")
    response_user = app.handle_request('/user/index')
    print(response_user)

    print("\n--- Simulating a request to /nonexistent/method ---")
    response_404_controller = app.handle_request('/nonexistent/method')
    print(response_404_controller)

    print("\n--- Simulating a request to /home/nonexistent_method ---")
    response_404_method = app.handle_request('/home/nonexistent_method')
    print(response_404_method)
