class CRUD_OperationsPage {
    get container() { return $('~CRUD_Operations_container'); }
    async waitForLoad() { await this.container.waitForDisplayed(); }
}
export default new CRUD_OperationsPage();
