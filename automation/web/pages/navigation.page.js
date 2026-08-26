const { By, until } = require('selenium-webdriver');

class NavigationPage {
    constructor(driver) {
        this.driver = driver;
        this.container = By.id('navigation-container');
    }

    async waitForLoad() {
        await this.driver.wait(until.elementLocated(this.container), 10000);
    }
}
module.exports = NavigationPage;
