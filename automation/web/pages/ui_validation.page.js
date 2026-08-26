const { By, until } = require('selenium-webdriver');

class UI_ValidationPage {
    constructor(driver) {
        this.driver = driver;
        this.container = By.id('ui_validation-container');
    }

    async waitForLoad() {
        await this.driver.wait(until.elementLocated(this.container), 10000);
    }
}
module.exports = UI_ValidationPage;
