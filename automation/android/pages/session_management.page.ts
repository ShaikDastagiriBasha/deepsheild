class Session_ManagementPage {
    get container() { return $('~Session_Management_container'); }
    async waitForLoad() { await this.container.waitForDisplayed(); }
}
export default new Session_ManagementPage();
