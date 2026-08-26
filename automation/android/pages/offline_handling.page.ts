class Offline_HandlingPage {
    get container() { return $('~Offline_Handling_container'); }
    async waitForLoad() { await this.container.waitForDisplayed(); }
}
export default new Offline_HandlingPage();
