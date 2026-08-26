class Error_HandlingPage {
    get container() { return $('~Error_Handling_container'); }
    async waitForLoad() { await this.container.waitForDisplayed(); }
}
export default new Error_HandlingPage();
