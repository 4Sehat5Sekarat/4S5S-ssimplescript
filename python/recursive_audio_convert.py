#!/usr/bin/env python

import subprocess
import os
from time import sleep


def convert(
    input_file,
    output_file,
    codec=None,
    bitrate=None,
    clean_metadata=False,
    extra_args=None,
    overwrite=True,
    quiet=True,
    execute=False,
):
    command = ["ffmpeg"]

    if overwrite:
        command.append("-y")

    if quiet:
        command.extend(["-hide_banner", "-loglevel", "error"])

    command.extend(["-i", input_file])

    if codec is not None:
        command.extend(["-vn", "-acodec", codec])

    if bitrate is not None:
        command.extend(["-b:a", bitrate])

    map_metadata = "0" if not clean_metadata else "-1"
    command.extend(["-map_metadata", map_metadata])

    if extra_args:
        command.extend(extra_args)

    command.append(output_file)

    result_data = {}
    result_data["command"] = command
    result_data["returncode"] = None
    result_data["stdout"] = None

    if execute:
        result = subprocess.run(command)
        result_data["returncode"] = result.returncode
        result_data["stdout"] = result.stdout

    return result_data


def get_files_list(dir_path, filter_ext):
    file_list = []

    for path, _, files in os.walk(dir_path):
        for file in files:
            if file.endswith(filter_ext):
                file_list.append(os.path.join(path, file))

    return sorted(file_list)


def ui_show_messages(message: dict, separator=":"):
    max_len = max(len(k) for k in message)
    keys = list(message.keys())

    for i, key in enumerate(keys, 1):
        value = message[key]
        print(f"{i:>2}. {key:<{max_len}} {separator} {value}")


def ui_input(prompt="> ", is_boolean=False, old_value=None):
    user_input = input(prompt).strip()

    if is_boolean:
        if user_input.lower() in ("y", "yes", "true"):
            return True
        elif user_input.lower() in ("n", "no", "false"):
            return False
        elif user_input == "":
            return old_value
        else:
            print("[!] input harus y/n")
            return None
    else:
        if user_input == "":
            return old_value
        return user_input


def main():
    argument = {
        "codec": "aac",
        "bitrate": "330k",
        "clean_metadata": False,
        "delete source": False,
        "extension original": ".flac",
        "extension result": ".m4a",
        "dryrun": False,
    }

    ui_show_messages(argument)
    while True:
        user_input = input("> ").strip()

        # Input if its empty or done and end loops
        if user_input in ("", "done"):
            acc = ui_input(prompt="done? > ", is_boolean=True, old_value=False)
            if acc:
                break  # end loops
            else:
                continue

        # Input if its q or exit and end programs
        if user_input in ("q", "exit"):
            acc = ui_input(prompt="exit? > ", is_boolean=True, old_value=False)
            if acc:
                print("Abort")
                return  # exit
            else:
                continue

        # show summary
        if user_input in ("sum", "summary"):
            ui_show_messages(argument)
            continue

        # if not input a number its skip current loop
        if not user_input.isdigit():
            print("[!] input must be a digit")
            continue

        # if input are digit, then this bellow are executed
        idx = int(user_input)  # Turn user_input into a integer
        keys = list(argument.keys())  # get a list of argument's key

        # if input are more than argument, will skip current
        if idx < 1 or idx > len(keys):
            print("[!] out of range")
            continue

        key = keys[
            idx - 1
        ]  # get current input key, it devided by 1 bcause python start index from 0
        current_value = argument[key]  # get current valeu

        print(
            f"Edit: {key} (current: {current_value})"
        )  # to ensure myself using a right choice

        # check is current edited key are booleans
        is_bool = isinstance(current_value, bool)

        new_value = ui_input(
            prompt="value > ",
            is_boolean=is_bool,
            old_value=current_value,
        )

        if new_value is not None:
            argument[key] = new_value
            print(f"[✓] updated: {key} = {new_value}")
        else:
            print("[!] unchanged")

    ui_show_messages(argument)
    file_list = get_files_list(".", argument["extension original"])

    if argument["extension result"][0] != 0:
        argument["extension result"] = f".{argument['extension result']}"

    if argument["extension original"][0] != 0:
        argument["extension original"] = f".{argument['extension original']}"

    if argument["codec"].lower() == "none":
        argument["codec"] = None

    if argument["bitrate"].lower() == "none":
        argument["bitrate"] = None

    execute = False if argument["dryrun"] else True

    if argument["dryrun"]:
        for input_file in file_list:
            print("[!] Convert :", input_file)
            if argument["delete source"]:
                print("[!] unDelet :", input_file)

        acc = ui_input(
            prompt="continue [real] convert? > ", is_boolean=True, old_value=False
        )
        if not acc:
            print("Abort")
            return  # exit
        else:
            execute = True

    for input_file in file_list:
        output_file = f"{input_file.rstrip(argument['extension original'])}{argument['extension result']}"
        print("[!] Convert :", input_file)

        try:
            result = convert(
                input_file=input_file,
                output_file=output_file,
                codec=argument["codec"],
                bitrate=argument["bitrate"],
                clean_metadata=argument["clean_metadata"],
                execute=execute,
            )
        except Exception as _:
            print("[X] Fail convert :", input_file)
            continue

        is_convert_sucess = True if result["returncode"] == 0 else False
        if argument["delete source"] and is_convert_sucess:
            print("[!] Delete  :", input_file)
            sleep(0.1)
            os.remove(input_file)


if __name__ == "__main__":
    main()
