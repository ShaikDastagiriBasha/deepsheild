const { By, until } = require('selenium-webdriver');

class RegressionPage {
    constructor(driver) {
        this.driver = driver;
        this.container = By.id('regression-container');
    }

    async waitForLoad() {
        await this.driver.wait(until.elementLocated(this.container), 10000);
    }
}
module.exports = RegressionPage;
