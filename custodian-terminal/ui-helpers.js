(() => {
  function byId(id) {
    return document.getElementById(id);
  }

  function clearChildren(node) {
    if (!node) return;
    while (node.firstChild) node.removeChild(node.firstChild);
  }

  function escapeHtml(text) {
    return String(text)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;");
  }

  function sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  function isAtBottom(node, threshold = 8) {
    if (!node) return true;
    return node.scrollTop + node.clientHeight >= node.scrollHeight - threshold;
  }

  window.CustodianUiHelpers = {
    byId,
    clearChildren,
    escapeHtml,
    sleep,
    isAtBottom,
  };
})();

