import * as fs from 'fs';
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
