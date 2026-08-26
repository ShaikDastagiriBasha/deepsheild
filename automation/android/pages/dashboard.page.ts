class DashboardPage {
    get container() { return $('~Dashboard_container'); }
    async waitForLoad() { await this.container.waitForDisplayed(); }
}
export default new DashboardPage();
