const { By, until } = require('selenium-webdriver');

class Performance_Smoke_TestsPage {
    constructor(driver) {
        this.driver = driver;
        this.container = By.id('performance_smoke_tests-container');
    }

    async waitForLoad() {
        await this.driver.wait(until.elementLocated(this.container), 10000);
    }
}
module.exports = Performance_Smoke_TestsPage;
