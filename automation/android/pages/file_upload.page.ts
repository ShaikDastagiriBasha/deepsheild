class File_UploadPage {
    get container() { return $('~File_Upload_container'); }
    async waitForLoad() { await this.container.waitForDisplayed(); }
}
export default new File_UploadPage();
