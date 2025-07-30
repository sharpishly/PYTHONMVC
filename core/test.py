# Example dict
my_data = {"name": "Alice", "age": 30, "skills": ["Python", "AI"]}
dBug(my_data)

# Example object
class Person:
    def __init__(self, name):
        self.name = name
        self.friends = []

alice = Person("Alice")
bob = Person("Bob")
alice.friends.append(bob)
bob.friends.append(alice)  # recursive

dBug(alice)

# Example XML
xml_string = """<person><name>Alice</name><age>30</age></person>"""
dBug(xml_string, force_type="xml")
