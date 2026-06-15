#!/usr/bin/env python3
import os
import sys
import subprocess
import json
import urllib.request
from urllib.error import URLError

# --- Configuration ---
LOCAL_LLM_URL = "http://localhost:8080/v1/chat/completions"
MAX_ITERATIONS = 3
SANDBOX_BRANCH = "agent-sandbox"
MAIN_BRANCH = "main" # Change this if your working branch is named differently

# The Soul of the Critic
CRITIC_SYSTEM_PROMPT = """You are a ruthless and precise Roblox Luau code auditor. 
Your singular goal is to prevent "AI slop", insecure client-authoritative movement, and unoptimized physics code.

STRICT DIRECTIVES:
1. EVERY file must start with `--!strict`.
2. `game:GetService()` must ONLY be at the top of the file.
3. NO `wait()`, `spawn()`, or `delay()`. Use the `task` library.
4. The client MUST NOT apply physics forces directly or dictate authoritative state.

If the code violates ANY rule, reply EXACTLY with "REJECT: [Your detailed reasoning]".
If the code is absolutely flawless, reply EXACTLY with "APPROVE"."""

# --- Terminal Colors ---
class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'

def print_step(msg):
    print(f"\n{Colors.BLUE}=== {msg} ==={Colors.ENDC}")

def print_success(msg):
    print(f"{Colors.GREEN}[+] {msg}{Colors.ENDC}")

def print_error(msg):
    print(f"{Colors.FAIL}[!] {msg}{Colors.ENDC}")

def print_warning(msg):
    print(f"{Colors.WARNING}[*] {msg}{Colors.ENDC}")

# --- Git Utilities ---
def run_cmd(command, ignore_errors=False):
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if result.returncode != 0 and not ignore_errors:
        print_error(f"Command failed: {command}\n{result.stderr}")
        sys.exit(1)
    return result.stdout.strip()

def setup_sandbox():
    print_step("Setting up Git Sandbox")
    run_cmd("git add .")
    run_cmd('git commit -m "WIP before agent loop"', ignore_errors=True)
    run_cmd(f"git checkout -B {SANDBOX_BRANCH}")
    print_success(f"Switched to isolated branch: {SANDBOX_BRANCH}")

def cleanup_sandbox(success):
    print_step("Cleaning up Workspace")
    run_cmd(f"git checkout {MAIN_BRANCH}")
    if success:
        run_cmd(f"git merge {SANDBOX_BRANCH}")
        print_success("Agent changes merged successfully!")
    else:
        print_error("Agent failed to produce approved code. Changes discarded.")
    run_cmd(f"git branch -D {SANDBOX_BRANCH}", ignore_errors=True)

# --- AI Agents ---
def run_antigravity(prompt):
    print_step("Invoking Antigravity CLI (Gemini 3.5 Flash)")
    print(f"Task: {prompt}")
    # Using 'agy' for Antigravity CLI. We pipe the output to terminal so you can watch it think.
    result = subprocess.run(f'agy "{prompt}"', shell=True)
    if result.returncode != 0:
        print_error("Antigravity CLI encountered an error.")
        return False
    return True

def get_modified_lua_files():
    status = run_cmd("git status --porcelain")
    files = []
    for line in status.split('\n'):
        if line and line.endswith('.lua'):
            # Extract file path from porcelain output (e.g., " M src/File.lua" -> "src/File.lua")
            filepath = line[3:]
            if os.path.exists(filepath):
                files.append(filepath)
    return files

def critique_code(filepath):
    print_step(f"Local Hermes Critic Auditing: {filepath}")
    
    with open(filepath, 'r', encoding='utf-8') as f:
        code_content = f.read()

    payload = {
        "messages": [
            {"role": "system", "content": CRITIC_SYSTEM_PROMPT},
            {"role": "user", "content": f"Review this Roblox Luau file:\n\n{code_content}"}
        ],
        "temperature": 0.0, # Zero variance for strict auditing
        "max_tokens": 500
    }

    try:
        req = urllib.request.Request(
            LOCAL_LLM_URL, 
            data=json.dumps(payload).encode('utf-8'),
            headers={'Content-Type': 'application/json'}
        )
        with urllib.request.urlopen(req) as response:
            result = json.loads(response.read().decode('utf-8'))
            critique = result['choices'][0]['message']['content'].strip()
            
            if critique.startswith("APPROVE"):
                print_success(f"Code Approved: {filepath}")
                return True, critique
            else:
                print_warning(f"Code Rejected:\n{critique}")
                return False, critique
    except URLError as e:
        print_error(f"Failed to connect to local llama.cpp server. Is it running on port 8080?\n{e}")
        sys.exit(1)

# --- Main Loop ---
def main():
    if len(sys.argv) < 2:
        print_error("Usage: python orchestrator.py \"Your prompt for the agent\"")
        sys.exit(1)
        
    initial_prompt = sys.argv[1]
    
    # 1. Isolate the workspace
    setup_sandbox()
    
    current_prompt = initial_prompt
    iteration = 1
    loop_successful = False

    # 2. Start the ReAct Loop
    while iteration <= MAX_ITERATIONS:
        print(f"\n{Colors.HEADER}=== LOOP ITERATION {iteration}/{MAX_ITERATIONS} ==={Colors.ENDC}")
        
        # Act
        if not run_antigravity(current_prompt):
            break

        # Observe
        modified_files = get_modified_lua_files()
        if not modified_files:
            print_error("Antigravity finished but no .lua files were modified.")
            break

        all_approved = True
        combined_feedback = []

        # Critique
        for file in modified_files:
            approved, feedback = critique_code(file)
            if not approved:
                all_approved = False
                combined_feedback.append(f"File {file} failed audit: {feedback}")

        # Resolve
        if all_approved:
            print_success("All files passed the local critic! Ready for Rojo sync.")
            loop_successful = True
            break
        else:
            print_warning("Critique failed. Formulating feedback for Antigravity...")
            feedback_prompt = "You modified some files, but the local code auditor rejected them. Fix the exact issues below:\n\n"
            feedback_prompt += "\n".join(combined_feedback)
            current_prompt = feedback_prompt
            
            # Undo the bad commit in the sandbox before retrying
            run_cmd("git reset --hard HEAD")
            iteration += 1

    # 3. Finalize
    if not loop_successful and iteration > MAX_ITERATIONS:
        print_error("Max iterations reached. The agent failed to produce compliant code.")
        
    cleanup_sandbox(success=loop_successful)

if __name__ == "__main__":
    main()