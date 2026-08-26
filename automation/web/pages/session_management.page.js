const { By, until } = require('selenium-webdriver');

class Session_ManagementPage {
    constructor(driver) {
        this.driver = driver;
        this.container = By.id('session_management-container');
    }

    async waitForLoad() {
        await this.driver.wait(until.elementLocated(this.container), 10000);
    }
}
module.exports = Session_ManagementPage;
