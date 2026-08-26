const { By, until } = require('selenium-webdriver');

class Error_HandlingPage {
    constructor(driver) {
        this.driver = driver;
        this.container = By.id('error_handling-container');
    }

    async waitForLoad() {
        await this.driver.wait(until.elementLocated(this.container), 10000);
    }
}
module.exports = Error_HandlingPage;
