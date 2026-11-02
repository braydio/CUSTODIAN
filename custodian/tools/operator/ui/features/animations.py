from ..actions import ANIMATION_ACTIONS
from ..service import WorkbenchService


class AnimationFeature:
    id = "animations"
    title = "Animations"
    key_binding = "1"

    def __init__(self, service: WorkbenchService) -> None:
        self.service = service

    def refresh(self):
        """Return a discovery candidate without retaining mutable browser state."""
        discover = getattr(self.service, "discover_browser_records", None)
        if discover is None:
            discover = self.service.browser_records
        return tuple(discover())

    def build_navigation(self, records, query: str = "", *, show_superseded: bool = False):
        return self.service.filter_records(records, query, show_superseded=show_superseded)

    def build_detail(self, selection):
        return self.service.session(selection)

    def actions(self):
        return ANIMATION_ACTIONS
