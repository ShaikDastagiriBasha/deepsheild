const { By, until } = require('selenium-webdriver');

class LoginPage {
    constructor(driver) {
        this.driver = driver;
        this.emailInput = By.css('input[type="email"], #email');
        this.passwordInput = By.css('input[type="password"], #password');
        this.loginButton = By.xpath('//button[contains(text(),"Login") or contains(text(),"Sign In")]');
        this.dashboardHeader = By.xpath('//h1[contains(text(),"Dashboard")]');
    }

    async navigateTo(url) {
        await this.driver.get(url);
    }

    async login(email, password) {
        await this.driver.wait(until.elementLocated(this.emailInput), 10000);
        await this.driver.findElement(this.emailInput).sendKeys(email);
        await this.driver.findElement(this.passwordInput).sendKeys(password);
        await this.driver.findElement(this.loginButton).click();
    }

    async isDashboardVisible() {
        try {
            await this.driver.wait(until.elementLocated(this.dashboardHeader), 10000);
            return true;
        } catch (e) {
            return false;
        }
    }
}

module.exports = LoginPage;
