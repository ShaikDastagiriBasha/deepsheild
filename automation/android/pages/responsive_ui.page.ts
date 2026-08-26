class Responsive_UIPage {
    get container() { return $('~Responsive_UI_container'); }
    async waitForLoad() { await this.container.waitForDisplayed(); }
}
export default new Responsive_UIPage();
