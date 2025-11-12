const axios = require('axios');

// Hacker News API基础URL
const HN_BASE_URL = 'https://hacker-news.firebaseio.com/v0';

/**
 * 获取单个项目的详细信息
 * @param {string|number} id - 项目ID
 * @returns {Promise<Object>} 项目详情
 */
async function getItem(id) {
  try {
    const response = await axios.get(`${HN_BASE_URL}/item/${id}.json`);
    return response.data;
  } catch (error) {
    console.error(`Error fetching item ${id}:`, error.message);
    return null;
  }
}

/**
 * 获取用户信息
 * @param {string} username - 用户名
 * @returns {Promise<Object>} 用户详情
 */
async function getUser(username) {
  try {
    const response = await axios.get(`${HN_BASE_URL}/user/${username}.json`);
    return response.data;
  } catch (error) {
    console.error(`Error fetching user ${username}:`, error.message);
    return null;
  }
}

module.exports = {
  getItem,
  getUser
};