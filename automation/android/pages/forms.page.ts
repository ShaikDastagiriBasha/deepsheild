class FormsPage {
    get container() { return $('~Forms_container'); }
    async waitForLoad() { await this.container.waitForDisplayed(); }
}
export default new FormsPage();
