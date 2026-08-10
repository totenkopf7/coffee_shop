import os

# ✅ Your project path
LIB_PATH = r"lib"

# ✅ Output file (will be created next to script)
 
OUTPUT_FILE = r"C:\Users/totenkopf\Desktop/coffee_shop.txt"

def dump_all_dart_files(lib_path, output_file):
    with open(output_file, "w", encoding="utf-8") as out:

        for root, dirs, files in os.walk(lib_path):
            files.sort()

            for file in files:
                if file.endswith(".dart"):
                    file_path = os.path.join(root, file)

                    # Include relative path (better for AI)
                    relative_path = os.path.relpath(file_path, lib_path)
                    out.write(f"\n// {relative_path}\n")

                    try:
                        with open(file_path, "r", encoding="utf-8") as f:
                            content = f.read()
                            out.write(content + "\n")
                    except Exception as e:
                        out.write(f"// ERROR reading file: {e}\n")


if __name__ == "__main__":
    if not os.path.exists(LIB_PATH):
        print(f"❌ Path not found: {LIB_PATH}")
    else:
        dump_all_dart_files(LIB_PATH, OUTPUT_FILE)
        print(f"✅ Done! File saved to:\n{OUTPUT_FILE}")