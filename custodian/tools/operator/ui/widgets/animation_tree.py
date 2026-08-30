from textual.message import Message
from textual.widgets import Tree

from ..state import AnimationRecord, AnimationSelection


class AnimationTree(Tree[object]):
    class Selected(Message):
        def __init__(self, selection: AnimationSelection) -> None:
            super().__init__(); self.selection = selection

    def __init__(self, records: list[AnimationRecord] | None = None) -> None:
        super().__init__("ANIMATIONS", id="animation-tree")
        self._records = records or []

    def set_records(self, records: list[AnimationRecord]) -> None:
        expanded = {
            node.data for node in self._walk_nodes()
            if isinstance(node.data, tuple) and node.is_expanded
        }
        self._records = records
        self.root.remove_children()
        profiles, groups, actions = {}, {}, {}
        for record in records:
            selected = record.selection
            profile_key = (selected.profile,)
            profile = profiles.get(selected.profile)
            if profile is None:
                profile = self.root.add(selected.profile, data=profile_key, expand=profile_key in expanded)
                profiles[selected.profile] = profile
            group_key = (selected.profile, selected.group)
            group = groups.get(group_key)
            if group is None:
                group = profile.add(selected.group, data=group_key, expand=group_key in expanded)
                groups[group_key] = group
            action_key = (selected.profile, selected.group, selected.action)
            action = actions.get(action_key)
            if action is None:
                action = group.add(selected.action, data=action_key, expand=action_key in expanded)
                actions[action_key] = action
            action.add_leaf(record.summary, data=selected)
        self.root.expand()

    def _walk_nodes(self):
        pending = list(self.root.children)
        while pending:
            node = pending.pop(0)
            pending[0:0] = list(node.children)
            yield node

    def select_identity(self, selection: AnimationSelection) -> bool:
        for node in self._walk_nodes():
            if isinstance(node.data, AnimationSelection) and (
                node.data.profile, node.data.group, node.data.action, node.data.direction
            ) == (selection.profile, selection.group, selection.action, selection.direction):
                node.data = selection
                ancestor = node.parent
                while ancestor is not None:
                    ancestor.expand(); ancestor = ancestor.parent
                self.select_node(node)
                return True
        return False

    def on_tree_node_selected(self, event: Tree.NodeSelected[str]) -> None:
        if isinstance(event.node.data, AnimationSelection):
            self.post_message(self.Selected(event.node.data))
