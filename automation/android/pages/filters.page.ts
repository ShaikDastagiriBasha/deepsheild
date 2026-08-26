class FiltersPage {
    get container() { return $('~Filters_container'); }
    async waitForLoad() { await this.container.waitForDisplayed(); }
}
export default new FiltersPage();
