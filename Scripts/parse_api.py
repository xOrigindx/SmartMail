import os
import glob

def parse_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    constants = []
    functions = []
    
    for line in lines:
        line = line.strip()
        if not line or line.startswith("---") or line == "---@meta":
            continue
            
        if line.startswith("function "):
            # Strip out "function " and " end"
            func_sig = line[9:]
            if func_sig.endswith(" end"):
                func_sig = func_sig[:-4]
            functions.append(f"- `{func_sig}`")
        elif "=" in line:
            # Clean up the type annotations like " = nil---@type nil"
            clean_line = line.split("---@")[0].strip()
            constants.append(f"- `{clean_line}`")
        # In the Client folder, methods might be defined like:
        # EditBox:GetText()
        elif ":" in line and not line.startswith("local ") and "function" not in line and not line.startswith("--") and "(" in line and line.endswith(")"):
            # Like: "UIObject:GetName()"
            functions.append(f"- `{line}`")

    if not constants and not functions:
        return ""
        
    basename = os.path.basename(filepath)
    # Also add parent dir for context since Client has subdirs
    parent_dir = os.path.basename(os.path.dirname(filepath))
    output = [f"### {parent_dir}/{basename}"]
    if constants:
        output.append("\n**Constants:**")
        output.extend(constants)
    if functions:
        output.append("\n**Functions:**")
        output.extend(functions)
        
    return "\n".join(output)

directory = r"C:\World of Warcraft - 1.12.1 - Microbot\Interface\AddOns\SmartMail\docs\References\type-definitions\Client"
output_file = r"C:\World of Warcraft - 1.12.1 - Microbot\Interface\AddOns\SmartMail\.agents\API_MANUAL.md"

files = glob.glob(os.path.join(directory, "**", "*.d.lua"), recursive=True)
files.sort()

all_outputs = []
all_outputs.append("## Vanilla Client Core API Index")
all_outputs.append("The following is an auto-generated index of all Vanilla Core API functions pulled from `docs/References/type-definitions/Client/`.")

for file in files:
    res = parse_file(file)
    if res:
        all_outputs.append(res)
        
full_text = "\n\n" + "\n\n".join(all_outputs) + "\n"

with open(output_file, "a", encoding="utf-8") as f:
    f.write(full_text)
    
print(f"Successfully processed {len(files)} files in Client folder and appended to API_MANUAL.md")
