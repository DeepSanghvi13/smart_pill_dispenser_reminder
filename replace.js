const fs = require('fs');
const path = require('path');

function walkDir(dir, callback) {
  fs.readdirSync(dir).forEach(f => {
    let dirPath = path.join(dir, f);
    let isDirectory = fs.statSync(dirPath).isDirectory();
    if (isDirectory) {
      walkDir(dirPath, callback);
    } else {
      if (dirPath.endsWith('.dart') || dirPath.endsWith('.md')) {
        callback(dirPath);
      }
    }
  });
}

function replaceInFile(filePath) {
  let content = fs.readFileSync(filePath, 'utf8');
  let original = content;
  
  content = content.replace(/PillDispenser/g, 'MedReminder');
  content = content.replace(/Pill Dispenser Reminder/ig, 'MedReminder');
  content = content.replace(/Pill Dispenser/ig, 'MedReminder');
  content = content.replace(/pill dispenser reminder/ig, 'MedReminder');
  content = content.replace(/pill dispenser/ig, 'MedReminder');
  
  if (content !== original) {
    fs.writeFileSync(filePath, content, 'utf8');
    console.log(`Updated: ${filePath}`);
  }
}

walkDir(path.join(__dirname, 'lib'), replaceInFile);
replaceInFile(path.join(__dirname, 'README.md'));
