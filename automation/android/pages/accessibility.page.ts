class AccessibilityPage {
    get container() { return $('~Accessibility_container'); }
    async waitForLoad() { await this.container.waitForDisplayed(); }
}
export default new AccessibilityPage();
