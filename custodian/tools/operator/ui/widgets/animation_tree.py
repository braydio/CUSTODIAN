from textual.message import Message
from textual.widgets import Tree

from ..state import AnimationRecord, AnimationSelection


class AnimationTree(Tree[str]):
    class Selected(Message):
        def __init__(self, selection: AnimationSelection) -> None:
            super().__init__(); self.selection = selection

    def __init__(self, records: list[AnimationRecord] | None = None) -> None:
        super().__init__("ANIMATIONS", id="animation-tree")
        self._records = records or []

    def set_records(self, records: list[AnimationRecord]) -> None:
        self._records = records
        self.root.remove_children()
        profiles, groups, actions = {}, {}, {}
        for record in records:
            selected = record.selection
            profile = profiles.setdefault(selected.profile, self.root.add(selected.profile, expand=True))
            group = groups.setdefault((selected.profile, selected.group), profile.add(selected.group, expand=True))
            action = actions.setdefault((selected.profile, selected.group, selected.action), group.add(selected.action, expand=True))
            action.add_leaf(record.summary, data=selected)
        self.root.expand()

    def select_identity(self, selection: AnimationSelection) -> bool:
        pending = list(self.root.children)
        while pending:
            node = pending.pop(0); pending[0:0] = list(node.children)
            if isinstance(node.data, AnimationSelection) and (
                node.data.profile, node.data.group, node.data.action, node.data.direction
            ) == (selection.profile, selection.group, selection.action, selection.direction):
                node.data = selection
                self.select_node(node); node.expand_all(); return True
        return False

    def on_tree_node_selected(self, event: Tree.NodeSelected[str]) -> None:
        if isinstance(event.node.data, AnimationSelection):
            self.post_message(self.Selected(event.node.data))
