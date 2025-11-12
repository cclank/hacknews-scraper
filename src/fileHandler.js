const fs = require('fs-extra');
const path = require('path');

/**
 * 将数据保存到文件
 * @param {string} data - 要保存的数据
 * @param {string} filename - 文件名
 * @param {string} format - 文件格式 ('json' 或 'md')
 * @returns {Promise<string>} 保存的文件路径
 */
async function saveToFile(data, filename, format = 'json') {
  try {
    // 确保输出目录存在
    const outputDir = path.join(process.cwd(), 'output');
    await fs.ensureDir(outputDir);

    // 确定文件扩展名
    const extension = format === 'json' ? '.json' : '.md';
    const filePath = path.join(outputDir, `${filename}${extension}`);

    // 保存文件
    await fs.writeFile(filePath, data, 'utf8');

    console.log(`Data saved to ${filePath}`);
    return filePath;
  } catch (error) {
    console.error('Error saving file:', error.message);
    throw error;
  }
}

/**
 * 生成安全的文件名
 * @param {string} title - 原始标题
 * @returns {string} 安全的文件名
 */
function generateSafeFilename(title) {
  if (!title) return 'untitled';

  // 移除不安全的字符，只保留字母、数字、空格、连字符和下划线
  let safeName = title.replace(/[^a-zA-Z0-9\s\-_]/g, '');

  // 替换空格为下划线
  safeName = safeName.replace(/\s+/g, '_');

  // 限制长度
  if (safeName.length > 50) {
    safeName = safeName.substring(0, 50);
  }

  // 移除开头和结尾的下划线
  safeName = safeName.replace(/^_+|_+$/g, '');

  return safeName || 'untitled';
}

module.exports = {
  saveToFile,
  generateSafeFilename
};