"use strict";

process.chdir("/app");
require("/app/node_modules/dotenv").config({ path: "/app/.env" });

const { connectDB, sequelize } = require("/app/db");
const App = require("/app/models/App");
const Bookmark = require("/app/models/Bookmark");
const Category = require("/app/models/Category");

async function main() {
  await connectDB();

  const company = await Category.create({
    name: "Northstar Relay",
    isPinned: true,
    isPublic: 1,
    orderId: 1,
  });

  for (const [name, url, icon] of [
    ["Product direction", "https://example.com/product", "explore"],
    ["Release readiness", "https://example.com/releases", "rocket_launch"],
    ["Customer notes", "https://example.com/customers", "groups"],
    ["Support queue", "https://example.com/support", "support_agent"],
    ["Finance review", "https://example.com/finance", "insights"],
  ]) {
    await Bookmark.create({
      name,
      url,
      icon,
      categoryId: company.id,
      isPublic: 1,
    });
  }

  await App.create({
    name: "Team handbook",
    url: "https://example.com/handbook",
    icon: "menu_book",
    description: "Working agreements and operating practices",
    isPinned: true,
    isPublic: 1,
  });

  await sequelize.close();
}

main().catch(async (error) => {
  console.error("DropLive Flame seed failed:", error);
  await sequelize.close();
  process.exit(1);
});
