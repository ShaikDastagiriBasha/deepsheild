class NotificationsPage {
    get container() { return $('~Notifications_container'); }
    async waitForLoad() { await this.container.waitForDisplayed(); }
}
export default new NotificationsPage();
