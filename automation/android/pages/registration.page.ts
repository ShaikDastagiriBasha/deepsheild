class RegistrationPage {
    get container() { return $('~Registration_container'); }
    async waitForLoad() { await this.container.waitForDisplayed(); }
}
export default new RegistrationPage();
