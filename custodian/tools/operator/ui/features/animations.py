from ..actions import ANIMATION_ACTIONS
from ..service import WorkbenchService


class AnimationFeature:
    id = "animations"
    title = "Animations"
    key_binding = "1"

    def __init__(self, service: WorkbenchService) -> None:
        self.service = service
        self._records = []

    def refresh(self):
        self._records = self.service.browser_records()
        return self._records

    def build_navigation(self, query: str = ""):
        if not self._records: self.refresh()
        return self.service.filter_records(self._records, query)

    def build_detail(self, selection):
        return self.service.session(selection)

    def actions(self):
        return ANIMATION_ACTIONS
