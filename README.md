# Export Copilot Chat Sessions

A simple tool to export and format your GitHub Copilot chat conversations from VS Code Web.

## What This Does

This tool helps you save your Copilot chat conversations as readable markdown files. It works in two steps:

1. **Extract** - Download your GitHub Copilot chat data from VS Code Web
2. **Export** - Convert the data into readable markdown files

---

## Step 1: Extract Your Chat Data

### Requirements
- Access to VS Code Web (vscode.dev or github.dev)
- An active GitHub Copilot subscription with chat history

### Instructions

1. **Open VS Code Web** in your browser (vscode.dev or github.dev)

2. **Open Developer Tools**
   - Press `F12` on your keyboard, OR
   - Right-click anywhere and select "Inspect", OR
   - Use the menu: `More Tools` → `Developer Tools`

3. **Open the Console Tab**
   - Click on the "Console" tab in the Developer Tools panel

4. **Copy and Paste the Script**
   - Open the file `extract-from-web-console.js`
   - Copy the entire contents of the file
   - Paste it into the Console and press Enter

5. **Download Starts Automatically**
   - A JSON file will download automatically
   - The filename will look like: `copilot_export_2026-02-02T14-30-45-123Z.json`
   - Save this file in the same folder as the `export-chat-from-json.sh` script

---

## Step 2: Export to Markdown

### Requirements
- A terminal or command line
- The JSON file from Step 1
- The `export-chat-from-json.sh` script

### List All Chat Sessions

To see all your chat sessions:

```bash
./export-chat-from-json.sh --list
```

This will show:
- Session ID (8-character identifier)
- Date of the conversation
- The first message from each session

### Export a Specific Session

To export a session to markdown:

```bash
./export-chat-from-json.sh --session <SESSION_ID>
```

Replace `<SESSION_ID>` with the 8-character ID from the list (e.g., `abc12345`).

This creates a markdown file named `<SESSION_ID>.md` with the full conversation.

### Custom Output Filename

To specify a different output filename:

```bash
./export-chat-from-json.sh --session <SESSION_ID> --output my-conversation.md
```

### Using a Specific JSON File

If you have multiple JSON exports it will include all of them by default. To specify a particular JSON file, use the `--file` option:

```bash
./export-chat-from-json.sh --file copilot_export_2026-02-02.json --list
./export-chat-from-json.sh --file copilot_export_2026-02-02.json --session <SESSION_ID>
```

---

## Privacy Note

All data extraction happens locally in your browser and on your computer. Nothing is sent to external servers.
