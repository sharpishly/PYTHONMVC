# core/autoload.py

import os
import importlib
import inspect
import logging

logger = logging.getLogger(__name__)

def load_controllers(base_dir):
    """
    Dynamically loads all controller classes from the 'controllers' directory.
    Assumes controller files are named 'controller_name.py' and contain a class
    named 'ControllerNameController'.
    Returns a dictionary mapping lowercase controller names to their instances.
    """
    controllers_path = os.path.join(base_dir, 'controllers')
    loaded_controllers = {}

    if not os.path.exists(controllers_path):
        logger.error(f"Controllers directory not found: {controllers_path}")
        return loaded_controllers

    for filename in os.listdir(controllers_path):
        if filename.endswith('.py') and filename != '__init__.py':
            module_name = filename[:-3] # Remove .py extension
            # Construct the full module path relative to the project root
            # e.g., 'controllers.home'
            full_module_path = f"controllers.{module_name}"

            try:
                # Dynamically import the module
                module = importlib.import_module(full_module_path)

                # Assume controller class name convention: e.g., 'HomeController' for 'home.py'
                class_name = f"{module_name.capitalize()}Controller"
                controller_class = getattr(module, class_name, None)

                if controller_class and inspect.isclass(controller_class):
                    # Instantiate the controller and store it
                    loaded_controllers[module_name.lower()] = controller_class()
                    logger.info(f"Loaded controller: {module_name.lower()} -> {class_name}")
                else:
                    logger.warning(f"Class '{class_name}' not found or not a class in module '{full_module_path}'.")

            except ImportError as e:
                logger.error(f"Failed to import module '{full_module_path}': {e}")
            except Exception as e:
                logger.error(f"Error loading controller from '{full_module_path}': {e}")

    return loaded_controllers

def load_models(base_dir):
    """
    Dynamically loads all model classes from the 'models' directory.
    This function is provided for completeness, but models are typically
    instantiated within their respective controllers, not globally.
    """
    models_path = os.path.join(base_dir, 'models')
    loaded_models = {}

    if not os.path.exists(models_path):
        logger.warning(f"Models directory not found: {models_path}")
        return loaded_models

    for filename in os.listdir(models_path):
        if filename.endswith('.py') and filename != '__init__.py':
            module_name = filename[:-3]
            full_module_path = f"models.{module_name}"

            try:
                module = importlib.import_module(full_module_path)
                class_name = f"{module_name.capitalize()}Model"
                model_class = getattr(module, class_name, None)

                if model_class and inspect.isclass(model_class):
                    loaded_models[module_name.lower()] = model_class # Store the class, not instance
                    logger.info(f"Loaded model class: {module_name.lower()} -> {class_name}")
                else:
                    logger.warning(f"Class '{class_name}' not found or not a class in module '{full_module_path}'.")

            except ImportError as e:
                logger.error(f"Failed to import module '{full_module_path}': {e}")
            except Exception as e:
                logger.error(f"Error loading model from '{full_module_path}': {e}")
    return loaded_models

# Note: For models, they are typically imported and instantiated within their
# respective controllers (e.g., HomeController imports HomeModel).
# The load_models function here is more for discovery if needed, but App
# primarily needs controller instances for routing.
