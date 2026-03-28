#!/usr/bin/env python
"""
Batch convert and compress audio file reccurssively
to use it first you need to change dir to target dir
thats how i use it
"""

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
    quiet=False,
    dryrun=False
):

    """
    Parse basic ffmpeg command for easy use
    """
    map_metadata = "0" if not clean_metadata else "-1"

    # Base command
    command = ["ffmpeg"]

    if overwrite:
        command.append("-y")  # auto overwrite

    if quiet:
        command.extend(["-hide_banner", "-loglevel", "error"])

    command.extend(["-i", input_file])

    if codec is not None:
        command.extend(["-vn", "-acodec", codec])

    if bitrate is not None:
        command.extend(["-b:a", bitrate])
    command.extend(["-map_metadata", map_metadata])

    if extra_args:
        command.extend(extra_args)

    command.append(output_file)

    # Execute command
    if dryrun:
        print("[!] Will execute command :")
        print(command)
        return
    
    subprocess.run(command)


def recurssive_convert(
        dir_path, 
        filter,
        is_src_del,
        extra={}):
    """
    Reccurssively convert by extension
    """

    extra_is_simple = extra.get("is_simple", True)
    extra_quiet = extra.get("quiet", True)
    extra_dryrun = extra.get("dryrun", False)
    extra_codec = extra.get("codec", "aac")
    extra_clean_metadata = extra.get("clean_metadata", False)
    extra_bitrate = extra.get("bitrate", "330k")
    extra_out_extension = extra.get("output_extension", None)

    for root, _, files in os.walk(dir_path):
        # Walk for file
        for file in files:
            # Filter, is extension are matching
            if file.endswith(filter):
                print(f"[!] - {file}")

                # Create full path file source
                file_source = os.path.join(root, file)

                # Create full path file output
                if extra_is_simple:
                    output_extension = ".m4a"
                else:
                    if extra_out_extension is not None:
                        _x = extra_out_extension
                    else:
                        _x = extra_codec
                        if extra_codec is None:
                            _x = filter
                    output_extension = _x

                out_file = f"{os.path.join(root, file).rstrip(filter)}_c.{output_extension}"

                convert(
                    input_file=file_source,
                    output_file=out_file,
                    quiet=extra_quiet,
                    dryrun=extra_dryrun,
                    codec=extra_codec,
                    clean_metadata=extra_clean_metadata,
                    bitrate=extra_bitrate
                )

                if is_src_del:
                    sleep(0.1)
                    os.remove(file_source)


def user_interact_do_accept():
    ui_confirm_action = input("Continue? (Y/n) ").lower()
    if ui_confirm_action in ("n", "no"):
        return 2
    elif ui_confirm_action in ("y", "yes"):
        return 1
    else:
        return 0


def user_interact(is_more=False):
    # Default option
    is_source_delete = False
    extension_filter = ".flac"
    extra_argument = {
        "codec" : "aac",
        "bitrate" : "330k",
        "clean_metadata" : False,
        "dryrun" : False,
        "quiet" : True,
        "is_simple" : True
    }

    # User Input
    ui_extension_filter = input("extension filter      ( Default .flac )  : ")
    ui_is_source_delete = input("delete original file? ( Y/n, Default no) : ").lower()
    
    if is_more:
        extra_argument["is_simple"] = False
        ui_extra_codec =    input("Codec              (default AAC) : ").lower()
        ui_extra_bitrate =  input("Bitrate           (default 330k) : ").lower()
        ui_extra_metadata = input("Clean metadata       (default n) : ").lower()
        ui_output_extension = input("Output extension (default codec) : ").lower()

        if len(ui_extra_codec) > 1:
            if ui_extra_codec == "none":
                _x = None
            else:
                _x = ui_extra_codec
            extra_argument["codec"] = _x
        
        if len(ui_extra_bitrate) > 1:
            if ui_extra_bitrate == "none":
                _y = None
            else:
                _y = ui_extra_bitrate
            extra_argument["bitrate"] = _y

        if len(ui_output_extension) > 0:
            extra_argument["output_extension"] = ui_output_extension

        extra_argument["clean_metadata"] = True if ui_extra_metadata in ("y", "yes") else False

    # Check if extension filter are more than 1 char and apply if true
    if len(ui_extension_filter) > 1:
        extension_filter = ui_extension_filter

    # Check if user agree, set is_source_delete to True
    if ui_is_source_delete in ("y", "yes"):
        is_source_delete = True

    # Run but not execute
    elif ui_is_source_delete == "dry":
        is_source_delete = False
        extra_argument["dryrun"] = True 

    # Summary
    print()
    print("--- SUMMARY ---")
    print("This will convert every file that have extension :", extension_filter)
    if is_source_delete:
        print("and will DELETE its original file")

    if is_more:
        print("and extra agrument")
        print(extra_argument)

    ui_is_accept = user_interact_do_accept()
    if ui_is_accept == 2:
        print("Abort")
        return 2
    if ui_is_accept != 1:
        print("Invalid, retry")
        return 1

    recurssive_convert(
        dir_path=".",
        filter=extension_filter,
        is_src_del=is_source_delete,
        extra=extra_argument
    )
    return 0


def main():
    is_m = input("More advance option? Y/n (default n) : ").lower()
    if is_m in ("y", "yes"):
        is_m = True
    else:
        is_m = False
    is_running = 1
    while is_running == 1:
        is_running = user_interact(is_more=is_m)

if __name__ == "__main__":
    main()
