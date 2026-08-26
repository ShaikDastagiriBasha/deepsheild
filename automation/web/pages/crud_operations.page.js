const { By, until } = require('selenium-webdriver');

class CRUD_OperationsPage {
    constructor(driver) {
        this.driver = driver;
        this.container = By.id('crud_operations-container');
    }

    async waitForLoad() {
        await this.driver.wait(until.elementLocated(this.container), 10000);
    }
}
module.exports = CRUD_OperationsPage;
