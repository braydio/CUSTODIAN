"""Family/action_group/state navigation, driven entirely by the family contract.

Tree node data is a small tagged tuple rather than a bespoke identity type:
``("family", family_id)``, ``("group", family_id, action_group)``, or
``("state", family_id, state_id)``.
"""
from __future__ import annotations

from textual.message import Message
from textual.widgets import Tree

from ..state import FamilyProjection

TIER_MARK = {"required": "●", "recommended": "◐", "optional": "○"}


class FamilyTree(Tree[object]):
    class FamilySelected(Message):
        def __init__(self, family_id: str) -> None:
            super().__init__()
            self.family_id = family_id

    class StateSelected(Message):
        def __init__(self, family_id: str, state_id: str) -> None:
            super().__init__()
            self.family_id = family_id
            self.state_id = state_id

    def __init__(self) -> None:
        super().__init__("ASSET FAMILIES", id="family-tree")

    def _walk_nodes(self):
        pending = list(self.root.children)
        while pending:
            node = pending.pop(0)
            pending[0:0] = list(node.children)
            yield node

    def set_families(self, family_ids: list[str], active_family_id: str) -> None:
        self.root.remove_children()
        for family_id in family_ids:
            self.root.add(family_id, data=("family", family_id), expand=family_id == active_family_id)
        self.root.expand()

    def set_projection(self, projection: FamilyProjection) -> None:
        family_node = next((node for node in self.root.children if node.data == ("family", projection.family_id)), None)
        if family_node is None:
            return
        expanded = {node.data for node in self._walk_nodes() if isinstance(node.data, tuple) and node.data[0] == "group" and node.is_expanded}
        family_node.remove_children()
        for group_name, states in projection.groups:
            group_key = ("group", projection.family_id, group_name)
            group_node = family_node.add(group_name.upper(), data=group_key, expand=(not expanded) or group_key in expanded)
            for state in states:
                tier_mark = TIER_MARK.get(state.tier, "○")
                coverage_mark = "●" if state.art_present else "◐" if state.authored_directions or state.mirrored_directions else "✗"
                group_node.add_leaf(f"{tier_mark} {state.state_id}  {coverage_mark}", data=("state", projection.family_id, state.state_id))
        family_node.expand()

    def on_tree_node_selected(self, event: Tree.NodeSelected) -> None:
        data = event.node.data
        if not isinstance(data, tuple):
            return
        if data[0] == "state":
            self.post_message(self.StateSelected(data[1], data[2]))
        elif data[0] == "family":
            self.post_message(self.FamilySelected(data[1]))
