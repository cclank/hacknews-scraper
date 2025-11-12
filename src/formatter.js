const fs = require('fs-extra');

/**
 * 将时间戳转换为可读格式
 * @param {number} timestamp - Unix时间戳
 * @returns {string} 格式化的时间字符串
 */
function formatTime(timestamp) {
  if (!timestamp) return 'Unknown';
  const date = new Date(timestamp * 1000);
  return date.toISOString().replace('T', ' ').substr(0, 19);
}

/**
 * 格式化帖子数据为Markdown
 * @param {Object} post - 帖子数据
 * @returns {string} Markdown格式的字符串
 */
function formatPostToMarkdown(post) {
  let markdown = `# ${post.title || 'Untitled'}\n\n`;

  // 帖子元数据
  markdown += `**Author**: ${post.by || 'Unknown'}  \n`;
  markdown += `**Posted**: ${formatTime(post.time)}  \n`;
  markdown += `**Score**: ${post.score || 0}  \n`;
  markdown += `**Comments**: ${post.descendants || 0}  \n`;
  if (post.url) {
    markdown += `**URL**: [${post.url}](${post.url})  \n`;
  }
  markdown += '\n---\n\n';

  // 帖子正文
  if (post.text) {
    markdown += `${post.text}\n\n`;
    markdown += '---\n\n';
  }

  // 评论部分
  markdown += `## Comments (${post.comments.length})\n\n`;
  markdown += formatCommentsToMarkdown(post.comments, 0);

  return markdown;
}

/**
 * 递归格式化评论为Markdown
 * @param {Array} comments - 评论数组
 * @param {number} level - 当前层级
 * @returns {string} Markdown格式的评论字符串
 */
function formatCommentsToMarkdown(comments, level = 0) {
  let markdown = '';

  for (const comment of comments) {
    if (comment.deleted) continue;

    const indent = '  '.repeat(level);
    markdown += `${indent}### Comment by ${comment.by || 'Unknown'} on ${formatTime(comment.time)}\n\n`;

    if (comment.text) {
      // 处理HTML标签
      let text = comment.text.replace(/<p>/g, '\n').replace(/<\/p>/g, '\n');
      text = text.replace(/<i>/g, '*').replace(/<\/i>/g, '*');
      text = text.replace(/<b>/g, '**').replace(/<\/b>/g, '**');
      text = text.replace(/<a\s+href="([^"]+)">([^<]+)<\/a>/g, '[$2]($1)');
      text = text.replace(/<[^>]*>/g, '');

      markdown += `${indent}${text}\n\n`;
    }

    // 递归处理子评论
    if (comment.comments && comment.comments.length > 0) {
      markdown += formatCommentsToMarkdown(comment.comments, level + 1);
    }

    markdown += `${indent}---\n\n`;
  }

  return markdown;
}

/**
 * 格式化帖子数据为JSON
 * @param {Object} post - 帖子数据
 * @returns {string} JSON格式的字符串
 */
function formatPostToJSON(post) {
  // 创建一个干净的帖子对象，不包含循环引用
  const cleanPost = {
    id: post.id,
    title: post.title,
    url: post.url,
    text: post.text,
    by: post.by,
    time: post.time,
    formattedTime: formatTime(post.time),
    score: post.score,
    descendants: post.descendants,
    type: post.type,
    comments: post.comments
  };

  return JSON.stringify(cleanPost, null, 2);
}

module.exports = {
  formatPostToMarkdown,
  formatPostToJSON,
  formatTime
};