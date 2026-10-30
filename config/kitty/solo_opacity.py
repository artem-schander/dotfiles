# Make the kitty background opaque while it is the only visible tiled window
# on its i3 workspace, and restore background_opacity otherwise.
import json
import subprocess
from typing import Any

from kitty.boss import Boss
from kitty.fast_data_types import change_background_opacity, get_options, x11_window_id
from kitty.window import Window


def visible_windows(node: dict[str, Any]) -> list[int]:
    # Leaf containers that are actually on screen; in tabbed/stacked
    # containers only the focused child is visible.
    if node.get('window'):
        return [node['window']]
    children = node.get('nodes', [])
    if node.get('layout') in ('tabbed', 'stacked') and node.get('focus'):
        children = [c for c in children if c['id'] == node['focus'][0]]
    return [w for c in children for w in visible_windows(c)]


def find_workspace(node: dict[str, Any], xid: int, ws: dict[str, Any] | None = None) -> dict[str, Any] | None:
    if node.get('type') == 'workspace':
        ws = node
    if node.get('window') == xid:
        return ws
    for c in node.get('nodes', []) + node.get('floating_nodes', []):
        if (found := find_workspace(c, xid, ws)) is not None:
            return found
    return None


def is_alone(os_window_id: int) -> bool:
    try:
        tree = json.loads(subprocess.run(
            ['i3-msg', '-t', 'get_tree'], capture_output=True, text=True, timeout=1,
        ).stdout)
    except Exception:
        return False
    xid = x11_window_id(os_window_id)
    ws = find_workspace(tree, xid)
    return ws is not None and visible_windows(ws) == [xid]


def on_resize(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    os_window_id = window.os_window_id
    opacity = 1.0 if is_alone(os_window_id) else get_options().background_opacity
    change_background_opacity(os_window_id, opacity)
