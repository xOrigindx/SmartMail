import os
import shutil

source_file = r"C:\World of Warcraft - 1.12.1 - Microbot\Interface\AddOns\SmartMail\.agents\API_MANUAL.md"
skills_dir = r"C:\Users\OriginD\.gemini\antigravity-cli\skills"
target_file = os.path.join(skills_dir, "wow_vanilla_api.md")

if not os.path.exists(skills_dir):
    os.makedirs(skills_dir)

yaml_header = """---
name: wow_vanilla_api
description: Comprehensive API reference, UI quirks, and function signatures for World of Warcraft 1.12.1 (Vanilla). Use this skill whenever working on Vanilla WoW AddOns to understand XML behavior, UI templates, and Client engine methods.
---

"""

with open(source_file, "r", encoding="utf-8") as src:
    content = src.read()

with open(target_file, "w", encoding="utf-8") as dst:
    dst.write(yaml_header + content)

print(f"Successfully created global skill at: {target_file}")
