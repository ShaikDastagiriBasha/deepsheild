const { By, until } = require('selenium-webdriver');

class AuthorizationPage {
    constructor(driver) {
        this.driver = driver;
        this.container = By.id('authorization-container');
    }

    async waitForLoad() {
        await this.driver.wait(until.elementLocated(this.container), 10000);
    }
}
module.exports = AuthorizationPage;
