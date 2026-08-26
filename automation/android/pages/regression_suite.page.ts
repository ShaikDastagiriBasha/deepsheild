class Regression_SuitePage {
    get container() { return $('~Regression_Suite_container'); }
    async waitForLoad() { await this.container.waitForDisplayed(); }
}
export default new Regression_SuitePage();
