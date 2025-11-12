#!/usr/bin/env node

const { getPostWithComments } = require('./src/comments');
const { formatPostToMarkdown, formatPostToJSON } = require('./src/formatter');
const { saveToFile, generateSafeFilename } = require('./src/fileHandler');

/**
 * 递归提取评论中的文本和作者信息
 * @param {Array} comments - 评论数组
 * @param {Array} result - 结果数组
 */
function extractComments(comments, result = []) {
  for (const comment of comments) {
    if (comment.deleted || comment.dead) continue;

    result.push({
      type: 'comment',
      by: comment.by,
      text: comment.text,
      time: comment.time
    });

    // 递归处理子评论
    if (comment.comments && comment.comments.length > 0) {
      extractComments(comment.comments, result);
    }
  }
  return result;
}

/**
 * 按时间顺序排序数据
 * @param {Object} post - 帖子数据
 * @returns {Array} 按时间排序的数组
 */
function createTimeline(post) {
  const timeline = [];

  // 添加帖子本身
  timeline.push({
    type: 'story',
    by: post.by,
    text: post.text,
    title: post.title,
    url: post.url,
    time: post.time
  });

  // 提取所有评论
  const comments = extractComments(post.comments);
  timeline.push(...comments);

  // 按时间排序
  timeline.sort((a, b) => a.time - b.time);

  return timeline;
}

/**
 * HackNews淘金程序主函数
 * @param {string|number} postId - HN帖子ID
 * @param {string} format - 输出格式 ('json' 或 'md')
 * @param {boolean} clean - 是否生成清洗后的数据
 */
async function scrapeHNPost(postId, format = 'json', clean = false) {
  try {
    console.log(`Fetching HN post with ID: ${postId}`);

    // 获取帖子和评论
    const post = await getPostWithComments(postId);
    console.log(`Successfully fetched post: ${post.title || 'Untitled'}`);

    // 格式化数据
    let formattedData;
    let fileExtension;

    if (format === 'md') {
      formattedData = formatPostToMarkdown(post);
      fileExtension = 'md';
    } else {
      formattedData = formatPostToJSON(post);
      fileExtension = 'json';
    }

    // 生成文件名
    const filename = generateSafeFilename(post.title || `hn-post-${postId}`);

    // 保存原始数据
    const filePath = await saveToFile(formattedData, filename, fileExtension);

    console.log(`Successfully saved data to ${filePath}`);

    // 如果需要清洗数据
    if (clean) {
      const cleanData = createTimeline(post);
      const cleanFilename = `${filename}-clean`;
      const cleanFormattedData = format === 'md' ?
        formatCleanDataToMarkdown(cleanData) :
        JSON.stringify(cleanData, null, 2);

      const cleanFilePath = await saveToFile(cleanFormattedData, cleanFilename, fileExtension);
      console.log(`Successfully saved clean data to ${cleanFilePath}`);
    }

    return filePath;
  } catch (error) {
    console.error('Error scraping HN post:', error.message);
    throw error;
  }
}

/**
 * 格式化清洗后的数据为Markdown
 * @param {Array} cleanData - 清洗后的数据
 * @returns {string} Markdown格式的字符串
 */
function formatCleanDataToMarkdown(cleanData) {
  let markdown = `# HN Post Discussion (Cleaned)\n\n`;

  for (const item of cleanData) {
    const time = new Date(item.time * 1000).toISOString().replace('T', ' ').substr(0, 19);

    if (item.type === 'story') {
      markdown += `## Story: ${item.title || 'Untitled'}\n`;
      markdown += `**Author**: ${item.by || 'Unknown'}  \n`;
      markdown += `**Posted**: ${time}  \n`;
      if (item.url) {
        markdown += `**URL**: [${item.url}](${item.url})  \n`;
      }
      if (item.text) {
        markdown += `\n${item.text}\n`;
      }
    } else {
      markdown += `### Comment by ${item.by || 'Unknown'} on ${time}\n`;
      if (item.text) {
        // 清理HTML标签
        let text = item.text.replace(/<p>/g, '\n').replace(/<\/p>/g, '\n');
        text = text.replace(/<i>/g, '*').replace(/<\/i>/g, '*');
        text = text.replace(/<b>/g, '**').replace(/<\/b>/g, '**');
        text = text.replace(/<a\s+href="([^"]+)">([^<]+)<\/a>/g, '[$2]($1)');
        text = text.replace(/<[^>]*>/g, '');
        markdown += `${text}\n`;
      }
    }

    markdown += '\n---\n\n';
  }

  return markdown;
}

// 命令行接口
async function main() {
  const args = process.argv.slice(2);

  if (args.length < 1) {
    console.log('Usage: node index.js <HN_POST_ID> [format] [clean]');
    console.log('Format: json (default) or md');
    console.log('Clean: --clean to generate cleaned data');
    console.log('Example: node index.js 123456 md --clean');
    process.exit(1);
  }

  const postId = args[0];
  const format = args[1] || 'json';
  const clean = args.includes('--clean');

  if (format !== 'json' && format !== 'md') {
    console.error('Invalid format. Use "json" or "md"');
    process.exit(1);
  }

  try {
    await scrapeHNPost(postId, format, clean);
    console.log('Scraping completed successfully!');
  } catch (error) {
    console.error('Scraping failed:', error.message);
    process.exit(1);
  }
}

// 如果直接运行此脚本，则执行main函数
if (require.main === module) {
  main();
}

module.exports = {
  scrapeHNPost,
  createTimeline,
  extractComments
};