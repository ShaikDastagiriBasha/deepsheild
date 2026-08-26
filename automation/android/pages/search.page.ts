class SearchPage {
    get container() { return $('~Search_container'); }
    async waitForLoad() { await this.container.waitForDisplayed(); }
}
export default new SearchPage();
