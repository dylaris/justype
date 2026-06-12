# -*- coding: utf-8 -*-
"""
Split Aesop's Fables into individual text files.
Usage: python split_aesop.py input.txt output_dir/
"""

import os
import re
import sys

def split_fables(content):
    """Split fables by lines starting with THE."""
    # 匹配以 THE 开头的行（后面跟空格或标点，不是小写字母）
    pattern = r'^THE(?=[^a-z])[^\n]*\n'

    matches = list(re.finditer(pattern, content, re.MULTILINE))

    if not matches:
        print("No fables found. Check the pattern.")
        return []

    fables = []
    for i, match in enumerate(matches):
        title = match.group(0).strip()
        start = match.end()

        if i + 1 < len(matches):
            end = matches[i + 1].start()
        else:
            end = len(content)

        text = content[start:end].strip()
        text = re.sub(r'\n{3,}', '\n\n', text)

        fables.append({
            'title': title,
            'text': text
        })

    return fables

def sanitize_filename(title, index):
    """Convert title to safe filename: lowercase, hyphens, 3-digit prefix."""
    # Remove special characters
    filename = re.sub(r'[<>:"/\\|?*]', '', title)
    # Replace spaces and underscores with hyphens
    filename = filename.replace(' ', '-').replace('_', '-')
    # Convert to lowercase
    filename = filename.lower()
    # Remove multiple consecutive hyphens
    filename = re.sub(r'-+', '-', filename)
    # Remove leading/trailing hyphens
    filename = filename.strip('-')
    # Add 3-digit prefix
    return f"{index:03d}-{filename}.txt"

def save_fable(fable, output_dir, index):
    """Save a single fable to file."""
    filename = sanitize_filename(fable['title'], index)
    filepath = os.path.join(output_dir, filename)

    # Write with UTF-8 encoding
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(fable['text'])

    return filepath

def main():
    # Parse command line arguments
    if len(sys.argv) < 3:
        print("Usage: python split_aesop.py <input_file> <output_directory>")
        print("Example: python split_aesop.py aesop.txt ./articles/")
        sys.exit(1)

    input_file = sys.argv[1]
    output_dir = sys.argv[2]

    # Check input file
    if not os.path.exists(input_file):
        print(f"Error: Input file '{input_file}' not found.")
        sys.exit(1)

    # Create output directory if needed
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        print(f"Created directory: {output_dir}")

    # Read input file (try common encodings)
    content = None
    encodings = ['utf-8', 'utf-8-sig', 'latin-1', 'cp1252']

    for enc in encodings:
        try:
            with open(input_file, 'r', encoding=enc) as f:
                content = f.read()
            print(f"Read file using encoding: {enc}")
            break
        except UnicodeDecodeError:
            continue

    if content is None:
        print("Error: Could not read file with any encoding.")
        sys.exit(1)

    # Split into fables
    fables = split_fables(content)

    if not fables:
        print("No fables found. Check the file format.")
        sys.exit(1)

    # Save each fable
    print(f"\nFound {len(fables)} fables.")

    for i, fable in enumerate(fables, 1):
        filepath = save_fable(fable, output_dir, i)
        print(f"{i:3d}. {fable['title']} -> {os.path.basename(filepath)}")

    print(f"\nDone! {len(fables)} files saved to '{output_dir}'")

if __name__ == '__main__':
    main()
