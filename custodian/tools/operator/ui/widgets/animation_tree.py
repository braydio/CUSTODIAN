from textual.message import Message
from textual.widgets import Tree

from ..state import AnimationRecord, AnimationSelection


class AnimationTree(Tree[object]):
    class Selected(Message):
        def __init__(self, selection: AnimationSelection) -> None:
            super().__init__(); self.selection = selection

    def __init__(self, records: list[AnimationRecord] | None = None) -> None:
        super().__init__("OPERATOR ANIMATIONS", id="animation-tree")
        self._records = records or []
        self._silent_selection_identity = ""

    def set_records(self, records: list[AnimationRecord]) -> None:
        expanded = {
            node.data for node in self._walk_nodes()
            if isinstance(node.data, tuple) and node.is_expanded
        }
        self._records = records
        self.root.remove_children()
        generations, profiles, groups, actions = {}, {}, {}, {}
        for record in records:
            selected = record.selection
            generation_key = (selected.art_generation,)
            generation = generations.get(generation_key)
            if generation is None:
                label = "LEGACY 96" if selected.art_generation == "legacy_96" else "2.5D 128"
                generation = self.root.add(label, data=generation_key, expand=generation_key in expanded)
                generations[generation_key] = generation
            profile_key = (selected.art_generation, selected.profile)
            profile = profiles.get(profile_key)
            if profile is None:
                profile = generation.add(selected.profile, data=profile_key, expand=profile_key in expanded)
                profiles[profile_key] = profile
            group_key = (selected.art_generation, selected.profile, selected.group)
            group = groups.get(group_key)
            if group is None:
                group = profile.add(selected.group, data=group_key, expand=group_key in expanded)
                groups[group_key] = group
            action_key = (selected.art_generation, selected.profile, selected.group, selected.action)
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
                node.data.authoring_identity == selection.authoring_identity
            ):
                node.data = selection
                ancestor = node.parent
                while ancestor is not None:
                    ancestor.expand(); ancestor = ancestor.parent
                self._silent_selection_identity = selection.authoring_identity
                self.select_node(node)
                return True
        return False

    def on_tree_node_selected(self, event: Tree.NodeSelected[str]) -> None:
        if isinstance(event.node.data, AnimationSelection):
            if event.node.data.authoring_identity == self._silent_selection_identity:
                self._silent_selection_identity = ""
                return
            self.post_message(self.Selected(event.node.data))
