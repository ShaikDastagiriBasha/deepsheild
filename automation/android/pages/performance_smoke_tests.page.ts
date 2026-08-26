class Performance_Smoke_TestsPage {
    get container() { return $('~Performance_Smoke_Tests_container'); }
    async waitForLoad() { await this.container.waitForDisplayed(); }
}
export default new Performance_Smoke_TestsPage();
