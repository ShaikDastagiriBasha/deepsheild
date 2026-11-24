const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

function crc32(buf) {
    let table = new Int32Array(256);
    for (let i = 0; i < 256; i++) {
        let c = i;
        for (let k = 0; k < 8; k++) c = ((c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1));
        table[i] = c;
    }
    let crc = -1;
    for (let i = 0; i < buf.length; i++) crc = (crc >>> 8) ^ table[(crc ^ buf[i]) & 0xFF];
    return (crc ^ (-1)) >>> 0;
}

function createZip(files) {
    let fileEntries = [];
    let centralDirEntries = [];
    let offset = 0;

    for (let file of files) {
        let nameBuf = Buffer.from(file.name, 'utf8');
        let dataBuf = Buffer.isBuffer(file.data) ? file.data : Buffer.from(file.data, 'utf8');
        let crc = crc32(dataBuf);
        let uncompressedSize = dataBuf.length;
        let compressedData = zlib.deflateRawSync(dataBuf);
        let compressedSize = compressedData.length;

        // Local header
        let localHeader = Buffer.alloc(30 + nameBuf.length);
        localHeader.writeUInt32LE(0x04034b50, 0); // sig
        localHeader.writeUInt16LE(20, 4); // version needed
        localHeader.writeUInt16LE(0, 6); // flags
        localHeader.writeUInt16LE(8, 8); // compression: deflate
        localHeader.writeUInt16LE(0, 10); // mod time
        localHeader.writeUInt16LE(0, 12); // mod date
        localHeader.writeUInt32LE(crc, 14); // crc32
        localHeader.writeUInt32LE(compressedSize, 18);
        localHeader.writeUInt32LE(uncompressedSize, 22);
        localHeader.writeUInt16LE(nameBuf.length, 26);
        localHeader.writeUInt16LE(0, 28);
        nameBuf.copy(localHeader, 30);

        fileEntries.push(localHeader, compressedData);

        // Central dir header
        let cdHeader = Buffer.alloc(46 + nameBuf.length);
        cdHeader.writeUInt32LE(0x02014b50, 0);
        cdHeader.writeUInt16LE(20, 4); // version made by
        cdHeader.writeUInt16LE(20, 6); // version needed
        cdHeader.writeUInt16LE(0, 8); // flags
        cdHeader.writeUInt16LE(8, 10); // deflate
        cdHeader.writeUInt16LE(0, 12);
        cdHeader.writeUInt16LE(0, 14);
        cdHeader.writeUInt32LE(crc, 16);
        cdHeader.writeUInt32LE(compressedSize, 20);
        cdHeader.writeUInt32LE(uncompressedSize, 24);
        cdHeader.writeUInt16LE(nameBuf.length, 28);
        cdHeader.writeUInt16LE(0, 30);
        cdHeader.writeUInt16LE(0, 32);
        cdHeader.writeUInt16LE(0, 34);
        cdHeader.writeUInt16LE(0, 36);
        cdHeader.writeUInt32LE(0, 38);
        cdHeader.writeUInt32LE(offset, 42);
        nameBuf.copy(cdHeader, 46);

        centralDirEntries.push(cdHeader);
        offset += localHeader.length + compressedData.length;
    }

    let centralDirOffset = offset;
    let centralDirSize = centralDirEntries.reduce((acc, b) => acc + b.length, 0);

    let endOfCentralDir = Buffer.alloc(22);
    endOfCentralDir.writeUInt32LE(0x06054b50, 0);
    endOfCentralDir.writeUInt16LE(0, 4);
    endOfCentralDir.writeUInt16LE(0, 6);
    endOfCentralDir.writeUInt16LE(files.length, 8);
    endOfCentralDir.writeUInt16LE(files.length, 10);
    endOfCentralDir.writeUInt32LE(centralDirSize, 12);
    endOfCentralDir.writeUInt32LE(centralDirOffset, 16);
    endOfCentralDir.writeUInt16LE(0, 20);

    return Buffer.concat([...fileEntries, ...centralDirEntries, endOfCentralDir]);
}

function escapeXml(str) {
    if (str === null || str === undefined) return '';
    return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&apos;');
}

function colToLetter(colIndex) {
    let letter = '';
    while (colIndex >= 0) {
        letter = String.fromCharCode((colIndex % 26) + 65) + letter;
        colIndex = Math.floor(colIndex / 26) - 1;
    }
    return letter;
}

function buildWorksheetXml(rows) {
    let xml = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>`;
    for (let r = 0; r < rows.length; r++) {
        let rowNum = r + 1;
        xml += `<row r="${rowNum}">`;
        let row = rows[r];
        for (let c = 0; c < row.length; c++) {
            let val = row[c];
            let cellRef = `${colToLetter(c)}${rowNum}`;
            if (typeof val === 'number') {
                xml += `<c r="${cellRef}"><v>${val}</v></c>`;
            } else {
                xml += `<c r="${cellRef}" t="inlineStr"><is><t>${escapeXml(val)}</t></is></c>`;
            }
        }
        xml += `</row>`;
    }
    xml += `</sheetData></worksheet>`;
    return xml;
}

function createWorkbookXlsx(sheets) {
    // sheets is an array of { name: 'SheetName', rows: [ [col1, col2], ... ] }
    let files = [];

    // [Content_Types].xml
    let contentTypes = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>`;

    // xl/workbook.xml
    let workbookXml = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>`;

    // xl/_rels/workbook.xml.rels
    let wbRelsXml = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">`;

    for (let i = 0; i < sheets.length; i++) {
        let sheet = sheets[i];
        let sheetIdx = i + 1;
        let sheetPath = `xl/worksheets/sheet${sheetIdx}.xml`;
        contentTypes += `\n  <Override PartName="/${sheetPath}" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>`;
        workbookXml += `\n    <sheet name="${escapeXml(sheet.name)}" sheetId="${sheetIdx}" r:id="rId${sheetIdx}"/>`;
        wbRelsXml += `\n  <Relationship Id="rId${sheetIdx}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet${sheetIdx}.xml"/>`;

        files.push({
            name: sheetPath,
            data: buildWorksheetXml(sheet.rows)
        });
    }

    contentTypes += `\n</Types>`;
    workbookXml += `\n  </sheets>\n</workbook>`;
    wbRelsXml += `\n</Relationships>`;

    // _rels/.rels
    let rootRels = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>`;

    files.push({ name: '[Content_Types].xml', data: contentTypes });
    files.push({ name: '_rels/.rels', data: rootRels });
    files.push({ name: 'xl/workbook.xml', data: workbookXml });
    files.push({ name: 'xl/_rels/workbook.xml.rels', data: wbRelsXml });

    return createZip(files);
}

function writeExcelFile(filePath, sheets) {
    const dir = path.dirname(filePath);
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }
    const buffer = createWorkbookXlsx(sheets);
    fs.writeFileSync(filePath, buffer);
}

module.exports = {
    createWorkbookXlsx,
    writeExcelFile
};
