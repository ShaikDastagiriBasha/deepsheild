class AuthorizationPage {
    get container() { return $('~Authorization_container'); }
    async waitForLoad() { await this.container.waitForDisplayed(); }
}
export default new AuthorizationPage();
