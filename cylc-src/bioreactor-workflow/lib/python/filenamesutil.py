"""
This module contains utility functions based on the Fabric library.
Used to run commands on remote servers. 
"""

from typing import Optional
from pathlib import Path, PurePath
from dataclasses import dataclass

# from fabric import Connection, Result


# def get_remote_filenames(conn: Connection, directory: Path) -> list[str]:
#     """Return a list of all filenames in a remote directory.\n
#     Doesn't open connections by itself, but uses the Connection object passed to
#     it."""
#     result: Result = conn.run(f"ls -1 -p {directory} | grep -v /", warn=True)
#     return result.stdout.splitlines()


def get_local_filenames(directory: Path) -> list[str]:
    """Return a list of all filenames in a local directory."""
    return [str(f) for f in directory.iterdir() if f.is_file()]


@dataclass
class FileNameComponents:
    """Dataclass to hold the components of a file name."""

    stem_prefix: Optional[str]
    stem_suffix: Optional[str]
    extension: Optional[str]

    def to_string(self):
        """Return the file name as a string."""
        return f"{self.stem_prefix}_{self.stem_suffix}{self.extension}"

    @staticmethod
    def from_path(filepath: PurePath):
        """Return a FileNameComponents object from a Path object. It will only
        look at the final element of the Path.
        """
        extension = filepath.suffix
        stem = filepath.stem
        if "_" not in stem:
            stem_prefix = stem
            stem_suffix = None
        else:
            stem_prefix = "_".join(stem.split("_")[0:-1])
            stem_suffix = stem.split("_")[-1]
        stem_prefix = stem_prefix if stem_prefix else None
        extension = extension if extension else None
        return FileNameComponents(stem_prefix, stem_suffix, extension)

    @staticmethod
    def from_filename(filename: str):
        """Return a FileNameComponents object from a string."""
        return FileNameComponents.from_path(PurePath(filename))


if __name__ == "__main__":
    HOST = "genobioinfo.toulouse.inrae.fr"
    with Connection(HOST) as c:
        filelist = get_remote_filenames(c, Path("~/save"))
        c.get(f"save/{filelist[0]}", "/Users/elliotfontaine/Downloads/")
    print(filelist)
    print(type(filelist[0]))
    a = FileNameComponents.from_path(PurePath("file_1.raw"))
    print(a)
