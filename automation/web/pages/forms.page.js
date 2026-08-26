const { By, until } = require('selenium-webdriver');

class FormsPage {
    constructor(driver) {
        this.driver = driver;
        this.container = By.id('forms-container');
    }

    async waitForLoad() {
        await this.driver.wait(until.elementLocated(this.container), 10000);
    }
}
module.exports = FormsPage;
