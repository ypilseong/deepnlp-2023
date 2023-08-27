from pathlib import Path
from typing import Optional

BOOK_DIR = Path("book")
PROJECTS_DIR = BOOK_DIR / "projects"
toc_file = BOOK_DIR / "_toc.yml"

toc_contents = """
# Table of contents
# Learn more at https://jupyterbook.org/customize/toc.html

format: jb-book
root: index
chapters:
  - file: syllabus/index
"""


def generate_toc(
    toc_contents: str,
    root: Path,
    section_dir: Optional[Path] = None,
    num_indent_space: int = 2,
):
    """
    Generates a table of contents (TOC) for a given directory structure.

    Args:
        toc_contents (str): The current contents of the TOC.
        root (Path): The root directory of the directory structure.
        section_dir (Optional[Path], optional): The directory to generate the TOC for. Defaults to None.
        num_indent_space (int, optional): The number of spaces to use for indentation. Defaults to 2.

    Returns:
        str: The updated contents of the TOC.
    """
    indent = " " * num_indent_space
    section_dir = section_dir or root
    for path_ in section_dir.iterdir():
        if path_.is_dir():
            num_indent_space += 2
            indent = " " * num_indent_space
            toc_entry = f"{indent}sections:\n"
            toc_contents += toc_entry
            toc_contents = generate_toc(toc_contents, root, path_, num_indent_space + 2)
        else:
            rel_path = path_.relative_to(root)
            toc_entry = f"{indent}- file: {rel_path.parent}/{rel_path.stem}\n"
            toc_contents += toc_entry
    return toc_contents


toc_contents = generate_toc(toc_contents, BOOK_DIR, PROJECTS_DIR)
print(toc_contents)


with open(toc_file, "w") as f:
    f.write(toc_contents)
