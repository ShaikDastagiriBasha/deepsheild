const ExcelJS = require('exceljs');
const fs = require('fs');
const path = require('path');

async function generateExcelReport() {
    const reportPath = path.join(__dirname, '../reports/excel');
    if (!fs.existsSync(reportPath)) {
        fs.mkdirSync(reportPath, { recursive: true });
    }

    const workbook = new ExcelJS.Workbook();
    const sheet = workbook.addWorksheet('Automation_Test_Report');
    
    sheet.columns = [
        { header: 'Test ID', key: 'id', width: 15 },
        { header: 'Module', key: 'module', width: 20 },
        { header: 'Test Name', key: 'name', width: 35 },
        { header: 'Status', key: 'status', width: 15 },
        { header: 'Execution Time', key: 'time', width: 15 }
    ];

    sheet.addRow({ id: 'TC_AUTH_001', module: 'Authentication', name: 'Valid Login', status: 'Passed', time: '2s' });
    
    const filePath = path.join(reportPath, 'Automation_Test_Report.xlsx');
    await workbook.xlsx.writeFile(filePath);
    console.log('Excel Report generated at: ' + filePath);
}

generateExcelReport();
