class Input_ValidationPage {
    get container() { return $('~Input_Validation_container'); }
    async waitForLoad() { await this.container.waitForDisplayed(); }
}
export default new Input_ValidationPage();
