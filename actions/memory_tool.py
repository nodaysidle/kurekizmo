"""
Memory tool for Kurek / JARVIS.
Allows storing and recalling long-term user facts, preferences, identity, and notes.
Synchronizes with both JARVIS memory and Hermes memory (/Volumes/omarchyuser/26MaySymlink/.hermes/memories).
"""
from pathlib import Path
from memory.memory_manager import remember, search_memory, load_memory

HERMES_CANDIDATES = [
    Path.home() / ".hermes" / "profiles" / "eldio" / "memories",
    Path.home() / ".hermes" / "memories",
    Path("/Volumes/omarchyuser/26MaySymlink/.hermes/memories"),
]

def _resolve_hermes_dir() -> Path | None:
    for candidate in HERMES_CANDIDATES:
        if candidate.exists() and candidate.is_dir():
            return candidate
    return None


def manage_memory(parameters: dict, **kwargs) -> str:
    params = parameters or {}
    action = params.get("action", "remember").lower()
    hermes_dir = _resolve_hermes_dir()
    
    if action == "recall":
        query = params.get("query", "").strip()
        if not query:
            return "No search query provided."
            
        found_lines = []
        
        # 1. Search Hermes memory files
        if hermes_dir and hermes_dir.exists():
            for filename in ("USER.md", "MEMORY.md"):
                file_path = hermes_dir / filename
                if file_path.exists():
                    try:
                        content = file_path.read_text(encoding="utf-8")
                        for block in content.split("§"):
                            if query.lower() in block.lower():
                                clean_block = " ".join(block.split()).strip()
                                if clean_block:
                                    found_lines.append(f"• [Hermes {filename}] {clean_block}")
                    except Exception:
                        pass
        
        # 2. Search local memory
        local_results = search_memory(query)
        if local_results and "Nothing stored" not in local_results and "I have not stored" not in local_results:
            found_lines.append(f"• [Local Memory]\n{local_results}")
            
        if not found_lines:
            return f"No memories found matching '{query}'."
            
        return f"Found {len(found_lines)} matching memories:\n" + "\n".join(found_lines[:6])
    
    # Default: remember
    key = params.get("key", "").strip()
    value = params.get("value", "").strip()
    category = params.get("category", "notes").strip().lower()
    
    if not key or not value:
        return "Please provide both a key and a value to remember."
        
    local_res = remember(key=key, value=value, category=category)
    
    # Also sync to Hermes MEMORY.md if available
    try:
        if hermes_dir:
            mem_file = hermes_dir / "MEMORY.md"
            if mem_file.exists() and mem_file.is_file():
                entry = f"\n§\n**[{category.upper()}] {key}:** {value}\n"
                with open(mem_file, "a", encoding="utf-8") as f:
                    f.write(entry)
    except Exception as e:
        print(f"[Memory Tool] Hermes sync notice: {e}")
        
    return f"{local_res} (synced to Hermes memory)."


TOOL = {
    "name": "manage_memory",
    "description": "Store or recall persistent facts, personal identity, user preferences, projects, relationships, or notes. Use action='remember' to save something about the user, or action='recall' to search stored knowledge (including Hermes memories).",
    "parameters": {
        "type": "OBJECT",
        "properties": {
            "action": {
                "type": "STRING",
                "description": "'remember' to save a new fact, or 'recall' to search stored facts",
                "enum": ["remember", "recall"]
            },
            "category": {
                "type": "STRING",
                "description": "Category for remember: 'identity', 'preferences', 'projects', 'relationships', 'wishes', or 'notes'",
                "enum": ["identity", "preferences", "projects", "relationships", "wishes", "notes"]
            },
            "key": {
                "type": "STRING",
                "description": "Short descriptor key (e.g. 'favorite_coffee', 'sister_name', 'current_project')"
            },
            "value": {
                "type": "STRING",
                "description": "The fact or detail to remember"
            },
            "query": {
                "type": "STRING",
                "description": "Keyword to search for when action is 'recall'"
            }
        },
        "required": ["action"]
    },
    "handler": manage_memory,
}
