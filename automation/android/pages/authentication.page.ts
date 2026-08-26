class AuthenticationPage {
    get container() { return $('~Authentication_container'); }
    async waitForLoad() { await this.container.waitForDisplayed(); }
}
export default new AuthenticationPage();
