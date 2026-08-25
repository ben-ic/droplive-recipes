"use strict";

const { existsSync, writeFileSync } = require("node:fs");
const bcrypt = require("bcrypt");
const { PrismaClient } = require("@prisma/client");

const marker = "/data/data/.droplive-business-saas-company-v1";
const username = "maya";
const password = process.env.DROPLIVE_OWNER_PASSWORD;
const companyUrl = process.env.DROPLIVE_COMPANY_URL;
const changingUrl = process.env.DROPLIVE_CHANGING_URL;

if (!password || !companyUrl || !changingUrl || existsSync(marker)) process.exit(0);

const prisma = new PrismaClient();

async function waitForSchema() {
  let lastError;
  for (let attempt = 0; attempt < 90; attempt += 1) {
    try {
      await prisma.user.count();
      return;
    } catch (error) {
      lastError = error;
      await new Promise((resolve) => setTimeout(resolve, 1000));
    }
  }
  throw lastError || new Error("Linkwarden schema did not become ready");
}

async function main() {
  await waitForSchema();

  let user = await prisma.user.findUnique({ where: { username } });
  if (!user) {
    user = await prisma.user.create({
      data: {
        name: "Maya Chen",
        username,
        password: bcrypt.hashSync(password, 10),
        dashboardSections: {
          createMany: {
            data: [
              { order: 0, type: "STATS" },
              { order: 1, type: "RECENT_LINKS" },
              { order: 2, type: "PINNED_LINKS" },
            ],
          },
        },
      },
    });
  }

  let collection = await prisma.collection.findFirst({
    where: { ownerId: user.id, name: "Northstar Relay" },
  });
  if (!collection) {
    collection = await prisma.collection.create({
      data: {
        name: "Northstar Relay",
        description: "Customer and release work for the Northstar Relay team.",
        color: "#2563eb",
        ownerId: user.id,
        createdById: user.id,
      },
    });
    await prisma.user.update({
      where: { id: user.id },
      data: { collectionOrder: [collection.id] },
    });
  }

  const links = [
    {
      name: "Northstar Relay company briefing",
      description: "Current customer and release context.",
      url: companyUrl,
    },
    {
      name: "Lumen export release note",
      description: "The page that changes as the team works on the export fix.",
      url: changingUrl,
    },
  ];

  for (const link of links) {
    const exists = await prisma.link.findFirst({
      where: { collectionId: collection.id, url: link.url },
    });
    if (!exists) {
      await prisma.link.create({
        data: {
          ...link,
          collectionId: collection.id,
          createdById: user.id,
          lastPreserved: new Date(),
          readable: "unavailable",
          image: "unavailable",
          monolith: "unavailable",
          pdf: "unavailable",
          preview: "unavailable",
        },
      });
    }
  }

  writeFileSync(marker, "seeded\n", { mode: 0o600 });
}

main()
  .catch((error) => {
    console.error("DropLive Linkwarden seed failed:", error.message);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
