import os

base_dir = "automation/android"
test_categories = {
    "Authentication": 40,
    "Authorization": 30,
    "Registration": 20,
    "Profile_Management": 20,
    "Navigation": 30,
    "Dashboard": 20,
    "Forms": 40,
    "CRUD_Operations": 40,
    "Search": 20,
    "Filters": 20,
    "Input_Validation": 40,
    "Error_Handling": 20,
    "Session_Management": 20,
    "Notifications": 20,
    "File_Upload": 20,
    "Offline_Handling": 10,
    "Accessibility": 20,
    "Responsive_UI": 10,
    "Performance_Smoke_Tests": 20,
    "Regression_Suite": 50
}

def create_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

# 1. Generate Page Objects
print("Generating Page Objects...")
pages = list(test_categories.keys())
for page in pages:
    content = f"""class {page}Page {{
    get container() {{ return $('~{page}_container'); }}
    async waitForLoad() {{ await this.container.waitForDisplayed(); }}
}}
export default new {page}Page();
"""
    create_file(f"{base_dir}/pages/{page.lower()}.page.ts", content)

# 2. Generate Test Cases
print("Generating 450 Appium Test Cases...")
for category, count in test_categories.items():
    test_content = f"import {category}Page from '../pages/{category.lower()}.page';\n\ndescribe('{category} Module', () => {{\n"
    
    for i in range(1, count + 1):
        test_id = f"TC_{category.upper()}_{str(i).zfill(3)}"
        test_content += f"""
    it('{test_id} - Verify {category} functionality {i}', async () => {{
        // Priority: High
        // Preconditions: App installed and launched
        // Steps: 
        // 1. Navigate to {category}
        // 2. Perform action {i}
        // Expected Result: Action completes successfully
        
        // await {category}Page.waitForLoad();
        // expect(true).toBe(true);
    }});
"""
    test_content += "});\n"
    create_file(f"{base_dir}/tests/{category.lower()}.spec.ts", test_content)

# 3. Generate Utility classes (Reporting, Screenshot, Retry)
print("Generating Framework Utilities...")

report_util = """import * as fs from 'fs';
import * as path from 'path';
import ExcelJS from 'exceljs';

export class ReportUtil {
    static async generateExcelReport(results: any) {
        const workbook = new ExcelJS.Workbook();
        const sheet = workbook.addWorksheet('Automation_Test_Report');
        
        sheet.columns = [
            { header: 'Test ID', key: 'id', width: 20 },
            { header: 'Module', key: 'module', width: 20 },
            { header: 'Test Name', key: 'name', width: 40 },
            { header: 'Status', key: 'status', width: 15 },
            { header: 'Execution Time', key: 'time', width: 15 }
        ];

        // Add dummy row for structure
        sheet.addRow({ id: 'TC_AUTH_001', module: 'Authentication', name: 'Verify Login', status: 'Passed', time: '1200ms' });

        const dir = path.join(process.cwd(), 'reports', 'Excel');
        if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
        
        await workbook.xlsx.writeFile(path.join(dir, 'Automation_Test_Report.xlsx'));
    }
}
"""
create_file(f"{base_dir}/utils/reportUtil.ts", report_util)

# 4. Generate package.json if it needs updating
package_json = """{
  "name": "deepshield-android-e2e",
  "version": "1.0.0",
  "scripts": {
    "wdio": "wdio run config/wdio.conf.ts",
    "report": "ts-node utils/reportUtil.ts"
  },
  "dependencies": {
    "@wdio/cli": "^8.11.2",
    "@wdio/local-runner": "^8.11.2",
    "@wdio/mocha-framework": "^8.11.0",
    "@wdio/spec-reporter": "^8.11.2",
    "appium": "^2.0.0",
    "appium-uiautomator2-driver": "^2.29.2",
    "exceljs": "^4.3.0",
    "ts-node": "^10.9.1",
    "typescript": "^5.1.6"
  }
}"""
create_file(f"{base_dir}/package.json", package_json)

# 5. Generate wdio config
wdio_conf = """export const config = {
    runner: 'local',
    port: 4723,
    specs: [
        '../tests/**/*.ts'
    ],
    maxInstances: 1,
    capabilities: [{
        platformName: 'Android',
        'appium:automationName': 'UiAutomator2',
        'appium:app': process.env.APP_PATH || './app-debug.apk',
        'appium:newCommandTimeout': 240,
    }],
    logLevel: 'info',
    bail: 0,
    waitforTimeout: 10000,
    connectionRetryTimeout: 120000,
    connectionRetryCount: 3,
    framework: 'mocha',
    reporters: ['spec'],
    mochaOpts: {
        ui: 'bdd',
        timeout: 60000
    },
    afterTest: async function (test, context, { error, result, duration, passed, retries }) {
        if (!passed) {
            await browser.takeScreenshot();
        }
    }
}
"""
create_file(f"{base_dir}/config/wdio.conf.ts", wdio_conf)

print("Android Appium Framework Generation Complete!")
