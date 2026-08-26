const { By, until } = require('selenium-webdriver');

class AuthenticationPage {
    constructor(driver) {
        this.driver = driver;
        this.container = By.id('authentication-container');
    }

    async waitForLoad() {
        await this.driver.wait(until.elementLocated(this.container), 10000);
    }
}
module.exports = AuthenticationPage;
