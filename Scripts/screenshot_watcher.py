import os
import time
import re
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from PIL import Image

# Path to the WoW Screenshots folder
SCREENSHOTS_DIR = r"C:\World of Warcraft - 1.12.1 - Microbot\Screenshots"

class TGAToJPGHandler(FileSystemEventHandler):
    def get_next_sequence_number(self):
        max_num = 0
        for filename in os.listdir(SCREENSHOTS_DIR):
            match = re.match(r"img-(\d+)\.jpg", filename)
            if match:
                num = int(match.group(1))
                if num > max_num:
                    max_num = num
        return max_num + 1

    def process_tga(self, tga_path):
        try:
            # Wait a tiny bit to ensure the file is fully written by WoW
            time.sleep(0.5)
            
            # Generate the new filename
            seq_num = self.get_next_sequence_number()
            jpg_filename = f"img-{seq_num:02d}.jpg"
            jpg_path = os.path.join(SCREENSHOTS_DIR, jpg_filename)
            
            # Convert TGA to JPG
            with Image.open(tga_path) as img:
                # Convert to RGB mode if necessary (TGA can have alpha channel)
                if img.mode != 'RGB':
                    img = img.convert('RGB')
                img.save(jpg_path, "JPEG", quality=90)
                
            print(f"Converted: {os.path.basename(tga_path)} -> {jpg_filename}")
            
            # Delete original TGA
            os.remove(tga_path)
            print(f"Deleted: {os.path.basename(tga_path)}")
            
        except Exception as e:
            print(f"Error processing {tga_path}: {e}")

    def on_created(self, event):
        if event.is_directory:
            return
        if event.src_path.lower().endswith(".tga"):
            self.process_tga(event.src_path)

if __name__ == "__main__":
    print(f"Watching {SCREENSHOTS_DIR} for new .tga files...")
    
    # First, process any existing TGAs that were missed before script started
    for filename in os.listdir(SCREENSHOTS_DIR):
        if filename.lower().endswith(".tga"):
            handler = TGAToJPGHandler()
            handler.process_tga(os.path.join(SCREENSHOTS_DIR, filename))
            
    # Then start watching the directory
    event_handler = TGAToJPGHandler()
    observer = Observer()
    observer.schedule(event_handler, SCREENSHOTS_DIR, recursive=False)
    observer.start()
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()
