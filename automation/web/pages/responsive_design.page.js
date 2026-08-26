const { By, until } = require('selenium-webdriver');

class Responsive_DesignPage {
    constructor(driver) {
        this.driver = driver;
        this.container = By.id('responsive_design-container');
    }

    async waitForLoad() {
        await this.driver.wait(until.elementLocated(this.container), 10000);
    }
}
module.exports = Responsive_DesignPage;
