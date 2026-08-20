class LoginPage {
    get emailInput() { return $('~email_input'); }
    get passwordInput() { return $('~password_input'); }
    get loginButton() { return $('~login_button'); }
    get dashboardHeader() { return $('~dashboard_header'); }

    async login(email, password) {
        await this.emailInput.setValue(email);
        await this.passwordInput.setValue(password);
        await this.loginButton.click();
    }
}

export default new LoginPage();
