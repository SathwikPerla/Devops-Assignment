#!/usr/bin/env python3
import sys
import subprocess
import os

SCRIPT_DIR = os.path.expanduser("~/.gemini/config/skills/k8s-lab-pipeline/scripts/render_terminal_screenshot.py")

def run_and_capture(cmd, output_png, current_dir="session-13-storage-hpa-probes", height=320):
    print(f"==> Running: {cmd}")
    res = subprocess.run(cmd, shell=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    output_text = res.stdout
    print(output_text)
    
    # Calculate appropriate height based on lines of output
    line_count = len(output_text.splitlines())
    auto_height = max(height, min(800, 100 + line_count * 24))
    
    # Render screenshot
    subprocess.run([
        "python3", SCRIPT_DIR,
        "--command", cmd,
        "--output-text", output_text,
        "--output", output_png,
        "--height", str(auto_height),
        "--dir", current_dir
    ], check=True)
    print(f"==> Saved screenshot to: {output_png}\n")
    return output_text

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 run_and_screenshot.py '<cmd>' '<output_png>' [dir] [height]")
        sys.exit(1)
    cmd = sys.argv[1]
    out_png = sys.argv[2]
    d = sys.argv[3] if len(sys.argv) > 3 else "session-13-storage-hpa-probes"
    h = int(sys.argv[4]) if len(sys.argv) > 4 else 320
    run_and_capture(cmd, out_png, d, h)
