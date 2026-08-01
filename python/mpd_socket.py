#!/usr/bin/env python
"""
Read mpd using socket
"""

import socket


class connect:
    def __init__(self, HOST: str = "127.0.0.1", PORT: str | int = 6600) -> None:
        self.HOST = HOST
        self.PORT = PORT

        s = socket.socket()
        s.connect((HOST, PORT))

        self.__socket__ = s

    def __execute__(self, command: str) -> list:
        s = self.__socket__
        s.sendall((command + "\n").encode())
        response = []

        with s.makefile("r") as stream:
            for line in stream:
                line = line.strip()
                if line == "OK":
                    break
                if line.split(" ")[0] == "ACK":
                    print("ERROR")
                    break
                response.append(line)
        return response

    def status(self) -> dict:
        response = {}
        r = self.__execute__("status")
        for line in r:
            if "OK MPD" in line:
                continue
            line = line.split(":")
            if len(line) > 2:
                response[line[0]] = line[1:]
            else:
                response[line[0]] = line[1].strip()
        return response

    def pause(self) -> list:
        """
        Pause Music
        """
        response = self.__execute__("pause")
        return response

    def play(self) -> list:
        """
        Play Music
        """
        response = self.__execute__("play")
        return response

    def stop(self) -> list:
        """
        Stop Music
        """
        response = self.__execute__("stop")
        return response

    def playlist(self) -> list:
        """
        Get current playlist
        """
        response = []
        r = self.__execute__("playlistinfo")
        for line in r:
            if "OK MPD" in line:
                continue
            if line.split(":")[0].strip() == "Title":
                response.append(line)
        return response

    def current(self) -> None:
        """
        Hello world
        """
        s = self.status()
        print("Volume : ", s["volume"].strip())

    def volume(self, volume: int | None = None) -> int:
        """
        Set volume
        """
        if volume:
            n = "setvol " + str(volume)
            self.__execute__(n)
        return int(self.status()["volume"])

    def direct_input(self):
        while True:
            command = input("> ")
            if command == "q":
                break
            out = self.__execute__(command)
            print(out)
