from rich.console import Console
from rich.table import Table
from rich.text import Text
from rich import box
import types
import xml.etree.ElementTree as ET

console = Console()

class dBug:
    def __init__(self, var, force_type=None, collapsed=False):
        self.visited = set()
        self.collapsed = collapsed
        self.force_type = force_type
        if force_type == 'array':
            self.var_is_array(var)
        elif force_type == 'object':
            self.var_is_object(var)
        elif force_type == 'xml':
            self.var_is_xml(var)
        else:
            self.check_type(var)

    def check_type(self, var):
        if var is None:
            console.print("[bold red]NULL[/bold red]")
        elif isinstance(var, bool):
            console.print(f"[bold magenta]{'TRUE' if var else 'FALSE'}[/bold magenta]")
        elif isinstance(var, (int, float, str)):
            console.print(repr(var))
        elif isinstance(var, dict):
            self.var_is_array(var)
        elif isinstance(var, (list, tuple, set)):
            self.var_is_array({i: v for i, v in enumerate(var)})
        elif hasattr(var, '__dict__'):
            self.var_is_object(var)
        else:
            console.print(f"[bold red]Unsupported type: {type(var).__name__}[/bold red]")

    def var_is_array(self, var):
        table = Table(show_header=True, header_style="bold green", box=box.MINIMAL_DOUBLE_HEAD)
        table.add_column("Key")
        table.add_column("Value")
        id_var = id(var)

        if id_var in self.visited:
            table.add_row("*RECURSION*", "")
            console.print(table)
            return

        self.visited.add(id_var)

        for key, value in var.items():
            if isinstance(value, (dict, list, tuple, set)):
                sub_table = dBug(value)
                table.add_row(str(key), "[Nested]")
            else:
                table.add_row(str(key), repr(value))

        console.print(table)

    def var_is_object(self, var):
        table = Table(show_header=True, header_style="bold blue", box=box.MINIMAL_DOUBLE_HEAD)
        table.add_column("Attribute")
        table.add_column("Value")

        id_var = id(var)
        if id_var in self.visited:
            table.add_row("*RECURSION*", "")
            console.print(table)
            return

        self.visited.add(id_var)

        for attr, value in vars(var).items():
            if isinstance(value, (dict, list, tuple, set)):
                dBug(value)
                table.add_row(attr, "[Nested]")
            else:
                table.add_row(attr, repr(value))

        methods = [m for m in dir(var) if isinstance(getattr(var, m), types.MethodType)]
        for method in methods:
            table.add_row(method, "[method]")

        console.print(table)

    def var_is_xml(self, var):
        try:
            if isinstance(var, str) and var.strip().startswith("<"):
                root = ET.fromstring(var)
            else:
                root = ET.parse(var).getroot()
        except Exception as e:
            console.print(f"[bold red]XML parsing error:[/bold red] {e}")
            return

        def recurse_xml(elem, depth=0):
            pad = "  " * depth
            console.print(f"{pad}[bold yellow]<{elem.tag}>[/bold yellow]")
            if elem.attrib:
                for k, v in elem.attrib.items():
                    console.print(f"{pad}  [cyan]{k}[/cyan] = {v}")
            if elem.text and elem.text.strip():
                console.print(f"{pad}  [white]{elem.text.strip()}[/white]")
            for child in elem:
                recurse_xml(child, depth + 1)

        recurse_xml(root)

