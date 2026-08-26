const { By, until } = require('selenium-webdriver');

class AccessibilityPage {
    constructor(driver) {
        this.driver = driver;
        this.container = By.id('accessibility-container');
    }

    async waitForLoad() {
        await this.driver.wait(until.elementLocated(this.container), 10000);
    }
}
module.exports = AccessibilityPage;
