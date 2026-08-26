class Profile_ManagementPage {
    get container() { return $('~Profile_Management_container'); }
    async waitForLoad() { await this.container.waitForDisplayed(); }
}
export default new Profile_ManagementPage();
