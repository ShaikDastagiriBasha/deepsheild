const { By, until } = require('selenium-webdriver');

class File_UploadPage {
    constructor(driver) {
        this.driver = driver;
        this.container = By.id('file_upload-container');
    }

    async waitForLoad() {
        await this.driver.wait(until.elementLocated(this.container), 10000);
    }
}
module.exports = File_UploadPage;
