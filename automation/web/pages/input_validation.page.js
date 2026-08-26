const { By, until } = require('selenium-webdriver');

class Input_ValidationPage {
    constructor(driver) {
        this.driver = driver;
        this.container = By.id('input_validation-container');
    }

    async waitForLoad() {
        await this.driver.wait(until.elementLocated(this.container), 10000);
    }
}
module.exports = Input_ValidationPage;
