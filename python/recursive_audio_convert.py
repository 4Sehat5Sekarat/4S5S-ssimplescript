#!/usr/bin/env python
"""
Batch convert and compress audio file reccurssively
to use it first you need to change dir to target dir
thats how i use it
"""


import subprocess
import os


def convert(
    input_file,
    output_file,
    codec="aac",
    bitrate="330k",
    clean_metadata=False,
    extra_args=None,
    overwrite=True,
    quiet=False,
):
    map_metadata = "0" if not clean_metadata else "-1"
    command = ["ffmpeg"]

    if overwrite:
        command.append("-y")  # auto overwrite
    if quiet:
        command.extend(["-hide_banner", "-loglevel", "error"])

    command.extend(["-i", input_file])

    if codec:
        command.extend(["-vn", "-acodec", codec])
    if bitrate:
        command.extend(["-b:a", bitrate])
    command.extend(["-map_metadata", map_metadata])

    if extra_args:
        command.extend(extra_args)

    command.append(output_file)

    subprocess.run(command)


def recurssive_convert(dir_path, filter, is_src_del):
    for root, dir, files in os.walk(dir_path):
        for file in files:
            if file.endswith(filter):
                print(f"[!] - {file}")
                file_source = os.path.join(root, file)
                out_file = f"{os.path.join(root, file).rstrip(filter)}_c.m4a"
                convert(input_file=file_source, output_file=out_file, quiet=True)
                if is_src_del:
                    os.remove(file_source)


def main():
    is_src_del = False
    ext_fil = ".flac"
    ui_ext_fil = input("extension filter      ( Default .flac ) : ")
    ui_src_del = input("delete original file? ( Y/n Default no) : ")

    if len(ui_ext_fil) > 1:
        ext_fil = ui_ext_fil
    else:
        print("use default falue .flac")

    if ui_src_del.lower() == "y":
        print("delete original file")
        is_src_del = True

    recurssive_convert(".", ext_fil, is_src_del)


if __name__ == "__main__":
    main()
