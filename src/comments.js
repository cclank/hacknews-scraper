const { getItem } = require('./api');

/**
 * 递归获取评论树
 * @param {string|number} id - 评论ID
 * @param {number} depth - 当前递归深度
 * @param {number} maxDepth - 最大递归深度
 * @returns {Promise<Object>} 包含评论树的对象
 */
async function getCommentTree(id, depth = 0, maxDepth = Infinity) {
  // 如果超过最大深度，停止递归
  if (depth > maxDepth) {
    return null;
  }

  // 获取项目详情
  const item = await getItem(id);

  // 如果项目不存在或不是评论，返回null
  if (!item || item.deleted) {
    return null;
  }

  // 初始化评论树节点
  const commentTree = {
    id: item.id,
    by: item.by,
    text: item.text,
    time: item.time,
    type: item.type,
    deleted: item.deleted || false,
    dead: item.dead || false,
    comments: []
  };

  // 如果有子评论且是评论类型，递归获取子评论
  if (item.kids && item.type === 'comment') {
    for (const kidId of item.kids) {
      const childComment = await getCommentTree(kidId, depth + 1, maxDepth);
      if (childComment) {
        commentTree.comments.push(childComment);
      }
    }
  }

  return commentTree;
}

/**
 * 获取帖子及其所有评论
 * @param {string|number} postId - 帖子ID
 * @returns {Promise<Object>} 包含帖子和评论的完整对象
 */
async function getPostWithComments(postId) {
  // 获取帖子详情
  const post = await getItem(postId);

  if (!post) {
    throw new Error(`Post with ID ${postId} not found`);
  }

  // 初始化结果对象
  const result = {
    id: post.id,
    title: post.title,
    url: post.url,
    text: post.text,
    by: post.by,
    time: post.time,
    score: post.score,
    descendants: post.descendants,
    type: post.type,
    deleted: post.deleted || false,
    dead: post.dead || false,
    comments: []
  };

  // 如果有评论，递归获取所有评论
  if (post.kids && post.kids.length > 0) {
    for (const kidId of post.kids) {
      try {
        const commentTree = await getCommentTree(kidId, 0);
        if (commentTree) {
          result.comments.push(commentTree);
        }
      } catch (error) {
        console.error(`Error fetching comment ${kidId}:`, error.message);
      }
    }
  }

  return result;
}

module.exports = {
  getPostWithComments,
  getCommentTree
};