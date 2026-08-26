class NavigationPage {
    get container() { return $('~Navigation_container'); }
    async waitForLoad() { await this.container.waitForDisplayed(); }
}
export default new NavigationPage();
