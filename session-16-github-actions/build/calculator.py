import re

def add(a, b):
    return a + b

def subtract(a, b):
    return a - b

def multiply(a, b):
    return a * b

def divide(a, b):
    if b == 0:
        raise ValueError("Cannot divide by zero")
    return a / b

if __name__ == "__main__":
    print("================================")
    print("Session 16 Calculator Application")
    print("================================")
    print("Available operations: +, -, *, /")
    print("Sample: 10 + 5")
