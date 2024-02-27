#!/usr/bin/env python3
import socket
import sys

class TCPClient():
    def __init__(self, host, port):
        self.host = host
        self.port = port
        self.socket = None

    def write(self, msg):
        self.socket.sendall(msg.encode('utf-8'))
        data = self.socket.recv(1024)
        print(f"Receieved: {data.decode('utf-8')}")

    def __enter__(self):
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM) 
        self.socket.connect((self.host, self.port))
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.socket.close()


# Command line arguments
if len(sys.argv) == 3:
    HOST = sys.argv[1]
    PORT = sys.argv[2]
    try:
        PORT = int(PORT)
    except:
        raise RuntimeError(f"Invalid port: {PORT}")
elif len(sys.argv) == 1:
    print("Usage:")
    print("python3 tcp_client.py <host> <port>")
    exit()
else:
    print("Invalid input")
    exit()

# Connect the client, get input and read response until user enters "quit"
with TCPClient(host=HOST, port=PORT) as client:
    while True:
        msg = input(">> ")
        if msg == "quit":
            break
        client.write(msg)
