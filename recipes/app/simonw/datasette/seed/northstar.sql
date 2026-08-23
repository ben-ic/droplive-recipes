PRAGMA foreign_keys = OFF;
BEGIN;
CREATE TABLE organizations (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  domain TEXT NOT NULL,
  summary TEXT NOT NULL,
  is_northstar INTEGER NOT NULL
);
INSERT INTO organizations (id, name, domain, summary, is_northstar) VALUES
('northstar-relay', 'Northstar Relay', 'northstar-relay.invalid', 'A small software company that automates large operational data exports.', 1),
('lumen-labs', 'Lumen Labs', 'lumen-labs.invalid', 'A growing operations analytics company and Northstar''s largest upcoming renewal.', 0),
('ember-commerce', 'Ember Commerce', 'ember-commerce.invalid', 'An online retailer that uses scheduled exports for fulfilment reporting.', 0),
('fieldnote-studio', 'Fieldnote Studio', 'fieldnote-studio.invalid', 'A design studio with a small annual Northstar plan.', 0),
('harbor-mobility', 'Harbor Mobility', 'harbor-mobility.invalid', 'A regional transport operator with compliance export requirements.', 0),
('cedar-office', 'Cedar Office', 'cedar-office.invalid', 'Northstar''s office and equipment supplier.', 0),
('cloudharbor', 'CloudHarbor', 'cloudharbor.invalid', 'A fictional infrastructure provider used by Northstar.', 0);
CREATE TABLE people (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  role TEXT NOT NULL,
  team TEXT NOT NULL,
  email TEXT NOT NULL,
  github_login TEXT,
  location TEXT,
  organization_id TEXT REFERENCES organizations(id),
  status TEXT
);
INSERT INTO people (id, name, role, team, email, github_login, location, organization_id, status) VALUES
('maya-chen', 'Maya Chen', 'Co-founder and CEO', 'leadership', 'maya@northstar-relay.invalid', 'mayac', 'London', 'northstar-relay', 'Renewal prep until 14:00'),
('jon-bell', 'Jon Bell', 'Co-founder and CTO', 'engineering', 'jon@northstar-relay.invalid', 'jonbell', 'Bristol', 'northstar-relay', 'Load testing exports'),
('noor-alvarez', 'Noor Alvarez', 'Operations and finance lead', 'operations', 'noor@northstar-relay.invalid', 'nooralvarez', 'Madrid', 'northstar-relay', 'Month-end preparation'),
('elena-petrov', 'Elena Petrov', 'Product manager', 'product', 'elena@northstar-relay.invalid', 'elenap', 'Berlin', 'northstar-relay', 'Planning 2.8'),
('samira-okafor', 'Samira Okafor', 'Customer support lead', 'support', 'samira@northstar-relay.invalid', 'samira-o', 'Dublin', 'northstar-relay', 'Watching Lumen export'),
('lucas-meyer', 'Lucas Meyer', 'Senior engineer', 'engineering', 'lucas@northstar-relay.invalid', 'lucasmeyer', 'Hamburg', 'northstar-relay', 'Export worker fix'),
('hana-ito', 'Hana Ito', 'Software engineer', 'engineering', 'hana@northstar-relay.invalid', 'hanaito', 'Leeds', 'northstar-relay', 'Reviewing audit page'),
('david-banerjee', 'David Banerjee', 'Sales and partnerships', 'commercial', 'david@northstar-relay.invalid', 'davidb', 'London', 'northstar-relay', 'Customer calls'),
('imani-brooks', 'Imani Brooks', 'Product designer', 'product', 'imani@northstar-relay.invalid', 'imanib', 'Manchester', 'northstar-relay', 'Onboarding notes'),
('theo-martin', 'Theo Martin', 'Software engineer', 'engineering', 'theo@northstar-relay.invalid', 'theomartin', 'Glasgow', 'northstar-relay', 'Starts Monday'),
('priya-raman', 'Priya Raman', 'Director of operations', 'external', 'priya@lumen-labs.invalid', 'priya-raman', 'Amsterdam', 'lumen-labs', NULL),
('ravi-okonkwo', 'Ravi Okonkwo', 'Data operations manager', 'external', 'ravi@ember-commerce.invalid', 'ravi-okonkwo', 'Birmingham', 'ember-commerce', NULL),
('marta-silva', 'Marta Silva', 'Studio manager', 'external', 'marta@fieldnote-studio.invalid', 'marta-silva', 'Porto', 'fieldnote-studio', NULL),
('owen-price', 'Owen Price', 'Compliance systems lead', 'external', 'owen@harbor-mobility.invalid', 'owen-price', 'Cardiff', 'harbor-mobility', NULL),
('fern-ellery', 'Fern Ellery', 'Account manager', 'external', 'fern@cedar-office.invalid', 'fern-ellery', 'London', 'cedar-office', NULL),
('adil-hassan', 'Adil Hassan', 'Customer success engineer', 'external', 'adil@cloudharbor.invalid', 'adil-hassan', 'Paris', 'cloudharbor', NULL);
CREATE TABLE customers (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  plan TEXT NOT NULL,
  monthly_usd REAL NOT NULL,
  organization_id TEXT REFERENCES organizations(id),
  contact_person_id TEXT REFERENCES people(id),
  invoice_day INTEGER NOT NULL,
  due_day INTEGER NOT NULL
);
INSERT INTO customers (id, name, plan, monthly_usd, organization_id, contact_person_id, invoice_day, due_day) VALUES
('lumen', 'Lumen Labs', 'Northstar Scale plan', 412.0, 'lumen-labs', 'priya-raman', 14, 30),
('ember', 'Ember Commerce', 'Northstar Growth plan', 289.0, 'ember-commerce', 'ravi-okonkwo', 5, 5),
('fieldnote', 'Fieldnote Studio', 'Northstar Team plan', 99.0, 'fieldnote-studio', 'marta-silva', 8, 8),
('harbor', 'Harbor Mobility', 'Northstar Scale plan', 356.0, 'harbor-mobility', 'owen-price', 11, 11);
CREATE TABLE suppliers (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  service TEXT NOT NULL,
  monthly_usd REAL NOT NULL,
  organization_id TEXT REFERENCES organizations(id),
  contact_person_id TEXT REFERENCES people(id)
);
INSERT INTO suppliers (id, name, service, monthly_usd, organization_id, contact_person_id) VALUES
('cedar', 'Cedar Office', 'Office, equipment, and meeting space', 184.0, 'cedar-office', 'fern-ellery'),
('cloudharbor', 'CloudHarbor', 'Compute, storage, and managed database', 731.0, 'cloudharbor', 'adil-hassan');
CREATE TABLE projects (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  summary TEXT NOT NULL,
  status TEXT NOT NULL,
  owner_person_id TEXT REFERENCES people(id),
  customer_id TEXT REFERENCES customers(id),
  start_on TEXT NOT NULL,
  target_on TEXT NOT NULL
);
INSERT INTO projects (id, name, summary, status, owner_person_id, customer_id, start_on, target_on) VALUES
('project-lumen-renewal', 'Lumen renewal', 'Prepare the renewal with an accurate account record and a safe export workaround.', 'active', 'maya-chen', 'lumen', '2026-08-11', '2026-08-25'),
('project-release-28', 'Release 2.8', 'Ship the audit improvements without hiding the remaining export risk.', 'at-risk', 'elena-petrov', NULL, '2026-07-27', '2026-08-27'),
('project-theo-onboarding', 'Theo onboarding', 'Give Theo a useful first week while the engineering team completes release work.', 'active', 'imani-brooks', NULL, '2026-08-17', '2026-08-28'),
('project-month-end', 'August month-end', 'Close August books with complete expenses and clear customer balances.', 'active', 'noor-alvarez', NULL, '2026-08-17', '2026-09-03');
CREATE TABLE project_members (
  project_id TEXT REFERENCES projects(id),
  person_id TEXT REFERENCES people(id)
);
INSERT INTO project_members (project_id, person_id) VALUES
('project-lumen-renewal', 'maya-chen'),
('project-lumen-renewal', 'david-banerjee'),
('project-lumen-renewal', 'samira-okafor'),
('project-lumen-renewal', 'jon-bell'),
('project-lumen-renewal', 'lucas-meyer'),
('project-release-28', 'elena-petrov'),
('project-release-28', 'jon-bell'),
('project-release-28', 'lucas-meyer'),
('project-release-28', 'hana-ito'),
('project-release-28', 'imani-brooks'),
('project-release-28', 'samira-okafor'),
('project-theo-onboarding', 'imani-brooks'),
('project-theo-onboarding', 'theo-martin'),
('project-theo-onboarding', 'jon-bell'),
('project-theo-onboarding', 'hana-ito'),
('project-month-end', 'noor-alvarez'),
('project-month-end', 'maya-chen'),
('project-month-end', 'david-banerjee');
CREATE TABLE tasks (
  id TEXT PRIMARY KEY,
  project_id TEXT REFERENCES projects(id),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  status TEXT NOT NULL,
  priority TEXT NOT NULL,
  assignee_person_id TEXT REFERENCES people(id),
  reporter_person_id TEXT REFERENCES people(id),
  due_on TEXT,
  labels TEXT
);
INSERT INTO tasks (id, project_id, title, description, status, priority, assignee_person_id, reporter_person_id, due_on, labels) VALUES
('task-renewal-brief', 'project-lumen-renewal', 'Finish the renewal brief', 'Replace the marked technical paragraph after engineering gives a tested status. Keep invoice 4471 separate from the incident.', 'in-progress', 'high', 'maya-chen', 'david-banerjee', '2026-08-24', 'customer, renewal'),
('task-safe-workaround', 'project-lumen-renewal', 'Send Priya the scheduled-export workaround', 'Document manual retry as the temporary path. Do not promise a release date.', 'ready', 'urgent', 'samira-okafor', 'maya-chen', '2026-08-21', 'support, customer'),
('task-load-50k', 'project-release-28', 'Run the 50k-row export test', 'Record duration and worker memory for the scheduled path on the fix branch.', 'done', 'high', 'lucas-meyer', 'jon-bell', '2026-08-21', 'exports, test'),
('task-load-75k', 'project-release-28', 'Run the 75k-row export test', 'Use the production-like object size and confirm the worker lease closes.', 'done', 'high', 'lucas-meyer', 'jon-bell', '2026-08-21', 'exports, test'),
('task-cancel-cleanup', 'project-release-28', 'Remove the partial object after cancellation', 'The worker lease closes, but the cancelled 75k-row run leaves a partial object. Add cleanup and prove idempotent retry.', 'blocked', 'urgent', 'lucas-meyer', 'jon-bell', '2026-08-24', 'exports, bug, release-blocker'),
('task-timezone-label', 'project-release-28', 'Correct the audit timezone label', 'The timestamp value is correct. The label says UTC after local conversion.', 'review', 'normal', 'hana-ito', 'hana-ito', '2026-08-25', 'audit, ui'),
('task-release-notes', 'project-release-28', 'Write release notes for audit history', 'Explain local time display and the new export activity entries in customer language.', 'in-progress', 'normal', 'elena-petrov', 'maya-chen', '2026-08-25', 'release, docs'),
('task-audit-empty-state', 'project-release-28', 'Approve the audit empty state', 'Use the short copy. Do not show an error when a new workspace has no export history.', 'done', 'normal', 'imani-brooks', 'elena-petrov', '2026-08-19', 'audit, design'),
('task-staging-access', 'project-theo-onboarding', 'Create Theo''s staging access', 'Owner is not assigned. Access must be ready before Tuesday pairing, not before the Monday welcome call.', 'backlog', 'high', 'jon-bell', 'imani-brooks', '2026-08-25', 'access, onboarding'),
('task-architecture-session', 'project-theo-onboarding', 'Prepare the connector architecture session', 'Use the Ember CSV incident as a small example of why connector contracts are versioned.', 'ready', 'normal', 'jon-bell', 'imani-brooks', '2026-08-24', 'onboarding, engineering'),
('task-pairing-plan', 'project-theo-onboarding', 'Choose Theo''s first pairing issue', 'Pick a bounded audit-page issue. Do not use the Lumen release blocker as an onboarding task.', 'done', 'normal', 'hana-ito', 'imani-brooks', '2026-08-20', 'onboarding'),
('task-august-expenses', 'project-month-end', 'Collect missing August expenses', 'Three entries have an amount but no receipt. Ask owners today and leave unresolved receipts marked pending.', 'in-progress', 'high', 'noor-alvarez', 'noor-alvarez', '2026-08-21', 'finance, month-end'),
('task-lumen-balance', 'project-month-end', 'Review Lumen balance after due date', 'Invoice 4471 is open and not overdue. Review only if it remains open after 30 August.', 'backlog', 'normal', 'noor-alvarez', 'maya-chen', '2026-08-31', 'finance, customer'),
('task-cash-reconcile', 'project-month-end', 'Reconcile operating cash', 'Match August customer receipts and supplier payments before the close review.', 'ready', 'normal', 'noor-alvarez', 'noor-alvarez', '2026-09-02', 'finance, reconciliation');
CREATE TABLE time_entries (
  id TEXT PRIMARY KEY,
  task_id TEXT REFERENCES tasks(id),
  person_id TEXT REFERENCES people(id),
  date TEXT NOT NULL,
  minutes INTEGER NOT NULL,
  note TEXT NOT NULL
);
INSERT INTO time_entries (id, task_id, person_id, date, minutes, note) VALUES
('time-001', 'task-load-50k', 'lucas-meyer', '2026-08-20', 95, 'Prepared the scheduled fixture and captured the baseline.'),
('time-002', 'task-load-50k', 'lucas-meyer', '2026-08-21', 40, 'Ran the fix branch and checked worker memory.'),
('time-003', 'task-load-75k', 'lucas-meyer', '2026-08-21', 55, 'Completed the large run and checked lease release.'),
('time-004', 'task-cancel-cleanup', 'lucas-meyer', '2026-08-21', 70, 'Found the partial object left by cancellation.'),
('time-005', 'task-timezone-label', 'hana-ito', '2026-08-20', 35, 'Reproduced the suffix error and added a view test.'),
('time-006', 'task-release-notes', 'elena-petrov', '2026-08-20', 50, 'Drafted the audit history section.'),
('time-007', 'task-audit-empty-state', 'imani-brooks', '2026-08-19', 45, 'Reviewed copy in the narrow and wide layouts.'),
('time-008', 'task-pairing-plan', 'hana-ito', '2026-08-20', 20, 'Selected a small audit filter issue for Tuesday.'),
('time-009', 'task-renewal-brief', 'maya-chen', '2026-08-20', 35, 'Reviewed usage and billing facts with David.'),
('time-010', 'task-august-expenses', 'noor-alvarez', '2026-08-20', 65, 'Matched card entries and requested three receipts.');
CREATE TABLE repositories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  language TEXT NOT NULL,
  topics TEXT NOT NULL
);
INSERT INTO repositories (id, name, description, language, topics) VALUES
('repo-core', 'relay-core', 'Core job orchestration and connector runtime', 'Go', 'jobs, connectors, queues'),
('repo-exports', 'exports-service', 'Export preparation, chunking, and delivery service', 'TypeScript', 'exports, workers, storage'),
('repo-console', 'web-console', 'Customer dashboard and audit interface', 'TypeScript', 'web, audit, dashboard');
CREATE TABLE issues (
  id TEXT PRIMARY KEY,
  repository_id TEXT REFERENCES repositories(id),
  number INTEGER NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  state TEXT NOT NULL,
  author TEXT NOT NULL,
  assignee TEXT,
  labels TEXT,
  customer_id TEXT REFERENCES customers(id),
  support_case_id TEXT
);
INSERT INTO issues (id, repository_id, number, title, body, state, author, assignee, labels, customer_id, support_case_id) VALUES
('issue-318', 'repo-core', 318, 'Scheduled exports keep the legacy 120s worker timeout', 'Lumen reproduced at 52,184 rows. Manual retry uses the account limit; scheduled execution still passes 120 seconds. Test 50k, 75k, and cancellation before merge.', 'open', 'samira-o', 'lucasmeyer', 'bug, customer-lumen, release-2.8', 'lumen', 'case-lumen-export'),
('issue-319', 'repo-exports', 319, 'Add cancellation case to large-export load fixture', 'Current fixture measures completion only. A cancelled 75k-row job must release its worker lease and partial object.', 'open', 'jonbell', 'hanaito', 'test, release-2.8', NULL, NULL),
('issue-322', 'repo-console', 322, 'Audit export labels timestamps as UTC after local conversion', 'Value is converted correctly, but the suffix remains UTC. Visual bug only; keep out of the export worker branch.', 'open', 'hanaito', 'hanaito', 'bug, audit-page, small', NULL, NULL);
CREATE TABLE support_cases (
  id TEXT PRIMARY KEY,
  customer_id TEXT REFERENCES customers(id),
  title TEXT NOT NULL,
  priority TEXT NOT NULL,
  state TEXT NOT NULL,
  owner_person_id TEXT REFERENCES people(id),
  contact_person_id TEXT REFERENCES people(id),
  opened_at TEXT NOT NULL,
  next_action TEXT NOT NULL
);
INSERT INTO support_cases (id, customer_id, title, priority, state, owner_person_id, contact_person_id, opened_at, next_action) VALUES
('case-lumen-export', 'lumen', 'Scheduled export stops at two minutes', 'high', 'engineering', 'samira-okafor', 'priya-raman', '2026-08-18 10:21:00', 'Send workaround before 15:00 and update after cancellation test.'),
('case-ember-header', 'ember', 'CSV header order changed after connector update', 'normal', 'waiting-customer', 'samira-okafor', 'ravi-okonkwo', '2026-08-19 14:08:00', 'Wait for the saved export id from Ravi.');
CREATE TABLE invoices (
  number TEXT PRIMARY KEY,
  customer_id TEXT REFERENCES customers(id),
  description TEXT NOT NULL,
  issued_on TEXT NOT NULL,
  due_on TEXT NOT NULL,
  amount_usd REAL NOT NULL,
  status TEXT NOT NULL,
  paid_on TEXT
);
INSERT INTO invoices (number, customer_id, description, issued_on, due_on, amount_usd, status, paid_on) VALUES
('2508-42', 'ember', 'Northstar Growth plan', '2025-08-05', '2025-09-05', 289.0, 'paid', '2025-09-05'),
('2508-18', 'fieldnote', 'Northstar Team plan', '2025-08-08', '2025-09-08', 99.0, 'paid', '2025-09-08'),
('2508-63', 'harbor', 'Northstar Scale plan', '2025-08-11', '2025-09-11', 356.0, 'paid', '2025-09-11'),
('2508-71', 'lumen', 'Northstar Scale plan', '2025-08-14', '2025-09-30', 412.0, 'paid', '2025-09-30'),
('2509-42', 'ember', 'Northstar Growth plan', '2025-09-05', '2025-10-05', 289.0, 'paid', '2025-10-05'),
('2509-18', 'fieldnote', 'Northstar Team plan', '2025-09-08', '2025-10-08', 99.0, 'paid', '2025-10-08'),
('2509-63', 'harbor', 'Northstar Scale plan', '2025-09-11', '2025-10-11', 356.0, 'paid', '2025-10-11'),
('2509-71', 'lumen', 'Northstar Scale plan', '2025-09-14', '2025-10-30', 412.0, 'paid', '2025-10-30'),
('2510-42', 'ember', 'Northstar Growth plan', '2025-10-05', '2025-11-05', 289.0, 'paid', '2025-11-05'),
('2510-18', 'fieldnote', 'Northstar Team plan', '2025-10-08', '2025-11-08', 99.0, 'paid', '2025-11-08'),
('2510-63', 'harbor', 'Northstar Scale plan', '2025-10-11', '2025-11-11', 356.0, 'paid', '2025-11-11'),
('2510-71', 'lumen', 'Northstar Scale plan', '2025-10-14', '2025-11-30', 412.0, 'paid', '2025-11-30'),
('2511-42', 'ember', 'Northstar Growth plan', '2025-11-05', '2025-12-05', 289.0, 'paid', '2025-12-05'),
('2511-18', 'fieldnote', 'Northstar Team plan', '2025-11-08', '2025-12-08', 99.0, 'paid', '2025-12-08'),
('2511-63', 'harbor', 'Northstar Scale plan', '2025-11-11', '2025-12-11', 356.0, 'paid', '2025-12-11'),
('2511-71', 'lumen', 'Northstar Scale plan', '2025-11-14', '2025-12-30', 412.0, 'paid', '2025-12-30'),
('2512-42', 'ember', 'Northstar Growth plan', '2025-12-05', '2026-01-05', 289.0, 'paid', '2026-01-05'),
('2512-18', 'fieldnote', 'Northstar Team plan', '2025-12-08', '2026-01-08', 99.0, 'paid', '2026-01-08'),
('2512-63', 'harbor', 'Northstar Scale plan', '2025-12-11', '2026-01-11', 356.0, 'paid', '2026-01-11'),
('2512-71', 'lumen', 'Northstar Scale plan', '2025-12-14', '2026-01-30', 412.0, 'paid', '2026-01-30'),
('2601-42', 'ember', 'Northstar Growth plan', '2026-01-05', '2026-02-05', 289.0, 'paid', '2026-02-05'),
('2601-18', 'fieldnote', 'Northstar Team plan', '2026-01-08', '2026-02-08', 99.0, 'paid', '2026-02-08'),
('2601-63', 'harbor', 'Northstar Scale plan', '2026-01-11', '2026-02-11', 356.0, 'paid', '2026-02-11'),
('2601-71', 'lumen', 'Northstar Scale plan', '2026-01-14', '2026-02-28', 412.0, 'paid', '2026-02-28'),
('2602-42', 'ember', 'Northstar Growth plan', '2026-02-05', '2026-03-05', 289.0, 'paid', '2026-03-05'),
('2602-18', 'fieldnote', 'Northstar Team plan', '2026-02-08', '2026-03-08', 99.0, 'paid', '2026-03-08'),
('2602-63', 'harbor', 'Northstar Scale plan', '2026-02-11', '2026-03-11', 356.0, 'paid', '2026-03-11'),
('2602-71', 'lumen', 'Northstar Scale plan', '2026-02-14', '2026-03-30', 412.0, 'paid', '2026-03-30'),
('2603-42', 'ember', 'Northstar Growth plan', '2026-03-05', '2026-04-05', 289.0, 'paid', '2026-04-05'),
('2603-18', 'fieldnote', 'Northstar Team plan', '2026-03-08', '2026-04-08', 99.0, 'paid', '2026-04-08'),
('2603-63', 'harbor', 'Northstar Scale plan', '2026-03-11', '2026-04-11', 356.0, 'paid', '2026-04-11'),
('2603-71', 'lumen', 'Northstar Scale plan', '2026-03-14', '2026-04-30', 412.0, 'paid', '2026-04-30'),
('2604-42', 'ember', 'Northstar Growth plan', '2026-04-05', '2026-05-05', 289.0, 'paid', '2026-05-05'),
('2604-18', 'fieldnote', 'Northstar Team plan', '2026-04-08', '2026-05-08', 99.0, 'paid', '2026-05-08'),
('2604-63', 'harbor', 'Northstar Scale plan', '2026-04-11', '2026-05-11', 356.0, 'paid', '2026-05-11'),
('2604-71', 'lumen', 'Northstar Scale plan', '2026-04-14', '2026-05-30', 412.0, 'paid', '2026-05-30'),
('2605-42', 'ember', 'Northstar Growth plan', '2026-05-05', '2026-06-05', 289.0, 'paid', '2026-06-05'),
('2605-18', 'fieldnote', 'Northstar Team plan', '2026-05-08', '2026-06-08', 99.0, 'paid', '2026-06-08'),
('2605-63', 'harbor', 'Northstar Scale plan', '2026-05-11', '2026-06-11', 356.0, 'paid', '2026-06-11'),
('2605-71', 'lumen', 'Northstar Scale plan', '2026-05-14', '2026-06-30', 412.0, 'paid', '2026-06-30'),
('2606-42', 'ember', 'Northstar Growth plan', '2026-06-05', '2026-07-05', 289.0, 'paid', '2026-07-05'),
('2606-18', 'fieldnote', 'Northstar Team plan', '2026-06-08', '2026-07-08', 99.0, 'paid', '2026-07-08'),
('2606-63', 'harbor', 'Northstar Scale plan', '2026-06-11', '2026-07-11', 356.0, 'paid', '2026-07-11'),
('2606-71', 'lumen', 'Northstar Scale plan', '2026-06-14', '2026-07-30', 412.0, 'paid', '2026-07-30'),
('2607-42', 'ember', 'Northstar Growth plan', '2026-07-05', '2026-08-05', 289.0, 'paid', '2026-08-05'),
('2607-18', 'fieldnote', 'Northstar Team plan', '2026-07-08', '2026-08-08', 99.0, 'paid', '2026-08-08'),
('2607-63', 'harbor', 'Northstar Scale plan', '2026-07-11', '2026-08-11', 356.0, 'paid', '2026-08-11'),
('2607-71', 'lumen', 'Northstar Scale plan', '2026-07-14', '2026-08-30', 412.0, 'paid', '2026-08-30'),
('4471', 'lumen', 'Northstar Scale plan — August', '2026-08-14', '2026-08-30', 412.0, 'open', NULL);
CREATE TABLE supplier_bills (
  id TEXT PRIMARY KEY,
  supplier_id TEXT REFERENCES suppliers(id),
  description TEXT NOT NULL,
  issued_on TEXT NOT NULL,
  amount_usd REAL NOT NULL,
  status TEXT NOT NULL
);
INSERT INTO supplier_bills (id, supplier_id, description, issued_on, amount_usd, status) VALUES
('bill-202508-cloudharbor', 'cloudharbor', 'Compute, storage, and managed database', '2025-08-02', 731.0, 'paid'),
('bill-202508-cedar', 'cedar', 'Office, equipment, and meeting space', '2025-08-12', 184.0, 'paid'),
('bill-202509-cloudharbor', 'cloudharbor', 'Compute, storage, and managed database', '2025-09-02', 731.0, 'paid'),
('bill-202509-cedar', 'cedar', 'Office, equipment, and meeting space', '2025-09-12', 184.0, 'paid'),
('bill-202510-cloudharbor', 'cloudharbor', 'Compute, storage, and managed database', '2025-10-02', 731.0, 'paid'),
('bill-202510-cedar', 'cedar', 'Office, equipment, and meeting space', '2025-10-12', 184.0, 'paid'),
('bill-202511-cloudharbor', 'cloudharbor', 'Compute, storage, and managed database', '2025-11-02', 731.0, 'paid'),
('bill-202511-cedar', 'cedar', 'Office, equipment, and meeting space', '2025-11-12', 184.0, 'paid'),
('bill-202512-cloudharbor', 'cloudharbor', 'Compute, storage, and managed database', '2025-12-02', 731.0, 'paid'),
('bill-202512-cedar', 'cedar', 'Office, equipment, and meeting space', '2025-12-12', 184.0, 'paid'),
('bill-202601-cloudharbor', 'cloudharbor', 'Compute, storage, and managed database', '2026-01-02', 731.0, 'paid'),
('bill-202601-cedar', 'cedar', 'Office, equipment, and meeting space', '2026-01-12', 184.0, 'paid'),
('bill-202602-cloudharbor', 'cloudharbor', 'Compute, storage, and managed database', '2026-02-02', 731.0, 'paid'),
('bill-202602-cedar', 'cedar', 'Office, equipment, and meeting space', '2026-02-12', 184.0, 'paid'),
('bill-202603-cloudharbor', 'cloudharbor', 'Compute, storage, and managed database', '2026-03-02', 731.0, 'paid'),
('bill-202603-cedar', 'cedar', 'Office, equipment, and meeting space', '2026-03-12', 184.0, 'paid'),
('bill-202604-cloudharbor', 'cloudharbor', 'Compute, storage, and managed database', '2026-04-02', 731.0, 'paid'),
('bill-202604-cedar', 'cedar', 'Office, equipment, and meeting space', '2026-04-12', 184.0, 'paid'),
('bill-202605-cloudharbor', 'cloudharbor', 'Compute, storage, and managed database', '2026-05-02', 731.0, 'paid'),
('bill-202605-cedar', 'cedar', 'Office, equipment, and meeting space', '2026-05-12', 184.0, 'paid'),
('bill-202606-cloudharbor', 'cloudharbor', 'Compute, storage, and managed database', '2026-06-02', 731.0, 'paid'),
('bill-202606-cedar', 'cedar', 'Office, equipment, and meeting space', '2026-06-12', 184.0, 'paid'),
('bill-202607-cloudharbor', 'cloudharbor', 'Compute, storage, and managed database', '2026-07-02', 731.0, 'paid'),
('bill-202607-cedar', 'cedar', 'Office, equipment, and meeting space', '2026-07-12', 184.0, 'paid');
CREATE TABLE ledger_entries (
  id TEXT PRIMARY KEY,
  record_id TEXT NOT NULL,
  account TEXT NOT NULL,
  date TEXT NOT NULL,
  debit_usd REAL NOT NULL,
  credit_usd REAL NOT NULL
);
INSERT INTO ledger_entries (id, record_id, account, date, debit_usd, credit_usd) VALUES
('entry-bill-202508-cloudharbor-cash', 'bill-202508-cloudharbor', 'operating-cash', '2025-08-02', 0.0, 731.0),
('entry-bill-202508-cloudharbor-expense', 'bill-202508-cloudharbor', 'operating-expense', '2025-08-02', 731.0, 0.0),
('entry-inv-202508-ember-receivable', 'inv-202508-ember', 'accounts-receivable', '2025-08-05', 289.0, 0.0),
('entry-inv-202508-ember-revenue', 'inv-202508-ember', 'subscription-revenue', '2025-08-05', 0.0, 289.0),
('entry-inv-202508-fieldnote-receivable', 'inv-202508-fieldnote', 'accounts-receivable', '2025-08-08', 99.0, 0.0),
('entry-inv-202508-fieldnote-revenue', 'inv-202508-fieldnote', 'subscription-revenue', '2025-08-08', 0.0, 99.0),
('entry-inv-202508-harbor-receivable', 'inv-202508-harbor', 'accounts-receivable', '2025-08-11', 356.0, 0.0),
('entry-inv-202508-harbor-revenue', 'inv-202508-harbor', 'subscription-revenue', '2025-08-11', 0.0, 356.0),
('entry-bill-202508-cedar-cash', 'bill-202508-cedar', 'operating-cash', '2025-08-12', 0.0, 184.0),
('entry-bill-202508-cedar-expense', 'bill-202508-cedar', 'operating-expense', '2025-08-12', 184.0, 0.0),
('entry-inv-202508-lumen-receivable', 'inv-202508-lumen', 'accounts-receivable', '2025-08-14', 412.0, 0.0),
('entry-inv-202508-lumen-revenue', 'inv-202508-lumen', 'subscription-revenue', '2025-08-14', 0.0, 412.0),
('entry-bill-202509-cloudharbor-cash', 'bill-202509-cloudharbor', 'operating-cash', '2025-09-02', 0.0, 731.0),
('entry-bill-202509-cloudharbor-expense', 'bill-202509-cloudharbor', 'operating-expense', '2025-09-02', 731.0, 0.0),
('entry-inv-202509-ember-receivable', 'inv-202509-ember', 'accounts-receivable', '2025-09-05', 289.0, 0.0),
('entry-inv-202509-ember-revenue', 'inv-202509-ember', 'subscription-revenue', '2025-09-05', 0.0, 289.0),
('entry-pay-inv-202508-ember-cash', 'pay-inv-202508-ember', 'operating-cash', '2025-09-05', 289.0, 0.0),
('entry-pay-inv-202508-ember-receivable', 'pay-inv-202508-ember', 'accounts-receivable', '2025-09-05', 0.0, 289.0),
('entry-inv-202509-fieldnote-receivable', 'inv-202509-fieldnote', 'accounts-receivable', '2025-09-08', 99.0, 0.0),
('entry-inv-202509-fieldnote-revenue', 'inv-202509-fieldnote', 'subscription-revenue', '2025-09-08', 0.0, 99.0),
('entry-pay-inv-202508-fieldnote-cash', 'pay-inv-202508-fieldnote', 'operating-cash', '2025-09-08', 99.0, 0.0),
('entry-pay-inv-202508-fieldnote-receivable', 'pay-inv-202508-fieldnote', 'accounts-receivable', '2025-09-08', 0.0, 99.0),
('entry-inv-202509-harbor-receivable', 'inv-202509-harbor', 'accounts-receivable', '2025-09-11', 356.0, 0.0),
('entry-inv-202509-harbor-revenue', 'inv-202509-harbor', 'subscription-revenue', '2025-09-11', 0.0, 356.0),
('entry-pay-inv-202508-harbor-cash', 'pay-inv-202508-harbor', 'operating-cash', '2025-09-11', 356.0, 0.0),
('entry-pay-inv-202508-harbor-receivable', 'pay-inv-202508-harbor', 'accounts-receivable', '2025-09-11', 0.0, 356.0),
('entry-bill-202509-cedar-cash', 'bill-202509-cedar', 'operating-cash', '2025-09-12', 0.0, 184.0),
('entry-bill-202509-cedar-expense', 'bill-202509-cedar', 'operating-expense', '2025-09-12', 184.0, 0.0),
('entry-inv-202509-lumen-receivable', 'inv-202509-lumen', 'accounts-receivable', '2025-09-14', 412.0, 0.0),
('entry-inv-202509-lumen-revenue', 'inv-202509-lumen', 'subscription-revenue', '2025-09-14', 0.0, 412.0),
('entry-pay-inv-202508-lumen-cash', 'pay-inv-202508-lumen', 'operating-cash', '2025-09-30', 412.0, 0.0),
('entry-pay-inv-202508-lumen-receivable', 'pay-inv-202508-lumen', 'accounts-receivable', '2025-09-30', 0.0, 412.0),
('entry-bill-202510-cloudharbor-cash', 'bill-202510-cloudharbor', 'operating-cash', '2025-10-02', 0.0, 731.0),
('entry-bill-202510-cloudharbor-expense', 'bill-202510-cloudharbor', 'operating-expense', '2025-10-02', 731.0, 0.0),
('entry-inv-202510-ember-receivable', 'inv-202510-ember', 'accounts-receivable', '2025-10-05', 289.0, 0.0),
('entry-inv-202510-ember-revenue', 'inv-202510-ember', 'subscription-revenue', '2025-10-05', 0.0, 289.0),
('entry-pay-inv-202509-ember-cash', 'pay-inv-202509-ember', 'operating-cash', '2025-10-05', 289.0, 0.0),
('entry-pay-inv-202509-ember-receivable', 'pay-inv-202509-ember', 'accounts-receivable', '2025-10-05', 0.0, 289.0),
('entry-inv-202510-fieldnote-receivable', 'inv-202510-fieldnote', 'accounts-receivable', '2025-10-08', 99.0, 0.0),
('entry-inv-202510-fieldnote-revenue', 'inv-202510-fieldnote', 'subscription-revenue', '2025-10-08', 0.0, 99.0),
('entry-pay-inv-202509-fieldnote-cash', 'pay-inv-202509-fieldnote', 'operating-cash', '2025-10-08', 99.0, 0.0),
('entry-pay-inv-202509-fieldnote-receivable', 'pay-inv-202509-fieldnote', 'accounts-receivable', '2025-10-08', 0.0, 99.0),
('entry-inv-202510-harbor-receivable', 'inv-202510-harbor', 'accounts-receivable', '2025-10-11', 356.0, 0.0),
('entry-inv-202510-harbor-revenue', 'inv-202510-harbor', 'subscription-revenue', '2025-10-11', 0.0, 356.0),
('entry-pay-inv-202509-harbor-cash', 'pay-inv-202509-harbor', 'operating-cash', '2025-10-11', 356.0, 0.0),
('entry-pay-inv-202509-harbor-receivable', 'pay-inv-202509-harbor', 'accounts-receivable', '2025-10-11', 0.0, 356.0),
('entry-bill-202510-cedar-cash', 'bill-202510-cedar', 'operating-cash', '2025-10-12', 0.0, 184.0),
('entry-bill-202510-cedar-expense', 'bill-202510-cedar', 'operating-expense', '2025-10-12', 184.0, 0.0),
('entry-inv-202510-lumen-receivable', 'inv-202510-lumen', 'accounts-receivable', '2025-10-14', 412.0, 0.0),
('entry-inv-202510-lumen-revenue', 'inv-202510-lumen', 'subscription-revenue', '2025-10-14', 0.0, 412.0),
('entry-pay-inv-202509-lumen-cash', 'pay-inv-202509-lumen', 'operating-cash', '2025-10-30', 412.0, 0.0),
('entry-pay-inv-202509-lumen-receivable', 'pay-inv-202509-lumen', 'accounts-receivable', '2025-10-30', 0.0, 412.0),
('entry-bill-202511-cloudharbor-cash', 'bill-202511-cloudharbor', 'operating-cash', '2025-11-02', 0.0, 731.0),
('entry-bill-202511-cloudharbor-expense', 'bill-202511-cloudharbor', 'operating-expense', '2025-11-02', 731.0, 0.0),
('entry-inv-202511-ember-receivable', 'inv-202511-ember', 'accounts-receivable', '2025-11-05', 289.0, 0.0),
('entry-inv-202511-ember-revenue', 'inv-202511-ember', 'subscription-revenue', '2025-11-05', 0.0, 289.0),
('entry-pay-inv-202510-ember-cash', 'pay-inv-202510-ember', 'operating-cash', '2025-11-05', 289.0, 0.0),
('entry-pay-inv-202510-ember-receivable', 'pay-inv-202510-ember', 'accounts-receivable', '2025-11-05', 0.0, 289.0),
('entry-inv-202511-fieldnote-receivable', 'inv-202511-fieldnote', 'accounts-receivable', '2025-11-08', 99.0, 0.0),
('entry-inv-202511-fieldnote-revenue', 'inv-202511-fieldnote', 'subscription-revenue', '2025-11-08', 0.0, 99.0),
('entry-pay-inv-202510-fieldnote-cash', 'pay-inv-202510-fieldnote', 'operating-cash', '2025-11-08', 99.0, 0.0),
('entry-pay-inv-202510-fieldnote-receivable', 'pay-inv-202510-fieldnote', 'accounts-receivable', '2025-11-08', 0.0, 99.0),
('entry-inv-202511-harbor-receivable', 'inv-202511-harbor', 'accounts-receivable', '2025-11-11', 356.0, 0.0),
('entry-inv-202511-harbor-revenue', 'inv-202511-harbor', 'subscription-revenue', '2025-11-11', 0.0, 356.0),
('entry-pay-inv-202510-harbor-cash', 'pay-inv-202510-harbor', 'operating-cash', '2025-11-11', 356.0, 0.0),
('entry-pay-inv-202510-harbor-receivable', 'pay-inv-202510-harbor', 'accounts-receivable', '2025-11-11', 0.0, 356.0),
('entry-bill-202511-cedar-cash', 'bill-202511-cedar', 'operating-cash', '2025-11-12', 0.0, 184.0),
('entry-bill-202511-cedar-expense', 'bill-202511-cedar', 'operating-expense', '2025-11-12', 184.0, 0.0),
('entry-inv-202511-lumen-receivable', 'inv-202511-lumen', 'accounts-receivable', '2025-11-14', 412.0, 0.0),
('entry-inv-202511-lumen-revenue', 'inv-202511-lumen', 'subscription-revenue', '2025-11-14', 0.0, 412.0),
('entry-pay-inv-202510-lumen-cash', 'pay-inv-202510-lumen', 'operating-cash', '2025-11-30', 412.0, 0.0),
('entry-pay-inv-202510-lumen-receivable', 'pay-inv-202510-lumen', 'accounts-receivable', '2025-11-30', 0.0, 412.0),
('entry-bill-202512-cloudharbor-cash', 'bill-202512-cloudharbor', 'operating-cash', '2025-12-02', 0.0, 731.0),
('entry-bill-202512-cloudharbor-expense', 'bill-202512-cloudharbor', 'operating-expense', '2025-12-02', 731.0, 0.0),
('entry-inv-202512-ember-receivable', 'inv-202512-ember', 'accounts-receivable', '2025-12-05', 289.0, 0.0),
('entry-inv-202512-ember-revenue', 'inv-202512-ember', 'subscription-revenue', '2025-12-05', 0.0, 289.0),
('entry-pay-inv-202511-ember-cash', 'pay-inv-202511-ember', 'operating-cash', '2025-12-05', 289.0, 0.0),
('entry-pay-inv-202511-ember-receivable', 'pay-inv-202511-ember', 'accounts-receivable', '2025-12-05', 0.0, 289.0),
('entry-inv-202512-fieldnote-receivable', 'inv-202512-fieldnote', 'accounts-receivable', '2025-12-08', 99.0, 0.0),
('entry-inv-202512-fieldnote-revenue', 'inv-202512-fieldnote', 'subscription-revenue', '2025-12-08', 0.0, 99.0),
('entry-pay-inv-202511-fieldnote-cash', 'pay-inv-202511-fieldnote', 'operating-cash', '2025-12-08', 99.0, 0.0),
('entry-pay-inv-202511-fieldnote-receivable', 'pay-inv-202511-fieldnote', 'accounts-receivable', '2025-12-08', 0.0, 99.0),
('entry-inv-202512-harbor-receivable', 'inv-202512-harbor', 'accounts-receivable', '2025-12-11', 356.0, 0.0),
('entry-inv-202512-harbor-revenue', 'inv-202512-harbor', 'subscription-revenue', '2025-12-11', 0.0, 356.0),
('entry-pay-inv-202511-harbor-cash', 'pay-inv-202511-harbor', 'operating-cash', '2025-12-11', 356.0, 0.0),
('entry-pay-inv-202511-harbor-receivable', 'pay-inv-202511-harbor', 'accounts-receivable', '2025-12-11', 0.0, 356.0),
('entry-bill-202512-cedar-cash', 'bill-202512-cedar', 'operating-cash', '2025-12-12', 0.0, 184.0),
('entry-bill-202512-cedar-expense', 'bill-202512-cedar', 'operating-expense', '2025-12-12', 184.0, 0.0),
('entry-inv-202512-lumen-receivable', 'inv-202512-lumen', 'accounts-receivable', '2025-12-14', 412.0, 0.0),
('entry-inv-202512-lumen-revenue', 'inv-202512-lumen', 'subscription-revenue', '2025-12-14', 0.0, 412.0),
('entry-pay-inv-202511-lumen-cash', 'pay-inv-202511-lumen', 'operating-cash', '2025-12-30', 412.0, 0.0),
('entry-pay-inv-202511-lumen-receivable', 'pay-inv-202511-lumen', 'accounts-receivable', '2025-12-30', 0.0, 412.0),
('entry-bill-202601-cloudharbor-cash', 'bill-202601-cloudharbor', 'operating-cash', '2026-01-02', 0.0, 731.0),
('entry-bill-202601-cloudharbor-expense', 'bill-202601-cloudharbor', 'operating-expense', '2026-01-02', 731.0, 0.0),
('entry-inv-202601-ember-receivable', 'inv-202601-ember', 'accounts-receivable', '2026-01-05', 289.0, 0.0),
('entry-inv-202601-ember-revenue', 'inv-202601-ember', 'subscription-revenue', '2026-01-05', 0.0, 289.0),
('entry-pay-inv-202512-ember-cash', 'pay-inv-202512-ember', 'operating-cash', '2026-01-05', 289.0, 0.0),
('entry-pay-inv-202512-ember-receivable', 'pay-inv-202512-ember', 'accounts-receivable', '2026-01-05', 0.0, 289.0),
('entry-inv-202601-fieldnote-receivable', 'inv-202601-fieldnote', 'accounts-receivable', '2026-01-08', 99.0, 0.0),
('entry-inv-202601-fieldnote-revenue', 'inv-202601-fieldnote', 'subscription-revenue', '2026-01-08', 0.0, 99.0);
INSERT INTO ledger_entries (id, record_id, account, date, debit_usd, credit_usd) VALUES
('entry-pay-inv-202512-fieldnote-cash', 'pay-inv-202512-fieldnote', 'operating-cash', '2026-01-08', 99.0, 0.0),
('entry-pay-inv-202512-fieldnote-receivable', 'pay-inv-202512-fieldnote', 'accounts-receivable', '2026-01-08', 0.0, 99.0),
('entry-inv-202601-harbor-receivable', 'inv-202601-harbor', 'accounts-receivable', '2026-01-11', 356.0, 0.0),
('entry-inv-202601-harbor-revenue', 'inv-202601-harbor', 'subscription-revenue', '2026-01-11', 0.0, 356.0),
('entry-pay-inv-202512-harbor-cash', 'pay-inv-202512-harbor', 'operating-cash', '2026-01-11', 356.0, 0.0),
('entry-pay-inv-202512-harbor-receivable', 'pay-inv-202512-harbor', 'accounts-receivable', '2026-01-11', 0.0, 356.0),
('entry-bill-202601-cedar-cash', 'bill-202601-cedar', 'operating-cash', '2026-01-12', 0.0, 184.0),
('entry-bill-202601-cedar-expense', 'bill-202601-cedar', 'operating-expense', '2026-01-12', 184.0, 0.0),
('entry-inv-202601-lumen-receivable', 'inv-202601-lumen', 'accounts-receivable', '2026-01-14', 412.0, 0.0),
('entry-inv-202601-lumen-revenue', 'inv-202601-lumen', 'subscription-revenue', '2026-01-14', 0.0, 412.0),
('entry-pay-inv-202512-lumen-cash', 'pay-inv-202512-lumen', 'operating-cash', '2026-01-30', 412.0, 0.0),
('entry-pay-inv-202512-lumen-receivable', 'pay-inv-202512-lumen', 'accounts-receivable', '2026-01-30', 0.0, 412.0),
('entry-bill-202602-cloudharbor-cash', 'bill-202602-cloudharbor', 'operating-cash', '2026-02-02', 0.0, 731.0),
('entry-bill-202602-cloudharbor-expense', 'bill-202602-cloudharbor', 'operating-expense', '2026-02-02', 731.0, 0.0),
('entry-inv-202602-ember-receivable', 'inv-202602-ember', 'accounts-receivable', '2026-02-05', 289.0, 0.0),
('entry-inv-202602-ember-revenue', 'inv-202602-ember', 'subscription-revenue', '2026-02-05', 0.0, 289.0),
('entry-pay-inv-202601-ember-cash', 'pay-inv-202601-ember', 'operating-cash', '2026-02-05', 289.0, 0.0),
('entry-pay-inv-202601-ember-receivable', 'pay-inv-202601-ember', 'accounts-receivable', '2026-02-05', 0.0, 289.0),
('entry-inv-202602-fieldnote-receivable', 'inv-202602-fieldnote', 'accounts-receivable', '2026-02-08', 99.0, 0.0),
('entry-inv-202602-fieldnote-revenue', 'inv-202602-fieldnote', 'subscription-revenue', '2026-02-08', 0.0, 99.0),
('entry-pay-inv-202601-fieldnote-cash', 'pay-inv-202601-fieldnote', 'operating-cash', '2026-02-08', 99.0, 0.0),
('entry-pay-inv-202601-fieldnote-receivable', 'pay-inv-202601-fieldnote', 'accounts-receivable', '2026-02-08', 0.0, 99.0),
('entry-inv-202602-harbor-receivable', 'inv-202602-harbor', 'accounts-receivable', '2026-02-11', 356.0, 0.0),
('entry-inv-202602-harbor-revenue', 'inv-202602-harbor', 'subscription-revenue', '2026-02-11', 0.0, 356.0),
('entry-pay-inv-202601-harbor-cash', 'pay-inv-202601-harbor', 'operating-cash', '2026-02-11', 356.0, 0.0),
('entry-pay-inv-202601-harbor-receivable', 'pay-inv-202601-harbor', 'accounts-receivable', '2026-02-11', 0.0, 356.0),
('entry-bill-202602-cedar-cash', 'bill-202602-cedar', 'operating-cash', '2026-02-12', 0.0, 184.0),
('entry-bill-202602-cedar-expense', 'bill-202602-cedar', 'operating-expense', '2026-02-12', 184.0, 0.0),
('entry-inv-202602-lumen-receivable', 'inv-202602-lumen', 'accounts-receivable', '2026-02-14', 412.0, 0.0),
('entry-inv-202602-lumen-revenue', 'inv-202602-lumen', 'subscription-revenue', '2026-02-14', 0.0, 412.0),
('entry-pay-inv-202601-lumen-cash', 'pay-inv-202601-lumen', 'operating-cash', '2026-02-28', 412.0, 0.0),
('entry-pay-inv-202601-lumen-receivable', 'pay-inv-202601-lumen', 'accounts-receivable', '2026-02-28', 0.0, 412.0),
('entry-bill-202603-cloudharbor-cash', 'bill-202603-cloudharbor', 'operating-cash', '2026-03-02', 0.0, 731.0),
('entry-bill-202603-cloudharbor-expense', 'bill-202603-cloudharbor', 'operating-expense', '2026-03-02', 731.0, 0.0),
('entry-inv-202603-ember-receivable', 'inv-202603-ember', 'accounts-receivable', '2026-03-05', 289.0, 0.0),
('entry-inv-202603-ember-revenue', 'inv-202603-ember', 'subscription-revenue', '2026-03-05', 0.0, 289.0),
('entry-pay-inv-202602-ember-cash', 'pay-inv-202602-ember', 'operating-cash', '2026-03-05', 289.0, 0.0),
('entry-pay-inv-202602-ember-receivable', 'pay-inv-202602-ember', 'accounts-receivable', '2026-03-05', 0.0, 289.0),
('entry-inv-202603-fieldnote-receivable', 'inv-202603-fieldnote', 'accounts-receivable', '2026-03-08', 99.0, 0.0),
('entry-inv-202603-fieldnote-revenue', 'inv-202603-fieldnote', 'subscription-revenue', '2026-03-08', 0.0, 99.0),
('entry-pay-inv-202602-fieldnote-cash', 'pay-inv-202602-fieldnote', 'operating-cash', '2026-03-08', 99.0, 0.0),
('entry-pay-inv-202602-fieldnote-receivable', 'pay-inv-202602-fieldnote', 'accounts-receivable', '2026-03-08', 0.0, 99.0),
('entry-inv-202603-harbor-receivable', 'inv-202603-harbor', 'accounts-receivable', '2026-03-11', 356.0, 0.0),
('entry-inv-202603-harbor-revenue', 'inv-202603-harbor', 'subscription-revenue', '2026-03-11', 0.0, 356.0),
('entry-pay-inv-202602-harbor-cash', 'pay-inv-202602-harbor', 'operating-cash', '2026-03-11', 356.0, 0.0),
('entry-pay-inv-202602-harbor-receivable', 'pay-inv-202602-harbor', 'accounts-receivable', '2026-03-11', 0.0, 356.0),
('entry-bill-202603-cedar-cash', 'bill-202603-cedar', 'operating-cash', '2026-03-12', 0.0, 184.0),
('entry-bill-202603-cedar-expense', 'bill-202603-cedar', 'operating-expense', '2026-03-12', 184.0, 0.0),
('entry-inv-202603-lumen-receivable', 'inv-202603-lumen', 'accounts-receivable', '2026-03-14', 412.0, 0.0),
('entry-inv-202603-lumen-revenue', 'inv-202603-lumen', 'subscription-revenue', '2026-03-14', 0.0, 412.0),
('entry-pay-inv-202602-lumen-cash', 'pay-inv-202602-lumen', 'operating-cash', '2026-03-30', 412.0, 0.0),
('entry-pay-inv-202602-lumen-receivable', 'pay-inv-202602-lumen', 'accounts-receivable', '2026-03-30', 0.0, 412.0),
('entry-bill-202604-cloudharbor-cash', 'bill-202604-cloudharbor', 'operating-cash', '2026-04-02', 0.0, 731.0),
('entry-bill-202604-cloudharbor-expense', 'bill-202604-cloudharbor', 'operating-expense', '2026-04-02', 731.0, 0.0),
('entry-inv-202604-ember-receivable', 'inv-202604-ember', 'accounts-receivable', '2026-04-05', 289.0, 0.0),
('entry-inv-202604-ember-revenue', 'inv-202604-ember', 'subscription-revenue', '2026-04-05', 0.0, 289.0),
('entry-pay-inv-202603-ember-cash', 'pay-inv-202603-ember', 'operating-cash', '2026-04-05', 289.0, 0.0),
('entry-pay-inv-202603-ember-receivable', 'pay-inv-202603-ember', 'accounts-receivable', '2026-04-05', 0.0, 289.0),
('entry-inv-202604-fieldnote-receivable', 'inv-202604-fieldnote', 'accounts-receivable', '2026-04-08', 99.0, 0.0),
('entry-inv-202604-fieldnote-revenue', 'inv-202604-fieldnote', 'subscription-revenue', '2026-04-08', 0.0, 99.0),
('entry-pay-inv-202603-fieldnote-cash', 'pay-inv-202603-fieldnote', 'operating-cash', '2026-04-08', 99.0, 0.0),
('entry-pay-inv-202603-fieldnote-receivable', 'pay-inv-202603-fieldnote', 'accounts-receivable', '2026-04-08', 0.0, 99.0),
('entry-inv-202604-harbor-receivable', 'inv-202604-harbor', 'accounts-receivable', '2026-04-11', 356.0, 0.0),
('entry-inv-202604-harbor-revenue', 'inv-202604-harbor', 'subscription-revenue', '2026-04-11', 0.0, 356.0),
('entry-pay-inv-202603-harbor-cash', 'pay-inv-202603-harbor', 'operating-cash', '2026-04-11', 356.0, 0.0),
('entry-pay-inv-202603-harbor-receivable', 'pay-inv-202603-harbor', 'accounts-receivable', '2026-04-11', 0.0, 356.0),
('entry-bill-202604-cedar-cash', 'bill-202604-cedar', 'operating-cash', '2026-04-12', 0.0, 184.0),
('entry-bill-202604-cedar-expense', 'bill-202604-cedar', 'operating-expense', '2026-04-12', 184.0, 0.0),
('entry-inv-202604-lumen-receivable', 'inv-202604-lumen', 'accounts-receivable', '2026-04-14', 412.0, 0.0),
('entry-inv-202604-lumen-revenue', 'inv-202604-lumen', 'subscription-revenue', '2026-04-14', 0.0, 412.0),
('entry-pay-inv-202603-lumen-cash', 'pay-inv-202603-lumen', 'operating-cash', '2026-04-30', 412.0, 0.0),
('entry-pay-inv-202603-lumen-receivable', 'pay-inv-202603-lumen', 'accounts-receivable', '2026-04-30', 0.0, 412.0),
('entry-bill-202605-cloudharbor-cash', 'bill-202605-cloudharbor', 'operating-cash', '2026-05-02', 0.0, 731.0),
('entry-bill-202605-cloudharbor-expense', 'bill-202605-cloudharbor', 'operating-expense', '2026-05-02', 731.0, 0.0),
('entry-inv-202605-ember-receivable', 'inv-202605-ember', 'accounts-receivable', '2026-05-05', 289.0, 0.0),
('entry-inv-202605-ember-revenue', 'inv-202605-ember', 'subscription-revenue', '2026-05-05', 0.0, 289.0),
('entry-pay-inv-202604-ember-cash', 'pay-inv-202604-ember', 'operating-cash', '2026-05-05', 289.0, 0.0),
('entry-pay-inv-202604-ember-receivable', 'pay-inv-202604-ember', 'accounts-receivable', '2026-05-05', 0.0, 289.0),
('entry-inv-202605-fieldnote-receivable', 'inv-202605-fieldnote', 'accounts-receivable', '2026-05-08', 99.0, 0.0),
('entry-inv-202605-fieldnote-revenue', 'inv-202605-fieldnote', 'subscription-revenue', '2026-05-08', 0.0, 99.0),
('entry-pay-inv-202604-fieldnote-cash', 'pay-inv-202604-fieldnote', 'operating-cash', '2026-05-08', 99.0, 0.0),
('entry-pay-inv-202604-fieldnote-receivable', 'pay-inv-202604-fieldnote', 'accounts-receivable', '2026-05-08', 0.0, 99.0),
('entry-inv-202605-harbor-receivable', 'inv-202605-harbor', 'accounts-receivable', '2026-05-11', 356.0, 0.0),
('entry-inv-202605-harbor-revenue', 'inv-202605-harbor', 'subscription-revenue', '2026-05-11', 0.0, 356.0),
('entry-pay-inv-202604-harbor-cash', 'pay-inv-202604-harbor', 'operating-cash', '2026-05-11', 356.0, 0.0),
('entry-pay-inv-202604-harbor-receivable', 'pay-inv-202604-harbor', 'accounts-receivable', '2026-05-11', 0.0, 356.0),
('entry-bill-202605-cedar-cash', 'bill-202605-cedar', 'operating-cash', '2026-05-12', 0.0, 184.0),
('entry-bill-202605-cedar-expense', 'bill-202605-cedar', 'operating-expense', '2026-05-12', 184.0, 0.0),
('entry-inv-202605-lumen-receivable', 'inv-202605-lumen', 'accounts-receivable', '2026-05-14', 412.0, 0.0),
('entry-inv-202605-lumen-revenue', 'inv-202605-lumen', 'subscription-revenue', '2026-05-14', 0.0, 412.0),
('entry-pay-inv-202604-lumen-cash', 'pay-inv-202604-lumen', 'operating-cash', '2026-05-30', 412.0, 0.0),
('entry-pay-inv-202604-lumen-receivable', 'pay-inv-202604-lumen', 'accounts-receivable', '2026-05-30', 0.0, 412.0),
('entry-bill-202606-cloudharbor-cash', 'bill-202606-cloudharbor', 'operating-cash', '2026-06-02', 0.0, 731.0),
('entry-bill-202606-cloudharbor-expense', 'bill-202606-cloudharbor', 'operating-expense', '2026-06-02', 731.0, 0.0),
('entry-inv-202606-ember-receivable', 'inv-202606-ember', 'accounts-receivable', '2026-06-05', 289.0, 0.0),
('entry-inv-202606-ember-revenue', 'inv-202606-ember', 'subscription-revenue', '2026-06-05', 0.0, 289.0),
('entry-pay-inv-202605-ember-cash', 'pay-inv-202605-ember', 'operating-cash', '2026-06-05', 289.0, 0.0),
('entry-pay-inv-202605-ember-receivable', 'pay-inv-202605-ember', 'accounts-receivable', '2026-06-05', 0.0, 289.0),
('entry-inv-202606-fieldnote-receivable', 'inv-202606-fieldnote', 'accounts-receivable', '2026-06-08', 99.0, 0.0),
('entry-inv-202606-fieldnote-revenue', 'inv-202606-fieldnote', 'subscription-revenue', '2026-06-08', 0.0, 99.0);
INSERT INTO ledger_entries (id, record_id, account, date, debit_usd, credit_usd) VALUES
('entry-pay-inv-202605-fieldnote-cash', 'pay-inv-202605-fieldnote', 'operating-cash', '2026-06-08', 99.0, 0.0),
('entry-pay-inv-202605-fieldnote-receivable', 'pay-inv-202605-fieldnote', 'accounts-receivable', '2026-06-08', 0.0, 99.0),
('entry-inv-202606-harbor-receivable', 'inv-202606-harbor', 'accounts-receivable', '2026-06-11', 356.0, 0.0),
('entry-inv-202606-harbor-revenue', 'inv-202606-harbor', 'subscription-revenue', '2026-06-11', 0.0, 356.0),
('entry-pay-inv-202605-harbor-cash', 'pay-inv-202605-harbor', 'operating-cash', '2026-06-11', 356.0, 0.0),
('entry-pay-inv-202605-harbor-receivable', 'pay-inv-202605-harbor', 'accounts-receivable', '2026-06-11', 0.0, 356.0),
('entry-bill-202606-cedar-cash', 'bill-202606-cedar', 'operating-cash', '2026-06-12', 0.0, 184.0),
('entry-bill-202606-cedar-expense', 'bill-202606-cedar', 'operating-expense', '2026-06-12', 184.0, 0.0),
('entry-inv-202606-lumen-receivable', 'inv-202606-lumen', 'accounts-receivable', '2026-06-14', 412.0, 0.0),
('entry-inv-202606-lumen-revenue', 'inv-202606-lumen', 'subscription-revenue', '2026-06-14', 0.0, 412.0),
('entry-pay-inv-202605-lumen-cash', 'pay-inv-202605-lumen', 'operating-cash', '2026-06-30', 412.0, 0.0),
('entry-pay-inv-202605-lumen-receivable', 'pay-inv-202605-lumen', 'accounts-receivable', '2026-06-30', 0.0, 412.0),
('entry-bill-202607-cloudharbor-cash', 'bill-202607-cloudharbor', 'operating-cash', '2026-07-02', 0.0, 731.0),
('entry-bill-202607-cloudharbor-expense', 'bill-202607-cloudharbor', 'operating-expense', '2026-07-02', 731.0, 0.0),
('entry-inv-202607-ember-receivable', 'inv-202607-ember', 'accounts-receivable', '2026-07-05', 289.0, 0.0),
('entry-inv-202607-ember-revenue', 'inv-202607-ember', 'subscription-revenue', '2026-07-05', 0.0, 289.0),
('entry-pay-inv-202606-ember-cash', 'pay-inv-202606-ember', 'operating-cash', '2026-07-05', 289.0, 0.0),
('entry-pay-inv-202606-ember-receivable', 'pay-inv-202606-ember', 'accounts-receivable', '2026-07-05', 0.0, 289.0),
('entry-inv-202607-fieldnote-receivable', 'inv-202607-fieldnote', 'accounts-receivable', '2026-07-08', 99.0, 0.0),
('entry-inv-202607-fieldnote-revenue', 'inv-202607-fieldnote', 'subscription-revenue', '2026-07-08', 0.0, 99.0),
('entry-pay-inv-202606-fieldnote-cash', 'pay-inv-202606-fieldnote', 'operating-cash', '2026-07-08', 99.0, 0.0),
('entry-pay-inv-202606-fieldnote-receivable', 'pay-inv-202606-fieldnote', 'accounts-receivable', '2026-07-08', 0.0, 99.0),
('entry-inv-202607-harbor-receivable', 'inv-202607-harbor', 'accounts-receivable', '2026-07-11', 356.0, 0.0),
('entry-inv-202607-harbor-revenue', 'inv-202607-harbor', 'subscription-revenue', '2026-07-11', 0.0, 356.0),
('entry-pay-inv-202606-harbor-cash', 'pay-inv-202606-harbor', 'operating-cash', '2026-07-11', 356.0, 0.0),
('entry-pay-inv-202606-harbor-receivable', 'pay-inv-202606-harbor', 'accounts-receivable', '2026-07-11', 0.0, 356.0),
('entry-bill-202607-cedar-cash', 'bill-202607-cedar', 'operating-cash', '2026-07-12', 0.0, 184.0),
('entry-bill-202607-cedar-expense', 'bill-202607-cedar', 'operating-expense', '2026-07-12', 184.0, 0.0),
('entry-inv-202607-lumen-receivable', 'inv-202607-lumen', 'accounts-receivable', '2026-07-14', 412.0, 0.0),
('entry-inv-202607-lumen-revenue', 'inv-202607-lumen', 'subscription-revenue', '2026-07-14', 0.0, 412.0),
('entry-pay-inv-202606-lumen-cash', 'pay-inv-202606-lumen', 'operating-cash', '2026-07-30', 412.0, 0.0),
('entry-pay-inv-202606-lumen-receivable', 'pay-inv-202606-lumen', 'accounts-receivable', '2026-07-30', 0.0, 412.0),
('entry-pay-inv-202607-ember-cash', 'pay-inv-202607-ember', 'operating-cash', '2026-08-05', 289.0, 0.0),
('entry-pay-inv-202607-ember-receivable', 'pay-inv-202607-ember', 'accounts-receivable', '2026-08-05', 0.0, 289.0),
('entry-pay-inv-202607-fieldnote-cash', 'pay-inv-202607-fieldnote', 'operating-cash', '2026-08-08', 99.0, 0.0),
('entry-pay-inv-202607-fieldnote-receivable', 'pay-inv-202607-fieldnote', 'accounts-receivable', '2026-08-08', 0.0, 99.0),
('entry-pay-inv-202607-harbor-cash', 'pay-inv-202607-harbor', 'operating-cash', '2026-08-11', 356.0, 0.0),
('entry-pay-inv-202607-harbor-receivable', 'pay-inv-202607-harbor', 'accounts-receivable', '2026-08-11', 0.0, 356.0),
('entry-inv-4471-receivable', 'inv-4471', 'accounts-receivable', '2026-08-14', 412.0, 0.0),
('entry-inv-4471-revenue', 'inv-4471', 'subscription-revenue', '2026-08-14', 0.0, 412.0),
('entry-pay-inv-202607-lumen-cash', 'pay-inv-202607-lumen', 'operating-cash', '2026-08-30', 412.0, 0.0),
('entry-pay-inv-202607-lumen-receivable', 'pay-inv-202607-lumen', 'accounts-receivable', '2026-08-30', 0.0, 412.0);
CREATE TABLE export_runs (
  run_id INTEGER PRIMARY KEY,
  started_at TEXT NOT NULL,
  customer_id TEXT REFERENCES customers(id),
  run_mode TEXT NOT NULL,
  row_count INTEGER NOT NULL,
  duration_s REAL NOT NULL,
  status TEXT NOT NULL,
  failure_reason TEXT
);
INSERT INTO export_runs (run_id, started_at, customer_id, run_mode, row_count, duration_s, status, failure_reason) VALUES
(1, '2026-02-22 02:15:19', 'lumen', 'scheduled', 22077, 41.5, 'succeeded', NULL),
(2, '2026-02-22 03:01:55', 'ember', 'scheduled', 6795, 12.8, 'succeeded', NULL),
(3, '2026-02-23 02:16:55', 'lumen', 'scheduled', 38550, 72.4, 'succeeded', NULL),
(4, '2026-02-23 03:01:07', 'ember', 'scheduled', 11893, 22.3, 'succeeded', NULL),
(5, '2026-02-23 05:32:18', 'harbor', 'scheduled', 27875, 52.4, 'succeeded', NULL),
(6, '2026-02-23 16:22:00', 'ember', 'interactive', 3513, 6.6, 'succeeded', NULL),
(7, '2026-02-24 02:18:33', 'lumen', 'scheduled', 39859, 74.9, 'succeeded', NULL),
(8, '2026-02-24 03:02:31', 'ember', 'scheduled', 12438, 23.4, 'succeeded', NULL),
(9, '2026-02-25 02:17:39', 'lumen', 'scheduled', 40296, 75.7, 'succeeded', NULL),
(10, '2026-02-25 03:00:37', 'ember', 'scheduled', 12645, 23.8, 'succeeded', NULL),
(11, '2026-02-25 13:53:00', 'lumen', 'interactive', 16520, 31.0, 'succeeded', NULL),
(12, '2026-02-26 02:15:15', 'lumen', 'scheduled', 39253, 73.7, 'succeeded', NULL),
(13, '2026-02-26 03:00:53', 'ember', 'scheduled', 11337, 21.3, 'succeeded', NULL),
(14, '2026-02-26 11:41:00', 'fieldnote', 'interactive', 649, 1.2, 'succeeded', NULL),
(15, '2026-02-27 02:18:37', 'lumen', 'scheduled', 38883, 73.0, 'succeeded', NULL),
(16, '2026-02-27 03:03:18', 'ember', 'scheduled', 12135, 22.8, 'succeeded', NULL),
(17, '2026-02-27 06:03:22', 'fieldnote', 'scheduled', 1596, 3.0, 'succeeded', NULL),
(18, '2026-02-27 13:33:00', 'lumen', 'interactive', 4857, 3.6, 'cancelled', 'cancelled by the requester'),
(19, '2026-02-28 02:18:40', 'lumen', 'scheduled', 24784, 46.6, 'succeeded', NULL),
(20, '2026-02-28 03:02:22', 'ember', 'scheduled', 7545, 14.2, 'succeeded', NULL),
(21, '2026-03-01 02:18:52', 'lumen', 'scheduled', 21939, 41.2, 'succeeded', NULL),
(22, '2026-03-01 03:03:50', 'ember', 'scheduled', 6592, 12.4, 'succeeded', NULL),
(23, '2026-03-02 02:16:39', 'lumen', 'scheduled', 39036, 73.3, 'succeeded', NULL),
(24, '2026-03-02 03:02:57', 'ember', 'scheduled', 11969, 22.5, 'succeeded', NULL),
(25, '2026-03-02 05:31:45', 'harbor', 'scheduled', 27297, 51.3, 'succeeded', NULL),
(26, '2026-03-03 02:17:36', 'lumen', 'scheduled', 40835, 76.7, 'succeeded', NULL),
(27, '2026-03-03 03:01:58', 'ember', 'scheduled', 12273, 23.1, 'succeeded', NULL),
(28, '2026-03-04 02:18:50', 'lumen', 'scheduled', 40733, 76.5, 'succeeded', NULL),
(29, '2026-03-04 03:00:05', 'ember', 'scheduled', 12273, 23.1, 'succeeded', NULL),
(30, '2026-03-04 11:09:00', 'ember', 'interactive', 5693, 10.7, 'succeeded', NULL),
(31, '2026-03-05 02:16:26', 'lumen', 'scheduled', 40376, 75.8, 'succeeded', NULL),
(32, '2026-03-05 03:01:13', 'ember', 'scheduled', 12466, 23.4, 'succeeded', NULL),
(33, '2026-03-05 16:24:00', 'fieldnote', 'interactive', 980, 1.8, 'succeeded', NULL),
(34, '2026-03-06 02:16:19', 'lumen', 'scheduled', 37983, 71.4, 'succeeded', NULL),
(35, '2026-03-06 03:00:46', 'ember', 'scheduled', 11589, 21.8, 'succeeded', NULL),
(36, '2026-03-06 06:00:04', 'fieldnote', 'scheduled', 2108, 4.0, 'succeeded', NULL),
(37, '2026-03-06 10:43:00', 'ember', 'interactive', 5143, 9.7, 'succeeded', NULL),
(38, '2026-03-07 02:15:14', 'lumen', 'scheduled', 24110, 45.3, 'succeeded', NULL),
(39, '2026-03-07 03:00:35', 'ember', 'scheduled', 6922, 13.0, 'succeeded', NULL),
(40, '2026-03-08 02:15:02', 'lumen', 'scheduled', 21523, 40.4, 'succeeded', NULL),
(41, '2026-03-08 03:02:38', 'ember', 'scheduled', 6240, 11.7, 'succeeded', NULL),
(42, '2026-03-09 02:18:56', 'lumen', 'scheduled', 40820, 76.7, 'succeeded', NULL),
(43, '2026-03-09 03:00:42', 'ember', 'scheduled', 11321, 21.3, 'succeeded', NULL),
(44, '2026-03-09 05:34:46', 'harbor', 'scheduled', 27497, 51.7, 'succeeded', NULL),
(45, '2026-03-09 15:42:00', 'harbor', 'interactive', 3544, 6.7, 'succeeded', NULL),
(46, '2026-03-10 02:17:09', 'lumen', 'scheduled', 41684, 78.3, 'succeeded', NULL),
(47, '2026-03-10 03:00:05', 'ember', 'scheduled', 12314, 23.1, 'succeeded', NULL),
(48, '2026-03-10 15:56:00', 'fieldnote', 'interactive', 1751, 3.3, 'succeeded', NULL),
(49, '2026-03-11 02:16:42', 'lumen', 'scheduled', 40557, 76.2, 'succeeded', NULL),
(50, '2026-03-11 03:03:25', 'ember', 'scheduled', 12768, 24.0, 'succeeded', NULL),
(51, '2026-03-11 14:23:00', 'fieldnote', 'interactive', 758, 1.4, 'succeeded', NULL),
(52, '2026-03-12 02:18:35', 'lumen', 'scheduled', 41657, 78.3, 'succeeded', NULL),
(53, '2026-03-12 03:00:20', 'ember', 'scheduled', 11302, 21.2, 'succeeded', NULL),
(54, '2026-03-12 13:49:00', 'fieldnote', 'interactive', 1580, 3.0, 'succeeded', NULL),
(55, '2026-03-13 02:15:37', 'lumen', 'scheduled', 38357, 72.1, 'succeeded', NULL),
(56, '2026-03-13 03:00:03', 'ember', 'scheduled', 11544, 21.7, 'succeeded', NULL),
(57, '2026-03-13 06:02:01', 'fieldnote', 'scheduled', 2025, 3.8, 'succeeded', NULL),
(58, '2026-03-14 02:17:37', 'lumen', 'scheduled', 25251, 47.4, 'succeeded', NULL),
(59, '2026-03-14 03:03:17', 'ember', 'scheduled', 7066, 13.3, 'succeeded', NULL),
(60, '2026-03-15 02:17:23', 'lumen', 'scheduled', 22892, 43.0, 'succeeded', NULL),
(61, '2026-03-15 03:03:19', 'ember', 'scheduled', 6779, 12.7, 'succeeded', NULL),
(62, '2026-03-16 02:18:34', 'lumen', 'scheduled', 41738, 78.4, 'succeeded', NULL),
(63, '2026-03-16 03:03:54', 'ember', 'scheduled', 11385, 21.4, 'succeeded', NULL),
(64, '2026-03-16 05:34:23', 'harbor', 'scheduled', 27854, 52.3, 'succeeded', NULL),
(65, '2026-03-16 10:27:00', 'lumen', 'interactive', 9851, 18.5, 'succeeded', NULL),
(66, '2026-03-17 02:16:09', 'lumen', 'scheduled', 40648, 76.4, 'succeeded', NULL),
(67, '2026-03-17 03:03:00', 'ember', 'scheduled', 11745, 22.1, 'succeeded', NULL),
(68, '2026-03-18 02:17:44', 'lumen', 'scheduled', 41063, 77.1, 'succeeded', NULL),
(69, '2026-03-18 03:00:42', 'ember', 'scheduled', 12157, 22.8, 'succeeded', NULL),
(70, '2026-03-19 02:15:48', 'lumen', 'scheduled', 41751, 78.4, 'succeeded', NULL),
(71, '2026-03-19 03:00:30', 'ember', 'scheduled', 12605, 23.7, 'succeeded', NULL),
(72, '2026-03-19 11:47:00', 'lumen', 'interactive', 5625, 10.6, 'succeeded', NULL),
(73, '2026-03-20 02:16:08', 'lumen', 'scheduled', 40785, 76.6, 'succeeded', NULL),
(74, '2026-03-20 03:03:40', 'ember', 'scheduled', 11709, 22.0, 'succeeded', NULL),
(75, '2026-03-20 06:02:53', 'fieldnote', 'scheduled', 2014, 3.8, 'succeeded', NULL),
(76, '2026-03-21 02:17:40', 'lumen', 'scheduled', 25664, 48.2, 'succeeded', NULL),
(77, '2026-03-21 03:00:03', 'ember', 'scheduled', 7673, 14.4, 'succeeded', NULL),
(78, '2026-03-22 02:17:12', 'lumen', 'scheduled', 22795, 42.8, 'succeeded', NULL),
(79, '2026-03-22 03:01:51', 'ember', 'scheduled', 6281, 11.8, 'succeeded', NULL),
(80, '2026-03-23 02:18:22', 'lumen', 'scheduled', 42269, 79.4, 'succeeded', NULL),
(81, '2026-03-23 03:03:41', 'ember', 'scheduled', 11273, 21.2, 'succeeded', NULL),
(82, '2026-03-23 05:32:07', 'harbor', 'scheduled', 27246, 51.2, 'succeeded', NULL),
(83, '2026-03-23 15:36:00', 'lumen', 'interactive', 15650, 29.4, 'succeeded', NULL),
(84, '2026-03-24 02:17:14', 'lumen', 'scheduled', 41688, 78.3, 'succeeded', NULL),
(85, '2026-03-24 03:02:36', 'ember', 'scheduled', 12173, 22.9, 'succeeded', NULL),
(86, '2026-03-24 13:49:00', 'ember', 'interactive', 4809, 9.0, 'succeeded', NULL),
(87, '2026-03-25 02:17:21', 'lumen', 'scheduled', 41392, 77.8, 'succeeded', NULL),
(88, '2026-03-25 03:03:34', 'ember', 'scheduled', 12429, 23.3, 'succeeded', NULL),
(89, '2026-03-26 02:18:49', 'lumen', 'scheduled', 41422, 77.8, 'succeeded', NULL),
(90, '2026-03-26 03:01:15', 'ember', 'scheduled', 11547, 21.7, 'succeeded', NULL),
(91, '2026-03-26 14:05:00', 'lumen', 'interactive', 5328, 10.0, 'succeeded', NULL),
(92, '2026-03-27 02:15:50', 'lumen', 'scheduled', 39652, 74.5, 'succeeded', NULL),
(93, '2026-03-27 03:00:36', 'ember', 'scheduled', 12197, 22.9, 'succeeded', NULL),
(94, '2026-03-27 06:03:52', 'fieldnote', 'scheduled', 1980, 3.7, 'succeeded', NULL),
(95, '2026-03-27 11:52:00', 'harbor', 'interactive', 11245, 21.1, 'succeeded', NULL),
(96, '2026-03-28 02:18:38', 'lumen', 'scheduled', 26330, 49.5, 'succeeded', NULL),
(97, '2026-03-28 03:00:48', 'ember', 'scheduled', 7359, 13.8, 'succeeded', NULL),
(98, '2026-03-29 02:16:26', 'lumen', 'scheduled', 22872, 43.0, 'succeeded', NULL),
(99, '2026-03-29 03:01:35', 'ember', 'scheduled', 6723, 12.6, 'succeeded', NULL),
(100, '2026-03-30 02:17:13', 'lumen', 'scheduled', 42588, 80.0, 'succeeded', NULL);
INSERT INTO export_runs (run_id, started_at, customer_id, run_mode, row_count, duration_s, status, failure_reason) VALUES
(101, '2026-03-30 03:02:57', 'ember', 'scheduled', 11903, 22.4, 'succeeded', NULL),
(102, '2026-03-30 05:31:35', 'harbor', 'scheduled', 28365, 53.3, 'succeeded', NULL),
(103, '2026-03-30 16:34:00', 'ember', 'interactive', 2398, 4.5, 'succeeded', NULL),
(104, '2026-03-31 02:16:59', 'lumen', 'scheduled', 42969, 80.7, 'succeeded', NULL),
(105, '2026-03-31 03:03:50', 'ember', 'scheduled', 11731, 22.0, 'succeeded', NULL),
(106, '2026-04-01 02:17:29', 'lumen', 'scheduled', 42002, 78.9, 'succeeded', NULL),
(107, '2026-04-01 03:02:24', 'ember', 'scheduled', 12869, 24.2, 'succeeded', NULL),
(108, '2026-04-02 02:16:07', 'lumen', 'scheduled', 42445, 79.7, 'succeeded', NULL),
(109, '2026-04-02 03:00:19', 'ember', 'scheduled', 12635, 23.7, 'succeeded', NULL),
(110, '2026-04-02 12:35:00', 'harbor', 'interactive', 11800, 22.2, 'succeeded', NULL),
(111, '2026-04-03 02:15:47', 'lumen', 'scheduled', 40667, 76.4, 'succeeded', NULL),
(112, '2026-04-03 03:02:01', 'ember', 'scheduled', 11306, 21.2, 'succeeded', NULL),
(113, '2026-04-03 06:01:31', 'fieldnote', 'scheduled', 1669, 3.1, 'succeeded', NULL),
(114, '2026-04-04 02:15:45', 'lumen', 'scheduled', 25665, 48.2, 'succeeded', NULL),
(115, '2026-04-04 03:03:45', 'ember', 'scheduled', 7398, 13.9, 'succeeded', NULL),
(116, '2026-04-05 02:15:54', 'lumen', 'scheduled', 23735, 44.6, 'succeeded', NULL),
(117, '2026-04-05 03:02:32', 'ember', 'scheduled', 6267, 11.8, 'succeeded', NULL),
(118, '2026-04-06 02:18:10', 'lumen', 'scheduled', 41171, 77.3, 'succeeded', NULL),
(119, '2026-04-06 03:03:51', 'ember', 'scheduled', 12655, 23.8, 'succeeded', NULL),
(120, '2026-04-06 05:32:13', 'harbor', 'scheduled', 28516, 53.6, 'succeeded', NULL),
(121, '2026-04-07 02:17:50', 'lumen', 'scheduled', 42394, 79.6, 'succeeded', NULL),
(122, '2026-04-07 03:00:14', 'ember', 'scheduled', 11832, 22.2, 'succeeded', NULL),
(123, '2026-04-08 02:17:42', 'lumen', 'scheduled', 44680, 83.9, 'succeeded', NULL),
(124, '2026-04-08 03:00:16', 'ember', 'scheduled', 12848, 24.1, 'succeeded', NULL),
(125, '2026-04-08 12:34:00', 'lumen', 'interactive', 8182, 15.4, 'succeeded', NULL),
(126, '2026-04-09 02:18:42', 'lumen', 'scheduled', 43022, 80.8, 'succeeded', NULL),
(127, '2026-04-09 03:03:51', 'ember', 'scheduled', 12044, 22.6, 'succeeded', NULL),
(128, '2026-04-09 11:57:00', 'lumen', 'interactive', 6085, 11.4, 'succeeded', NULL),
(129, '2026-04-10 02:15:27', 'lumen', 'scheduled', 40545, 76.2, 'succeeded', NULL),
(130, '2026-04-10 03:00:33', 'ember', 'scheduled', 11256, 21.1, 'succeeded', NULL),
(131, '2026-04-10 06:02:46', 'fieldnote', 'scheduled', 1858, 3.5, 'succeeded', NULL),
(132, '2026-04-11 02:15:49', 'lumen', 'scheduled', 26329, 49.5, 'succeeded', NULL),
(133, '2026-04-11 03:00:34', 'ember', 'scheduled', 7445, 14.0, 'succeeded', NULL),
(134, '2026-04-12 02:18:03', 'lumen', 'scheduled', 23549, 44.2, 'succeeded', NULL),
(135, '2026-04-12 03:00:41', 'ember', 'scheduled', 6653, 12.5, 'succeeded', NULL),
(136, '2026-04-13 02:16:39', 'lumen', 'scheduled', 42046, 79.0, 'succeeded', NULL),
(137, '2026-04-13 03:01:43', 'ember', 'scheduled', 12766, 24.0, 'succeeded', NULL),
(138, '2026-04-13 05:31:58', 'harbor', 'scheduled', 27633, 51.9, 'succeeded', NULL),
(139, '2026-04-13 09:50:00', 'fieldnote', 'interactive', 1800, 3.4, 'succeeded', NULL),
(140, '2026-04-14 02:16:38', 'lumen', 'scheduled', 44744, 84.1, 'succeeded', NULL),
(141, '2026-04-14 03:02:15', 'ember', 'scheduled', 11908, 22.4, 'succeeded', NULL),
(142, '2026-04-15 02:17:55', 'lumen', 'scheduled', 44808, 84.2, 'succeeded', NULL),
(143, '2026-04-15 03:03:11', 'ember', 'scheduled', 12375, 23.2, 'succeeded', NULL),
(144, '2026-04-16 02:15:30', 'lumen', 'scheduled', 42809, 80.4, 'succeeded', NULL),
(145, '2026-04-16 03:01:55', 'ember', 'scheduled', 12857, 24.2, 'succeeded', NULL),
(146, '2026-04-16 13:00:00', 'lumen', 'interactive', 6779, 12.7, 'succeeded', NULL),
(147, '2026-04-17 02:17:34', 'lumen', 'scheduled', 40991, 77.0, 'succeeded', NULL),
(148, '2026-04-17 03:02:59', 'ember', 'scheduled', 12495, 23.5, 'succeeded', NULL),
(149, '2026-04-17 06:03:32', 'fieldnote', 'scheduled', 1622, 3.0, 'succeeded', NULL),
(150, '2026-04-18 02:16:52', 'lumen', 'scheduled', 26861, 50.5, 'succeeded', NULL),
(151, '2026-04-18 03:00:17', 'ember', 'scheduled', 7840, 14.7, 'succeeded', NULL),
(152, '2026-04-19 02:15:14', 'lumen', 'scheduled', 23897, 44.9, 'succeeded', NULL),
(153, '2026-04-19 03:03:09', 'ember', 'scheduled', 6516, 12.2, 'succeeded', NULL),
(154, '2026-04-20 02:16:26', 'lumen', 'scheduled', 43577, 81.9, 'succeeded', NULL),
(155, '2026-04-20 03:03:41', 'ember', 'scheduled', 12307, 23.1, 'succeeded', NULL),
(156, '2026-04-20 05:34:11', 'harbor', 'scheduled', 28923, 54.3, 'succeeded', NULL),
(157, '2026-04-20 14:47:00', 'fieldnote', 'interactive', 641, 1.2, 'succeeded', NULL),
(158, '2026-04-21 02:15:40', 'lumen', 'scheduled', 45355, 85.3, 'succeeded', NULL),
(159, '2026-04-21 03:02:01', 'ember', 'scheduled', 11778, 22.1, 'succeeded', NULL),
(160, '2026-04-22 02:18:20', 'lumen', 'scheduled', 43448, 81.6, 'succeeded', NULL),
(161, '2026-04-22 03:00:01', 'ember', 'scheduled', 13060, 24.5, 'succeeded', NULL),
(162, '2026-04-23 02:16:29', 'lumen', 'scheduled', 44648, 83.9, 'succeeded', NULL),
(163, '2026-04-23 03:02:23', 'ember', 'scheduled', 12334, 23.2, 'succeeded', NULL),
(164, '2026-04-24 02:15:06', 'lumen', 'scheduled', 43264, 81.3, 'succeeded', NULL),
(165, '2026-04-24 03:02:38', 'ember', 'scheduled', 11955, 22.5, 'succeeded', NULL),
(166, '2026-04-24 06:00:52', 'fieldnote', 'scheduled', 1888, 3.5, 'succeeded', NULL),
(167, '2026-04-25 02:18:21', 'lumen', 'scheduled', 27090, 50.9, 'succeeded', NULL),
(168, '2026-04-25 03:02:50', 'ember', 'scheduled', 7910, 14.9, 'succeeded', NULL),
(169, '2026-04-26 02:17:44', 'lumen', 'scheduled', 23566, 44.3, 'succeeded', NULL),
(170, '2026-04-26 03:01:07', 'ember', 'scheduled', 6842, 12.9, 'succeeded', NULL),
(171, '2026-04-27 02:15:28', 'lumen', 'scheduled', 44869, 84.3, 'succeeded', NULL),
(172, '2026-04-27 03:00:57', 'ember', 'scheduled', 12505, 23.5, 'succeeded', NULL),
(173, '2026-04-27 05:30:53', 'harbor', 'scheduled', 29134, 54.7, 'succeeded', NULL),
(174, '2026-04-28 02:17:41', 'lumen', 'scheduled', 45402, 85.4, 'succeeded', NULL),
(175, '2026-04-28 03:03:42', 'ember', 'scheduled', 12618, 23.7, 'succeeded', NULL),
(176, '2026-04-28 09:28:00', 'lumen', 'interactive', 17544, 33.0, 'succeeded', NULL),
(177, '2026-04-29 02:15:44', 'lumen', 'scheduled', 45671, 86.0, 'succeeded', NULL),
(178, '2026-04-29 03:03:37', 'ember', 'scheduled', 12679, 23.8, 'succeeded', NULL),
(179, '2026-04-29 15:03:00', 'lumen', 'interactive', 5365, 10.1, 'succeeded', NULL),
(180, '2026-04-30 02:15:06', 'lumen', 'scheduled', 44517, 83.6, 'succeeded', NULL),
(181, '2026-04-30 03:00:14', 'ember', 'scheduled', 11787, 22.1, 'succeeded', NULL),
(182, '2026-05-01 02:18:34', 'lumen', 'scheduled', 42938, 80.7, 'succeeded', NULL),
(183, '2026-05-01 03:03:58', 'ember', 'scheduled', 11891, 22.3, 'succeeded', NULL),
(184, '2026-05-01 06:04:21', 'fieldnote', 'scheduled', 1588, 3.0, 'succeeded', NULL),
(185, '2026-05-01 11:40:00', 'lumen', 'interactive', 11659, 21.9, 'succeeded', NULL),
(186, '2026-05-02 02:16:36', 'lumen', 'scheduled', 26668, 50.1, 'succeeded', NULL),
(187, '2026-05-02 03:03:20', 'ember', 'scheduled', 7563, 14.2, 'succeeded', NULL),
(188, '2026-05-03 02:18:06', 'lumen', 'scheduled', 24378, 45.8, 'succeeded', NULL),
(189, '2026-05-03 03:01:56', 'ember', 'scheduled', 6658, 12.5, 'succeeded', NULL),
(190, '2026-05-04 02:17:28', 'lumen', 'scheduled', 43120, 81.0, 'succeeded', NULL),
(191, '2026-05-04 03:03:13', 'ember', 'scheduled', 11873, 22.3, 'succeeded', NULL),
(192, '2026-05-04 05:31:15', 'harbor', 'scheduled', 27872, 52.4, 'succeeded', NULL),
(193, '2026-05-05 02:15:33', 'lumen', 'scheduled', 45607, 85.8, 'succeeded', NULL),
(194, '2026-05-05 03:01:41', 'ember', 'scheduled', 12247, 23.0, 'succeeded', NULL),
(195, '2026-05-06 02:15:52', 'lumen', 'scheduled', 45123, 84.8, 'succeeded', NULL),
(196, '2026-05-06 03:03:20', 'ember', 'scheduled', 12493, 23.5, 'succeeded', NULL),
(197, '2026-05-06 09:24:00', 'ember', 'interactive', 3827, 7.2, 'succeeded', NULL),
(198, '2026-05-07 02:17:04', 'lumen', 'scheduled', 45270, 85.1, 'succeeded', NULL),
(199, '2026-05-07 03:03:21', 'ember', 'scheduled', 11584, 21.8, 'succeeded', NULL),
(200, '2026-05-08 02:17:33', 'lumen', 'scheduled', 44055, 82.8, 'succeeded', NULL);
INSERT INTO export_runs (run_id, started_at, customer_id, run_mode, row_count, duration_s, status, failure_reason) VALUES
(201, '2026-05-08 03:02:08', 'ember', 'scheduled', 12157, 22.8, 'succeeded', NULL),
(202, '2026-05-08 06:03:57', 'fieldnote', 'scheduled', 2101, 3.9, 'succeeded', NULL),
(203, '2026-05-08 14:11:00', 'fieldnote', 'interactive', 808, 1.5, 'succeeded', NULL),
(204, '2026-05-09 02:17:55', 'lumen', 'scheduled', 28393, 53.3, 'succeeded', NULL),
(205, '2026-05-09 03:03:14', 'ember', 'scheduled', 7439, 14.0, 'succeeded', NULL),
(206, '2026-05-10 02:15:35', 'lumen', 'scheduled', 24132, 45.3, 'succeeded', NULL),
(207, '2026-05-10 03:00:08', 'ember', 'scheduled', 6746, 12.7, 'succeeded', NULL),
(208, '2026-05-11 02:15:22', 'lumen', 'scheduled', 44802, 84.2, 'succeeded', NULL),
(209, '2026-05-11 03:03:49', 'ember', 'scheduled', 12436, 23.4, 'succeeded', NULL),
(210, '2026-05-11 05:30:59', 'harbor', 'scheduled', 28911, 54.3, 'succeeded', NULL),
(211, '2026-05-12 02:17:14', 'lumen', 'scheduled', 46995, 90.0, 'succeeded', NULL),
(212, '2026-05-12 03:03:29', 'ember', 'scheduled', 13119, 24.6, 'succeeded', NULL),
(213, '2026-05-12 14:23:00', 'lumen', 'interactive', 4727, 8.9, 'succeeded', NULL),
(214, '2026-05-13 02:15:38', 'lumen', 'scheduled', 45376, 85.3, 'succeeded', NULL),
(215, '2026-05-13 03:02:47', 'ember', 'scheduled', 12718, 23.9, 'succeeded', NULL),
(216, '2026-05-13 11:13:00', 'fieldnote', 'interactive', 1465, 2.8, 'succeeded', NULL),
(217, '2026-05-14 02:15:21', 'lumen', 'scheduled', 46770, 89.2, 'succeeded', NULL),
(218, '2026-05-14 03:01:24', 'ember', 'scheduled', 12508, 23.5, 'succeeded', NULL),
(219, '2026-05-14 12:23:00', 'harbor', 'interactive', 10329, 19.4, 'succeeded', NULL),
(220, '2026-05-15 02:17:56', 'lumen', 'scheduled', 44899, 84.3, 'succeeded', NULL),
(221, '2026-05-15 03:01:28', 'ember', 'scheduled', 11896, 22.3, 'succeeded', NULL),
(222, '2026-05-15 06:03:58', 'fieldnote', 'scheduled', 1981, 3.7, 'succeeded', NULL),
(223, '2026-05-15 10:17:00', 'lumen', 'interactive', 18571, 34.9, 'succeeded', NULL),
(224, '2026-05-16 02:18:52', 'lumen', 'scheduled', 28325, 53.2, 'succeeded', NULL),
(225, '2026-05-16 03:02:32', 'ember', 'scheduled', 7916, 14.9, 'succeeded', NULL),
(226, '2026-05-17 02:18:43', 'lumen', 'scheduled', 24250, 45.6, 'succeeded', NULL),
(227, '2026-05-17 03:01:20', 'ember', 'scheduled', 6484, 12.2, 'succeeded', NULL),
(228, '2026-05-18 02:17:43', 'lumen', 'scheduled', 44224, 83.1, 'succeeded', NULL),
(229, '2026-05-18 03:03:49', 'ember', 'scheduled', 11506, 21.6, 'succeeded', NULL),
(230, '2026-05-18 05:33:58', 'harbor', 'scheduled', 27908, 52.4, 'succeeded', NULL),
(231, '2026-05-18 10:58:00', 'ember', 'interactive', 3056, 5.7, 'succeeded', NULL),
(232, '2026-05-19 02:17:14', 'lumen', 'scheduled', 46563, 88.5, 'succeeded', NULL),
(233, '2026-05-19 03:00:45', 'ember', 'scheduled', 11881, 22.3, 'succeeded', NULL),
(234, '2026-05-20 02:18:12', 'lumen', 'scheduled', 48126, 94.6, 'succeeded', NULL),
(235, '2026-05-20 03:03:18', 'ember', 'scheduled', 12415, 23.3, 'succeeded', NULL),
(236, '2026-05-20 11:29:00', 'ember', 'interactive', 3305, 6.2, 'succeeded', NULL),
(237, '2026-05-21 02:16:35', 'lumen', 'scheduled', 47489, 91.8, 'succeeded', NULL),
(238, '2026-05-21 03:03:16', 'ember', 'scheduled', 12230, 23.0, 'succeeded', NULL),
(239, '2026-05-21 09:12:00', 'harbor', 'interactive', 4260, 3.2, 'cancelled', 'cancelled by the requester'),
(240, '2026-05-22 02:18:04', 'lumen', 'scheduled', 44202, 83.0, 'succeeded', NULL),
(241, '2026-05-22 03:02:10', 'ember', 'scheduled', 11416, 21.4, 'succeeded', NULL),
(242, '2026-05-22 06:03:34', 'fieldnote', 'scheduled', 1999, 3.8, 'succeeded', NULL),
(243, '2026-05-22 09:44:00', 'ember', 'interactive', 4342, 8.2, 'succeeded', NULL),
(244, '2026-05-23 02:15:16', 'lumen', 'scheduled', 29061, 54.6, 'succeeded', NULL),
(245, '2026-05-23 03:02:11', 'ember', 'scheduled', 7952, 14.9, 'succeeded', NULL),
(246, '2026-05-24 02:15:14', 'lumen', 'scheduled', 24709, 46.4, 'succeeded', NULL),
(247, '2026-05-24 03:03:37', 'ember', 'scheduled', 6354, 11.9, 'succeeded', NULL),
(248, '2026-05-25 02:17:27', 'lumen', 'scheduled', 47317, 91.2, 'succeeded', NULL),
(249, '2026-05-25 03:00:26', 'ember', 'scheduled', 12296, 23.1, 'succeeded', NULL),
(250, '2026-05-25 05:32:54', 'harbor', 'scheduled', 30158, 56.7, 'succeeded', NULL),
(251, '2026-05-25 11:15:00', 'lumen', 'interactive', 8149, 15.3, 'succeeded', NULL),
(252, '2026-05-26 02:15:48', 'lumen', 'scheduled', 48096, 94.4, 'succeeded', NULL),
(253, '2026-05-26 03:01:33', 'ember', 'scheduled', 12561, 23.6, 'succeeded', NULL),
(254, '2026-05-27 02:16:03', 'lumen', 'scheduled', 48535, 96.5, 'succeeded', NULL),
(255, '2026-05-27 03:03:17', 'ember', 'scheduled', 12673, 23.8, 'succeeded', NULL),
(256, '2026-05-28 02:18:21', 'lumen', 'scheduled', 45790, 86.3, 'succeeded', NULL),
(257, '2026-05-28 03:03:04', 'ember', 'scheduled', 12854, 24.1, 'succeeded', NULL),
(258, '2026-05-29 02:15:53', 'lumen', 'scheduled', 45983, 86.8, 'succeeded', NULL),
(259, '2026-05-29 03:03:51', 'ember', 'scheduled', 11666, 21.9, 'succeeded', NULL),
(260, '2026-05-29 06:03:26', 'fieldnote', 'scheduled', 2042, 3.8, 'succeeded', NULL),
(261, '2026-05-29 14:25:00', 'harbor', 'interactive', 5022, 9.4, 'succeeded', NULL),
(262, '2026-05-30 02:17:58', 'lumen', 'scheduled', 28434, 53.4, 'succeeded', NULL),
(263, '2026-05-30 03:00:02', 'ember', 'scheduled', 7383, 13.9, 'succeeded', NULL),
(264, '2026-05-31 02:16:01', 'lumen', 'scheduled', 26034, 48.9, 'succeeded', NULL),
(265, '2026-05-31 03:02:13', 'ember', 'scheduled', 6534, 12.3, 'succeeded', NULL),
(266, '2026-06-01 02:15:26', 'lumen', 'scheduled', 46822, 89.4, 'succeeded', NULL),
(267, '2026-06-01 03:00:24', 'ember', 'scheduled', 12420, 23.3, 'succeeded', NULL),
(268, '2026-06-01 05:32:11', 'harbor', 'scheduled', 30289, 56.9, 'succeeded', NULL),
(269, '2026-06-02 02:19:00', 'lumen', 'scheduled', 47155, 90.6, 'succeeded', NULL),
(270, '2026-06-02 03:01:09', 'ember', 'scheduled', 11855, 22.3, 'succeeded', NULL),
(271, '2026-06-02 12:16:00', 'fieldnote', 'interactive', 761, 1.4, 'succeeded', NULL),
(272, '2026-06-03 02:17:36', 'lumen', 'scheduled', 49346, 100.7, 'succeeded', NULL),
(273, '2026-06-03 03:00:37', 'ember', 'scheduled', 13212, 24.8, 'succeeded', NULL),
(274, '2026-06-03 12:55:00', 'ember', 'interactive', 2752, 2.1, 'cancelled', 'cancelled by the requester'),
(275, '2026-06-04 02:17:39', 'lumen', 'scheduled', 47728, 92.8, 'succeeded', NULL),
(276, '2026-06-04 03:03:49', 'ember', 'scheduled', 12113, 22.8, 'succeeded', NULL),
(277, '2026-06-04 10:59:00', 'ember', 'interactive', 2213, 4.2, 'succeeded', NULL),
(278, '2026-06-05 02:16:27', 'lumen', 'scheduled', 44691, 84.0, 'succeeded', NULL),
(279, '2026-06-05 03:03:21', 'ember', 'scheduled', 11703, 22.0, 'succeeded', NULL),
(280, '2026-06-05 06:02:54', 'fieldnote', 'scheduled', 1776, 3.3, 'succeeded', NULL),
(281, '2026-06-06 02:18:12', 'lumen', 'scheduled', 29942, 56.2, 'succeeded', NULL),
(282, '2026-06-06 03:02:46', 'ember', 'scheduled', 7739, 14.5, 'succeeded', NULL),
(283, '2026-06-07 02:15:24', 'lumen', 'scheduled', 25861, 48.6, 'succeeded', NULL),
(284, '2026-06-07 03:03:40', 'ember', 'scheduled', 6955, 13.1, 'succeeded', NULL),
(285, '2026-06-08 02:18:16', 'lumen', 'scheduled', 47972, 93.9, 'succeeded', NULL),
(286, '2026-06-08 03:03:47', 'ember', 'scheduled', 12622, 23.7, 'succeeded', NULL),
(287, '2026-06-08 05:34:40', 'harbor', 'scheduled', 28780, 54.1, 'succeeded', NULL),
(288, '2026-06-08 09:15:00', 'lumen', 'interactive', 9426, 17.7, 'succeeded', NULL),
(289, '2026-06-09 02:16:15', 'lumen', 'scheduled', 48302, 95.4, 'succeeded', NULL),
(290, '2026-06-09 03:03:27', 'ember', 'scheduled', 12351, 23.2, 'succeeded', NULL),
(291, '2026-06-09 10:04:00', 'fieldnote', 'interactive', 1938, 3.6, 'succeeded', NULL),
(292, '2026-06-10 02:17:04', 'lumen', 'scheduled', 47600, 92.3, 'succeeded', NULL),
(293, '2026-06-10 03:03:00', 'ember', 'scheduled', 12271, 23.1, 'succeeded', NULL),
(294, '2026-06-11 02:17:57', 'lumen', 'scheduled', 47601, 92.3, 'succeeded', NULL),
(295, '2026-06-11 03:02:03', 'ember', 'scheduled', 11920, 22.4, 'succeeded', NULL),
(296, '2026-06-11 15:56:00', 'lumen', 'interactive', 7611, 14.3, 'succeeded', NULL),
(297, '2026-06-12 02:15:02', 'lumen', 'scheduled', 45566, 85.7, 'succeeded', NULL),
(298, '2026-06-12 03:02:35', 'ember', 'scheduled', 11835, 22.2, 'succeeded', NULL),
(299, '2026-06-12 06:04:47', 'fieldnote', 'scheduled', 1626, 3.1, 'succeeded', NULL),
(300, '2026-06-12 16:53:00', 'lumen', 'interactive', 11206, 21.1, 'succeeded', NULL);
INSERT INTO export_runs (run_id, started_at, customer_id, run_mode, row_count, duration_s, status, failure_reason) VALUES
(301, '2026-06-13 02:18:03', 'lumen', 'scheduled', 30087, 56.5, 'succeeded', NULL),
(302, '2026-06-13 03:00:00', 'ember', 'scheduled', 7736, 14.5, 'succeeded', NULL),
(303, '2026-06-14 02:16:27', 'lumen', 'scheduled', 26226, 49.3, 'succeeded', NULL),
(304, '2026-06-14 03:02:50', 'ember', 'scheduled', 6439, 12.1, 'succeeded', NULL),
(305, '2026-06-15 02:16:56', 'lumen', 'scheduled', 48260, 95.2, 'succeeded', NULL),
(306, '2026-06-15 03:00:53', 'ember', 'scheduled', 12719, 23.9, 'succeeded', NULL),
(307, '2026-06-15 05:31:07', 'harbor', 'scheduled', 30302, 56.9, 'succeeded', NULL),
(308, '2026-06-16 02:17:55', 'lumen', 'scheduled', 49303, 100.5, 'succeeded', NULL),
(309, '2026-06-16 03:01:50', 'ember', 'scheduled', 12659, 23.8, 'succeeded', NULL),
(310, '2026-06-17 02:17:14', 'lumen', 'scheduled', 50454, 107.4, 'succeeded', NULL),
(311, '2026-06-17 03:01:13', 'ember', 'scheduled', 12816, 24.1, 'succeeded', NULL),
(312, '2026-06-17 11:20:00', 'lumen', 'interactive', 8981, 16.9, 'succeeded', NULL),
(313, '2026-06-18 02:18:25', 'lumen', 'scheduled', 47581, 92.2, 'succeeded', NULL),
(314, '2026-06-18 03:01:47', 'ember', 'scheduled', 12617, 23.7, 'succeeded', NULL),
(315, '2026-06-18 11:32:00', 'ember', 'interactive', 4524, 8.5, 'succeeded', NULL),
(316, '2026-06-19 02:18:02', 'lumen', 'scheduled', 46149, 87.3, 'succeeded', NULL),
(317, '2026-06-19 03:03:45', 'ember', 'scheduled', 12492, 23.5, 'succeeded', NULL),
(318, '2026-06-19 06:04:30', 'fieldnote', 'scheduled', 1625, 3.1, 'succeeded', NULL),
(319, '2026-06-19 16:54:00', 'lumen', 'interactive', 20952, 39.4, 'succeeded', NULL),
(320, '2026-06-20 02:15:10', 'lumen', 'scheduled', 29696, 55.8, 'succeeded', NULL),
(321, '2026-06-20 03:00:20', 'ember', 'scheduled', 7504, 14.1, 'succeeded', NULL),
(322, '2026-06-21 02:16:07', 'lumen', 'scheduled', 26607, 50.0, 'succeeded', NULL),
(323, '2026-06-21 03:01:31', 'ember', 'scheduled', 6491, 12.2, 'succeeded', NULL),
(324, '2026-06-22 02:16:38', 'lumen', 'scheduled', 49420, 101.2, 'succeeded', NULL),
(325, '2026-06-22 03:02:56', 'ember', 'scheduled', 12187, 22.9, 'succeeded', NULL),
(326, '2026-06-22 05:34:47', 'harbor', 'scheduled', 28517, 53.6, 'succeeded', NULL),
(327, '2026-06-23 02:18:44', 'lumen', 'scheduled', 50578, 108.3, 'succeeded', NULL),
(328, '2026-06-23 03:03:14', 'ember', 'scheduled', 12483, 23.4, 'succeeded', NULL),
(329, '2026-06-23 15:12:00', 'ember', 'interactive', 6758, 12.7, 'succeeded', NULL),
(330, '2026-06-24 02:17:23', 'lumen', 'scheduled', 50237, 106.0, 'succeeded', NULL),
(331, '2026-06-24 03:02:39', 'ember', 'scheduled', 12456, 23.4, 'succeeded', NULL),
(332, '2026-06-25 02:16:42', 'lumen', 'scheduled', 47682, 92.6, 'succeeded', NULL),
(333, '2026-06-25 03:02:33', 'ember', 'scheduled', 11947, 22.4, 'succeeded', NULL),
(334, '2026-06-26 02:16:07', 'lumen', 'scheduled', 47637, 92.4, 'succeeded', NULL),
(335, '2026-06-26 03:01:59', 'ember', 'scheduled', 12360, 23.2, 'succeeded', NULL),
(336, '2026-06-26 06:00:29', 'fieldnote', 'scheduled', 1751, 3.3, 'succeeded', NULL),
(337, '2026-06-26 09:41:00', 'lumen', 'interactive', 15255, 28.7, 'succeeded', NULL),
(338, '2026-06-27 02:16:26', 'lumen', 'scheduled', 30571, 57.4, 'succeeded', NULL),
(339, '2026-06-27 03:01:50', 'ember', 'scheduled', 7579, 14.2, 'succeeded', NULL),
(340, '2026-06-28 02:16:04', 'lumen', 'scheduled', 26489, 49.8, 'succeeded', NULL),
(341, '2026-06-28 03:03:03', 'ember', 'scheduled', 6935, 13.0, 'succeeded', NULL),
(342, '2026-06-29 02:18:20', 'lumen', 'scheduled', 48724, 97.4, 'succeeded', NULL),
(343, '2026-06-29 03:03:17', 'ember', 'scheduled', 12574, 23.6, 'succeeded', NULL),
(344, '2026-06-29 05:33:24', 'harbor', 'scheduled', 29873, 56.1, 'succeeded', NULL),
(345, '2026-06-29 10:26:00', 'ember', 'interactive', 8426, 15.8, 'succeeded', NULL),
(346, '2026-06-30 02:15:13', 'lumen', 'scheduled', 49227, 100.1, 'succeeded', NULL),
(347, '2026-06-30 03:00:08', 'ember', 'scheduled', 12192, 22.9, 'succeeded', NULL),
(348, '2026-06-30 16:07:00', 'lumen', 'interactive', 15539, 29.2, 'succeeded', NULL),
(349, '2026-07-01 02:18:24', 'lumen', 'scheduled', 50938, 110.7, 'succeeded', NULL),
(350, '2026-07-01 03:01:15', 'ember', 'scheduled', 12912, 24.3, 'succeeded', NULL),
(351, '2026-07-01 09:18:00', 'lumen', 'interactive', 17727, 33.3, 'succeeded', NULL),
(352, '2026-07-02 02:18:46', 'lumen', 'scheduled', 48954, 98.6, 'succeeded', NULL),
(353, '2026-07-02 03:00:48', 'ember', 'scheduled', 12948, 24.3, 'succeeded', NULL),
(354, '2026-07-02 09:51:00', 'ember', 'interactive', 5454, 10.2, 'succeeded', NULL),
(355, '2026-07-03 02:15:36', 'lumen', 'scheduled', 47580, 92.2, 'succeeded', NULL),
(356, '2026-07-03 03:01:53', 'ember', 'scheduled', 12019, 22.6, 'succeeded', NULL),
(357, '2026-07-03 06:04:46', 'fieldnote', 'scheduled', 1655, 3.1, 'succeeded', NULL),
(358, '2026-07-03 12:59:00', 'fieldnote', 'interactive', 946, 1.8, 'succeeded', NULL),
(359, '2026-07-04 02:16:34', 'lumen', 'scheduled', 30827, 57.9, 'succeeded', NULL),
(360, '2026-07-04 03:00:30', 'ember', 'scheduled', 7947, 14.9, 'succeeded', NULL),
(361, '2026-07-05 02:18:09', 'lumen', 'scheduled', 27790, 52.2, 'succeeded', NULL),
(362, '2026-07-05 03:03:42', 'ember', 'scheduled', 6870, 12.9, 'succeeded', NULL),
(363, '2026-07-06 02:17:41', 'lumen', 'scheduled', 50274, 106.3, 'succeeded', NULL),
(364, '2026-07-06 03:01:44', 'ember', 'scheduled', 12643, 23.7, 'succeeded', NULL),
(365, '2026-07-06 05:34:34', 'harbor', 'scheduled', 29973, 56.3, 'succeeded', NULL),
(366, '2026-07-07 02:18:47', 'lumen', 'scheduled', 50931, 110.7, 'succeeded', NULL),
(367, '2026-07-07 03:03:18', 'ember', 'scheduled', 12433, 23.4, 'succeeded', NULL),
(368, '2026-07-08 02:15:10', 'lumen', 'scheduled', 52296, 120.0, 'failed', 'worker timeout after 120s'),
(369, '2026-07-08 03:00:50', 'ember', 'scheduled', 12537, 23.6, 'succeeded', NULL),
(370, '2026-07-08 08:54:28', 'lumen', 'interactive', 52248, 120.5, 'succeeded', NULL),
(371, '2026-07-09 02:17:34', 'lumen', 'scheduled', 49275, 100.3, 'succeeded', NULL),
(372, '2026-07-09 03:03:18', 'ember', 'scheduled', 12449, 23.4, 'succeeded', NULL),
(373, '2026-07-09 09:26:00', 'lumen', 'interactive', 12316, 23.1, 'succeeded', NULL),
(374, '2026-07-10 02:15:51', 'lumen', 'scheduled', 50331, 106.6, 'succeeded', NULL),
(375, '2026-07-10 03:00:16', 'ember', 'scheduled', 12608, 23.7, 'succeeded', NULL),
(376, '2026-07-10 06:00:49', 'fieldnote', 'scheduled', 1998, 3.8, 'succeeded', NULL),
(377, '2026-07-11 02:18:21', 'lumen', 'scheduled', 31919, 60.0, 'succeeded', NULL),
(378, '2026-07-11 03:03:49', 'ember', 'scheduled', 7929, 14.9, 'succeeded', NULL),
(379, '2026-07-12 02:17:34', 'lumen', 'scheduled', 27664, 52.0, 'succeeded', NULL),
(380, '2026-07-12 03:03:41', 'ember', 'scheduled', 6694, 12.6, 'succeeded', NULL),
(381, '2026-07-13 02:18:59', 'lumen', 'scheduled', 51098, 111.8, 'succeeded', NULL),
(382, '2026-07-13 03:02:23', 'ember', 'scheduled', 11919, 22.4, 'succeeded', NULL),
(383, '2026-07-13 05:31:09', 'harbor', 'scheduled', 30230, 56.8, 'succeeded', NULL),
(384, '2026-07-13 09:48:00', 'ember', 'interactive', 4496, 8.4, 'succeeded', NULL),
(385, '2026-07-14 02:17:44', 'lumen', 'scheduled', 52778, 120.0, 'failed', 'worker timeout after 120s'),
(386, '2026-07-14 03:03:27', 'ember', 'scheduled', 12227, 23.0, 'succeeded', NULL),
(387, '2026-07-14 08:51:48', 'lumen', 'interactive', 52368, 121.5, 'succeeded', NULL),
(388, '2026-07-14 09:45:00', 'harbor', 'interactive', 9567, 18.0, 'succeeded', NULL),
(389, '2026-07-15 02:17:10', 'lumen', 'scheduled', 52299, 120.0, 'failed', 'worker timeout after 120s'),
(390, '2026-07-15 03:03:36', 'ember', 'scheduled', 12731, 23.9, 'succeeded', NULL),
(391, '2026-07-15 08:54:33', 'lumen', 'interactive', 52123, 119.5, 'succeeded', NULL),
(392, '2026-07-16 02:16:51', 'lumen', 'scheduled', 52207, 120.0, 'failed', 'worker timeout after 120s'),
(393, '2026-07-16 03:02:22', 'ember', 'scheduled', 12591, 23.7, 'succeeded', NULL),
(394, '2026-07-16 08:48:22', 'lumen', 'interactive', 51795, 117.0, 'succeeded', NULL),
(395, '2026-07-16 09:43:00', 'fieldnote', 'interactive', 1781, 3.3, 'succeeded', NULL),
(396, '2026-07-17 02:17:21', 'lumen', 'scheduled', 50127, 105.4, 'succeeded', NULL),
(397, '2026-07-17 03:02:17', 'ember', 'scheduled', 13026, 24.5, 'succeeded', NULL),
(398, '2026-07-17 06:03:16', 'fieldnote', 'scheduled', 1744, 3.3, 'succeeded', NULL),
(399, '2026-07-17 09:57:00', 'harbor', 'interactive', 8993, 16.9, 'succeeded', NULL),
(400, '2026-07-18 02:17:25', 'lumen', 'scheduled', 30595, 57.5, 'succeeded', NULL);
INSERT INTO export_runs (run_id, started_at, customer_id, run_mode, row_count, duration_s, status, failure_reason) VALUES
(401, '2026-07-18 03:02:39', 'ember', 'scheduled', 7727, 14.5, 'succeeded', NULL),
(402, '2026-07-19 02:15:20', 'lumen', 'scheduled', 27768, 52.2, 'succeeded', NULL),
(403, '2026-07-19 03:01:09', 'ember', 'scheduled', 6639, 12.5, 'succeeded', NULL),
(404, '2026-07-20 02:16:35', 'lumen', 'scheduled', 50390, 107.0, 'succeeded', NULL),
(405, '2026-07-20 03:03:33', 'ember', 'scheduled', 12289, 23.1, 'succeeded', NULL),
(406, '2026-07-20 05:34:37', 'harbor', 'scheduled', 29446, 55.3, 'succeeded', NULL),
(407, '2026-07-20 16:23:00', 'lumen', 'interactive', 10268, 19.3, 'succeeded', NULL),
(408, '2026-07-21 02:17:00', 'lumen', 'scheduled', 51767, 116.7, 'succeeded', NULL),
(409, '2026-07-21 03:03:35', 'ember', 'scheduled', 12906, 24.2, 'succeeded', NULL),
(410, '2026-07-21 11:30:00', 'lumen', 'interactive', 14661, 27.5, 'succeeded', NULL),
(411, '2026-07-22 02:18:07', 'lumen', 'scheduled', 53351, 120.0, 'failed', 'worker timeout after 120s'),
(412, '2026-07-22 03:02:10', 'ember', 'scheduled', 13035, 24.5, 'succeeded', NULL),
(413, '2026-07-22 08:45:57', 'lumen', 'interactive', 53324, 129.7, 'succeeded', NULL),
(414, '2026-07-23 02:18:08', 'lumen', 'scheduled', 51194, 112.5, 'succeeded', NULL),
(415, '2026-07-23 03:02:08', 'ember', 'scheduled', 13333, 25.0, 'succeeded', NULL),
(416, '2026-07-24 02:16:31', 'lumen', 'scheduled', 50398, 107.1, 'succeeded', NULL),
(417, '2026-07-24 03:01:03', 'ember', 'scheduled', 12396, 23.3, 'succeeded', NULL),
(418, '2026-07-24 06:01:59', 'fieldnote', 'scheduled', 1843, 3.5, 'succeeded', NULL),
(419, '2026-07-25 02:17:18', 'lumen', 'scheduled', 32142, 60.4, 'succeeded', NULL),
(420, '2026-07-25 03:02:17', 'ember', 'scheduled', 7929, 14.9, 'succeeded', NULL),
(421, '2026-07-26 02:18:42', 'lumen', 'scheduled', 27717, 52.1, 'succeeded', NULL),
(422, '2026-07-26 03:02:56', 'ember', 'scheduled', 6881, 12.9, 'succeeded', NULL),
(423, '2026-07-27 02:16:59', 'lumen', 'scheduled', 51049, 111.5, 'succeeded', NULL),
(424, '2026-07-27 03:02:30', 'ember', 'scheduled', 12901, 24.2, 'succeeded', NULL),
(425, '2026-07-27 05:33:35', 'harbor', 'scheduled', 31364, 58.9, 'succeeded', NULL),
(426, '2026-07-27 12:33:00', 'fieldnote', 'interactive', 1161, 2.2, 'succeeded', NULL),
(427, '2026-07-28 02:15:57', 'lumen', 'scheduled', 52651, 120.0, 'failed', 'worker timeout after 120s'),
(428, '2026-07-28 03:03:40', 'ember', 'scheduled', 12169, 22.9, 'succeeded', NULL),
(429, '2026-07-28 08:53:07', 'lumen', 'interactive', 52558, 123.1, 'succeeded', NULL),
(430, '2026-07-29 02:15:29', 'lumen', 'scheduled', 51886, 117.7, 'succeeded', NULL),
(431, '2026-07-29 03:03:00', 'ember', 'scheduled', 13608, 25.6, 'succeeded', NULL),
(432, '2026-07-30 02:18:29', 'lumen', 'scheduled', 51402, 114.0, 'succeeded', NULL),
(433, '2026-07-30 03:03:58', 'ember', 'scheduled', 13434, 25.2, 'succeeded', NULL),
(434, '2026-07-31 02:17:55', 'lumen', 'scheduled', 50575, 108.2, 'succeeded', NULL),
(435, '2026-07-31 03:03:31', 'ember', 'scheduled', 12313, 23.1, 'succeeded', NULL),
(436, '2026-07-31 06:03:13', 'fieldnote', 'scheduled', 1611, 3.0, 'succeeded', NULL),
(437, '2026-07-31 10:06:00', 'fieldnote', 'interactive', 811, 1.5, 'succeeded', NULL),
(438, '2026-08-01 02:16:53', 'lumen', 'scheduled', 32985, 62.0, 'succeeded', NULL),
(439, '2026-08-01 03:03:01', 'ember', 'scheduled', 7405, 13.9, 'succeeded', NULL),
(440, '2026-08-02 02:15:26', 'lumen', 'scheduled', 29321, 55.1, 'succeeded', NULL),
(441, '2026-08-02 03:02:59', 'ember', 'scheduled', 7014, 13.2, 'succeeded', NULL),
(442, '2026-08-03 02:17:10', 'lumen', 'scheduled', 51173, 112.4, 'succeeded', NULL),
(443, '2026-08-03 03:01:19', 'ember', 'scheduled', 12417, 23.3, 'succeeded', NULL),
(444, '2026-08-03 05:33:34', 'harbor', 'scheduled', 29925, 56.2, 'succeeded', NULL),
(445, '2026-08-03 13:48:00', 'harbor', 'interactive', 5170, 9.7, 'succeeded', NULL),
(446, '2026-08-04 02:18:49', 'lumen', 'scheduled', 51929, 118.0, 'succeeded', NULL),
(447, '2026-08-04 03:01:09', 'ember', 'scheduled', 13530, 25.4, 'succeeded', NULL),
(448, '2026-08-04 16:58:00', 'lumen', 'interactive', 7179, 13.5, 'succeeded', NULL),
(449, '2026-08-05 02:18:31', 'lumen', 'scheduled', 52761, 120.0, 'failed', 'worker timeout after 120s'),
(450, '2026-08-05 03:01:40', 'ember', 'scheduled', 12563, 23.6, 'succeeded', NULL),
(451, '2026-08-05 08:40:58', 'lumen', 'interactive', 52586, 123.3, 'succeeded', NULL),
(452, '2026-08-05 13:44:00', 'fieldnote', 'interactive', 930, 0.7, 'cancelled', 'cancelled by the requester'),
(453, '2026-08-06 02:16:35', 'lumen', 'scheduled', 52945, 120.0, 'failed', 'worker timeout after 120s'),
(454, '2026-08-06 03:02:21', 'ember', 'scheduled', 12316, 23.1, 'succeeded', NULL),
(455, '2026-08-06 08:55:02', 'lumen', 'interactive', 53044, 127.2, 'succeeded', NULL),
(456, '2026-08-06 12:45:00', 'lumen', 'interactive', 7128, 13.4, 'succeeded', NULL),
(457, '2026-08-07 02:16:00', 'lumen', 'scheduled', 51280, 113.1, 'succeeded', NULL),
(458, '2026-08-07 03:02:21', 'ember', 'scheduled', 12024, 22.6, 'succeeded', NULL),
(459, '2026-08-07 06:00:31', 'fieldnote', 'scheduled', 1712, 3.2, 'succeeded', NULL),
(460, '2026-08-07 14:57:00', 'lumen', 'interactive', 16718, 31.4, 'succeeded', NULL),
(461, '2026-08-08 02:16:54', 'lumen', 'scheduled', 32251, 60.6, 'succeeded', NULL),
(462, '2026-08-08 03:00:19', 'ember', 'scheduled', 8072, 15.2, 'succeeded', NULL),
(463, '2026-08-09 02:16:49', 'lumen', 'scheduled', 28265, 53.1, 'succeeded', NULL),
(464, '2026-08-09 03:00:05', 'ember', 'scheduled', 6836, 12.8, 'succeeded', NULL),
(465, '2026-08-10 02:15:59', 'lumen', 'scheduled', 53535, 120.0, 'failed', 'worker timeout after 120s'),
(466, '2026-08-10 03:02:22', 'ember', 'scheduled', 12839, 24.1, 'succeeded', NULL),
(467, '2026-08-10 05:33:20', 'harbor', 'scheduled', 29969, 56.3, 'succeeded', NULL),
(468, '2026-08-10 08:55:31', 'lumen', 'interactive', 53864, 134.6, 'succeeded', NULL),
(469, '2026-08-10 15:35:00', 'harbor', 'interactive', 6253, 11.7, 'succeeded', NULL),
(470, '2026-08-11 02:17:26', 'lumen', 'scheduled', 52937, 120.0, 'failed', 'worker timeout after 120s'),
(471, '2026-08-11 03:00:44', 'ember', 'scheduled', 12861, 24.2, 'succeeded', NULL),
(472, '2026-08-11 08:50:53', 'lumen', 'interactive', 53039, 127.2, 'succeeded', NULL),
(473, '2026-08-11 14:49:00', 'lumen', 'interactive', 5979, 11.2, 'succeeded', NULL),
(474, '2026-08-12 02:15:49', 'lumen', 'scheduled', 54769, 120.0, 'failed', 'worker timeout after 120s'),
(475, '2026-08-12 03:03:51', 'ember', 'scheduled', 13584, 25.5, 'succeeded', NULL),
(476, '2026-08-12 08:45:18', 'lumen', 'interactive', 55237, 148.4, 'succeeded', NULL),
(477, '2026-08-12 09:26:00', 'lumen', 'interactive', 20402, 38.3, 'succeeded', NULL),
(478, '2026-08-13 02:18:29', 'lumen', 'scheduled', 53347, 120.0, 'failed', 'worker timeout after 120s'),
(479, '2026-08-13 03:01:07', 'ember', 'scheduled', 12453, 23.4, 'succeeded', NULL),
(480, '2026-08-13 08:55:12', 'lumen', 'interactive', 53843, 134.4, 'succeeded', NULL),
(481, '2026-08-14 02:17:45', 'lumen', 'scheduled', 53516, 120.0, 'failed', 'worker timeout after 120s'),
(482, '2026-08-14 03:02:42', 'ember', 'scheduled', 12296, 23.1, 'succeeded', NULL),
(483, '2026-08-14 06:04:07', 'fieldnote', 'scheduled', 1769, 3.3, 'succeeded', NULL),
(484, '2026-08-14 08:47:54', 'lumen', 'interactive', 53095, 127.6, 'succeeded', NULL),
(485, '2026-08-15 02:18:28', 'lumen', 'scheduled', 33590, 63.1, 'succeeded', NULL),
(486, '2026-08-15 03:00:38', 'ember', 'scheduled', 7645, 14.4, 'succeeded', NULL),
(487, '2026-08-16 02:18:45', 'lumen', 'scheduled', 29668, 55.7, 'succeeded', NULL),
(488, '2026-08-16 03:02:33', 'ember', 'scheduled', 7315, 13.7, 'succeeded', NULL),
(489, '2026-08-17 02:15:15', 'lumen', 'scheduled', 54317, 120.0, 'failed', 'worker timeout after 120s'),
(490, '2026-08-17 03:02:47', 'ember', 'scheduled', 12462, 23.4, 'succeeded', NULL),
(491, '2026-08-17 05:31:31', 'harbor', 'scheduled', 30865, 58.0, 'succeeded', NULL),
(492, '2026-08-17 08:49:05', 'lumen', 'interactive', 54647, 142.3, 'succeeded', NULL),
(493, '2026-08-18 02:16:12', 'lumen', 'scheduled', 56080, 120.0, 'failed', 'worker timeout after 120s'),
(494, '2026-08-18 03:00:06', 'ember', 'scheduled', 13604, 25.6, 'succeeded', NULL),
(495, '2026-08-18 08:42:46', 'lumen', 'interactive', 55992, 156.6, 'succeeded', NULL),
(496, '2026-08-19 02:18:34', 'lumen', 'scheduled', 56790, 120.0, 'failed', 'worker timeout after 120s'),
(497, '2026-08-19 03:04:00', 'ember', 'scheduled', 12567, 23.6, 'succeeded', NULL),
(498, '2026-08-19 08:47:31', 'lumen', 'interactive', 56604, 163.7, 'succeeded', NULL),
(499, '2026-08-19 12:08:00', 'ember', 'interactive', 6049, 11.4, 'succeeded', NULL),
(500, '2026-08-20 02:16:44', 'lumen', 'scheduled', 55574, 120.0, 'failed', 'worker timeout after 120s');
INSERT INTO export_runs (run_id, started_at, customer_id, run_mode, row_count, duration_s, status, failure_reason) VALUES
(501, '2026-08-20 03:02:03', 'ember', 'scheduled', 13496, 25.4, 'succeeded', NULL),
(502, '2026-08-20 08:41:31', 'lumen', 'interactive', 55889, 155.5, 'succeeded', NULL),
(503, '2026-08-20 15:21:00', 'lumen', 'interactive', 12165, 22.9, 'succeeded', NULL),
(504, '2026-08-21 02:16:09', 'lumen', 'scheduled', 52708, 120.0, 'failed', 'worker timeout after 120s'),
(505, '2026-08-21 03:00:37', 'ember', 'scheduled', 11752, 22.1, 'succeeded', NULL),
(506, '2026-08-21 06:02:36', 'fieldnote', 'scheduled', 2111, 4.0, 'succeeded', NULL),
(507, '2026-08-21 08:53:56', 'lumen', 'interactive', 52290, 120.9, 'succeeded', NULL);
CREATE TABLE calendar_events (
  id TEXT PRIMARY KEY,
  summary TEXT NOT NULL,
  description TEXT NOT NULL,
  starts_at TEXT NOT NULL,
  ends_at TEXT NOT NULL,
  attendees TEXT NOT NULL
);
INSERT INTO calendar_events (id, summary, description, starts_at, ends_at, attendees) VALUES
('event-lumen-review', 'Lumen renewal review', 'Renewal, export reliability, usage growth, and next-quarter plan.', '2026-08-25 13:00:00', '2026-08-25 13:45:00', 'maya@northstar-relay.invalid, david@northstar-relay.invalid, priya@lumen-labs.invalid'),
('event-release-go-no-go', '2.8 go or no-go', 'Decide whether the export timeout fix enters 2.8.', '2026-08-24 11:30:00', '2026-08-24 12:00:00', 'jon@northstar-relay.invalid, elena@northstar-relay.invalid, lucas@northstar-relay.invalid'),
('event-theo-welcome', 'Welcome Theo', 'Introductions, first-week plan, and access check.', '2026-08-24 09:30:00', '2026-08-24 10:00:00', 'theo@northstar-relay.invalid, imani@northstar-relay.invalid, jon@northstar-relay.invalid');
CREATE TABLE chat_messages (
  id TEXT PRIMARY KEY,
  channel TEXT NOT NULL,
  author_person_id TEXT REFERENCES people(id),
  sent_at TEXT NOT NULL,
  text TEXT NOT NULL
);
INSERT INTO chat_messages (id, channel, author_person_id, sent_at, text) VALUES
('chat-general-0819', 'general', 'imani-brooks', '2026-08-19 15:42:00', 'Theo''s onboarding page is ready. Staging access is the only unchecked item; I left the owner blank because I do not know whether Jon or Lucas is handling it.'),
('chat-general-0820', 'general', 'noor-alvarez', '2026-08-20 08:17:00', 'Friday reminder: please submit August expenses before 16:00. Missing receipts can wait until Monday; the amount and customer still need to be entered today.'),
('chat-lumen-001', 'lumen-renewal', 'samira-okafor', '2026-08-20 09:06:00', 'Priya sent a useful boundary: 48k rows finishes in 1m34s; 52k reaches the two-minute worker limit. Interactive retry works, scheduled retry does not.'),
('chat-lumen-002', 'lumen-renewal', 'lucas-meyer', '2026-08-20 09:18:00', 'I can reproduce it. The scheduler still passes the old timeout to the export worker. Fix is small; the load test is not.'),
('chat-lumen-003', 'lumen-renewal', 'jon-bell', '2026-08-20 09:31:00', 'Please do not merge on the small fixture alone. Run 50k, 75k, and a cancelled job. If cancellation leaks workers, 2.8 waits.'),
('chat-lumen-004', 'lumen-renewal', 'noor-alvarez', '2026-08-20 10:02:00', 'Account note: invoice 4471 is open, but it is not overdue until the 30th. Keep billing out of the incident reply unless Priya asks.'),
('chat-release-001', 'release-2-8', 'elena-petrov', '2026-08-20 13:10:00', 'Audit page copy is final. Export timeout is the only item that can still change the release date. I need a go or no-go by Monday noon.'),
('chat-release-002', 'release-2-8', 'hana-ito', '2026-08-20 13:22:00', 'The audit page review found one timezone label bug. It is visual only; I opened 322 and kept it out of the export branch.');
CREATE TABLE email_messages (
  id TEXT PRIMARY KEY,
  thread_id TEXT,
  subject TEXT NOT NULL,
  from_person_id TEXT REFERENCES people(id),
  to_person_ids TEXT NOT NULL,
  sent_at TEXT NOT NULL,
  labels TEXT,
  customer_id TEXT REFERENCES customers(id),
  invoice_number TEXT,
  body TEXT NOT NULL
);
INSERT INTO email_messages (id, thread_id, subject, from_person_id, to_person_ids, sent_at, labels, customer_id, invoice_number, body) VALUES
('mail-inv-202508-ember', 'thread-inv-202508-ember', 'Invoice 2508-42 — Ember Commerce', 'noor-alvarez', 'ravi-okonkwo', '2025-08-05 09:15:00', 'SENT, Finance', 'ember', 'inv-202508-ember', 'Hi Ravi,

Invoice 2508-42 for Northstar Growth plan is attached. The total is 289.00 USD, due 2025-09-05.

Noor Alvarez'),
('mail-inv-202508-fieldnote', 'thread-inv-202508-fieldnote', 'Invoice 2508-18 — Fieldnote Studio', 'noor-alvarez', 'marta-silva', '2025-08-08 09:15:00', 'SENT, Finance', 'fieldnote', 'inv-202508-fieldnote', 'Hi Marta,

Invoice 2508-18 for Northstar Team plan is attached. The total is 99.00 USD, due 2025-09-08.

Noor Alvarez'),
('mail-inv-202508-harbor', 'thread-inv-202508-harbor', 'Invoice 2508-63 — Harbor Mobility', 'noor-alvarez', 'owen-price', '2025-08-11 09:15:00', 'SENT, Finance', 'harbor', 'inv-202508-harbor', 'Hi Owen,

Invoice 2508-63 for Northstar Scale plan is attached. The total is 356.00 USD, due 2025-09-11.

Noor Alvarez'),
('mail-inv-202508-lumen', 'thread-inv-202508-lumen', 'Invoice 2508-71 — Lumen Labs', 'noor-alvarez', 'priya-raman', '2025-08-14 09:15:00', 'SENT, Finance', 'lumen', 'inv-202508-lumen', 'Hi Priya,

Invoice 2508-71 for Northstar Scale plan is attached. The total is 412.00 USD, due 2025-09-30.

Noor Alvarez'),
('mail-inv-202509-ember', 'thread-inv-202509-ember', 'Invoice 2509-42 — Ember Commerce', 'noor-alvarez', 'ravi-okonkwo', '2025-09-05 09:15:00', 'SENT, Finance', 'ember', 'inv-202509-ember', 'Hi Ravi,

Invoice 2509-42 for Northstar Growth plan is attached. The total is 289.00 USD, due 2025-10-05.

Noor Alvarez'),
('mail-inv-202509-fieldnote', 'thread-inv-202509-fieldnote', 'Invoice 2509-18 — Fieldnote Studio', 'noor-alvarez', 'marta-silva', '2025-09-08 09:15:00', 'SENT, Finance', 'fieldnote', 'inv-202509-fieldnote', 'Hi Marta,

Invoice 2509-18 for Northstar Team plan is attached. The total is 99.00 USD, due 2025-10-08.

Noor Alvarez'),
('mail-inv-202509-harbor', 'thread-inv-202509-harbor', 'Invoice 2509-63 — Harbor Mobility', 'noor-alvarez', 'owen-price', '2025-09-11 09:15:00', 'SENT, Finance', 'harbor', 'inv-202509-harbor', 'Hi Owen,

Invoice 2509-63 for Northstar Scale plan is attached. The total is 356.00 USD, due 2025-10-11.

Noor Alvarez'),
('mail-inv-202509-lumen', 'thread-inv-202509-lumen', 'Invoice 2509-71 — Lumen Labs', 'noor-alvarez', 'priya-raman', '2025-09-14 09:15:00', 'SENT, Finance', 'lumen', 'inv-202509-lumen', 'Hi Priya,

Invoice 2509-71 for Northstar Scale plan is attached. The total is 412.00 USD, due 2025-10-30.

Noor Alvarez'),
('mail-inv-202510-ember', 'thread-inv-202510-ember', 'Invoice 2510-42 — Ember Commerce', 'noor-alvarez', 'ravi-okonkwo', '2025-10-05 09:15:00', 'SENT, Finance', 'ember', 'inv-202510-ember', 'Hi Ravi,

Invoice 2510-42 for Northstar Growth plan is attached. The total is 289.00 USD, due 2025-11-05.

Noor Alvarez'),
('mail-inv-202510-fieldnote', 'thread-inv-202510-fieldnote', 'Invoice 2510-18 — Fieldnote Studio', 'noor-alvarez', 'marta-silva', '2025-10-08 09:15:00', 'SENT, Finance', 'fieldnote', 'inv-202510-fieldnote', 'Hi Marta,

Invoice 2510-18 for Northstar Team plan is attached. The total is 99.00 USD, due 2025-11-08.

Noor Alvarez'),
('mail-inv-202510-harbor', 'thread-inv-202510-harbor', 'Invoice 2510-63 — Harbor Mobility', 'noor-alvarez', 'owen-price', '2025-10-11 09:15:00', 'SENT, Finance', 'harbor', 'inv-202510-harbor', 'Hi Owen,

Invoice 2510-63 for Northstar Scale plan is attached. The total is 356.00 USD, due 2025-11-11.

Noor Alvarez'),
('mail-inv-202510-lumen', 'thread-inv-202510-lumen', 'Invoice 2510-71 — Lumen Labs', 'noor-alvarez', 'priya-raman', '2025-10-14 09:15:00', 'SENT, Finance', 'lumen', 'inv-202510-lumen', 'Hi Priya,

Invoice 2510-71 for Northstar Scale plan is attached. The total is 412.00 USD, due 2025-11-30.

Noor Alvarez'),
('mail-inv-202511-ember', 'thread-inv-202511-ember', 'Invoice 2511-42 — Ember Commerce', 'noor-alvarez', 'ravi-okonkwo', '2025-11-05 09:15:00', 'SENT, Finance', 'ember', 'inv-202511-ember', 'Hi Ravi,

Invoice 2511-42 for Northstar Growth plan is attached. The total is 289.00 USD, due 2025-12-05.

Noor Alvarez'),
('mail-inv-202511-fieldnote', 'thread-inv-202511-fieldnote', 'Invoice 2511-18 — Fieldnote Studio', 'noor-alvarez', 'marta-silva', '2025-11-08 09:15:00', 'SENT, Finance', 'fieldnote', 'inv-202511-fieldnote', 'Hi Marta,

Invoice 2511-18 for Northstar Team plan is attached. The total is 99.00 USD, due 2025-12-08.

Noor Alvarez'),
('mail-inv-202511-harbor', 'thread-inv-202511-harbor', 'Invoice 2511-63 — Harbor Mobility', 'noor-alvarez', 'owen-price', '2025-11-11 09:15:00', 'SENT, Finance', 'harbor', 'inv-202511-harbor', 'Hi Owen,

Invoice 2511-63 for Northstar Scale plan is attached. The total is 356.00 USD, due 2025-12-11.

Noor Alvarez'),
('mail-inv-202511-lumen', 'thread-inv-202511-lumen', 'Invoice 2511-71 — Lumen Labs', 'noor-alvarez', 'priya-raman', '2025-11-14 09:15:00', 'SENT, Finance', 'lumen', 'inv-202511-lumen', 'Hi Priya,

Invoice 2511-71 for Northstar Scale plan is attached. The total is 412.00 USD, due 2025-12-30.

Noor Alvarez'),
('mail-inv-202512-ember', 'thread-inv-202512-ember', 'Invoice 2512-42 — Ember Commerce', 'noor-alvarez', 'ravi-okonkwo', '2025-12-05 09:15:00', 'SENT, Finance', 'ember', 'inv-202512-ember', 'Hi Ravi,

Invoice 2512-42 for Northstar Growth plan is attached. The total is 289.00 USD, due 2026-01-05.

Noor Alvarez'),
('mail-inv-202512-fieldnote', 'thread-inv-202512-fieldnote', 'Invoice 2512-18 — Fieldnote Studio', 'noor-alvarez', 'marta-silva', '2025-12-08 09:15:00', 'SENT, Finance', 'fieldnote', 'inv-202512-fieldnote', 'Hi Marta,

Invoice 2512-18 for Northstar Team plan is attached. The total is 99.00 USD, due 2026-01-08.

Noor Alvarez'),
('mail-inv-202512-harbor', 'thread-inv-202512-harbor', 'Invoice 2512-63 — Harbor Mobility', 'noor-alvarez', 'owen-price', '2025-12-11 09:15:00', 'SENT, Finance', 'harbor', 'inv-202512-harbor', 'Hi Owen,

Invoice 2512-63 for Northstar Scale plan is attached. The total is 356.00 USD, due 2026-01-11.

Noor Alvarez'),
('mail-inv-202512-lumen', 'thread-inv-202512-lumen', 'Invoice 2512-71 — Lumen Labs', 'noor-alvarez', 'priya-raman', '2025-12-14 09:15:00', 'SENT, Finance', 'lumen', 'inv-202512-lumen', 'Hi Priya,

Invoice 2512-71 for Northstar Scale plan is attached. The total is 412.00 USD, due 2026-01-30.

Noor Alvarez'),
('mail-inv-202601-ember', 'thread-inv-202601-ember', 'Invoice 2601-42 — Ember Commerce', 'noor-alvarez', 'ravi-okonkwo', '2026-01-05 09:15:00', 'SENT, Finance', 'ember', 'inv-202601-ember', 'Hi Ravi,

Invoice 2601-42 for Northstar Growth plan is attached. The total is 289.00 USD, due 2026-02-05.

Noor Alvarez'),
('mail-inv-202601-fieldnote', 'thread-inv-202601-fieldnote', 'Invoice 2601-18 — Fieldnote Studio', 'noor-alvarez', 'marta-silva', '2026-01-08 09:15:00', 'SENT, Finance', 'fieldnote', 'inv-202601-fieldnote', 'Hi Marta,

Invoice 2601-18 for Northstar Team plan is attached. The total is 99.00 USD, due 2026-02-08.

Noor Alvarez'),
('mail-inv-202601-harbor', 'thread-inv-202601-harbor', 'Invoice 2601-63 — Harbor Mobility', 'noor-alvarez', 'owen-price', '2026-01-11 09:15:00', 'SENT, Finance', 'harbor', 'inv-202601-harbor', 'Hi Owen,

Invoice 2601-63 for Northstar Scale plan is attached. The total is 356.00 USD, due 2026-02-11.

Noor Alvarez'),
('mail-inv-202601-lumen', 'thread-inv-202601-lumen', 'Invoice 2601-71 — Lumen Labs', 'noor-alvarez', 'priya-raman', '2026-01-14 09:15:00', 'SENT, Finance', 'lumen', 'inv-202601-lumen', 'Hi Priya,

Invoice 2601-71 for Northstar Scale plan is attached. The total is 412.00 USD, due 2026-02-28.

Noor Alvarez'),
('mail-inv-202602-ember', 'thread-inv-202602-ember', 'Invoice 2602-42 — Ember Commerce', 'noor-alvarez', 'ravi-okonkwo', '2026-02-05 09:15:00', 'SENT, Finance', 'ember', 'inv-202602-ember', 'Hi Ravi,

Invoice 2602-42 for Northstar Growth plan is attached. The total is 289.00 USD, due 2026-03-05.

Noor Alvarez'),
('mail-inv-202602-fieldnote', 'thread-inv-202602-fieldnote', 'Invoice 2602-18 — Fieldnote Studio', 'noor-alvarez', 'marta-silva', '2026-02-08 09:15:00', 'SENT, Finance', 'fieldnote', 'inv-202602-fieldnote', 'Hi Marta,

Invoice 2602-18 for Northstar Team plan is attached. The total is 99.00 USD, due 2026-03-08.

Noor Alvarez'),
('mail-inv-202602-harbor', 'thread-inv-202602-harbor', 'Invoice 2602-63 — Harbor Mobility', 'noor-alvarez', 'owen-price', '2026-02-11 09:15:00', 'SENT, Finance', 'harbor', 'inv-202602-harbor', 'Hi Owen,

Invoice 2602-63 for Northstar Scale plan is attached. The total is 356.00 USD, due 2026-03-11.

Noor Alvarez'),
('mail-inv-202602-lumen', 'thread-inv-202602-lumen', 'Invoice 2602-71 — Lumen Labs', 'noor-alvarez', 'priya-raman', '2026-02-14 09:15:00', 'SENT, Finance', 'lumen', 'inv-202602-lumen', 'Hi Priya,

Invoice 2602-71 for Northstar Scale plan is attached. The total is 412.00 USD, due 2026-03-30.

Noor Alvarez'),
('mail-inv-202603-ember', 'thread-inv-202603-ember', 'Invoice 2603-42 — Ember Commerce', 'noor-alvarez', 'ravi-okonkwo', '2026-03-05 09:15:00', 'SENT, Finance', 'ember', 'inv-202603-ember', 'Hi Ravi,

Invoice 2603-42 for Northstar Growth plan is attached. The total is 289.00 USD, due 2026-04-05.

Noor Alvarez'),
('mail-inv-202603-fieldnote', 'thread-inv-202603-fieldnote', 'Invoice 2603-18 — Fieldnote Studio', 'noor-alvarez', 'marta-silva', '2026-03-08 09:15:00', 'SENT, Finance', 'fieldnote', 'inv-202603-fieldnote', 'Hi Marta,

Invoice 2603-18 for Northstar Team plan is attached. The total is 99.00 USD, due 2026-04-08.

Noor Alvarez'),
('mail-inv-202603-harbor', 'thread-inv-202603-harbor', 'Invoice 2603-63 — Harbor Mobility', 'noor-alvarez', 'owen-price', '2026-03-11 09:15:00', 'SENT, Finance', 'harbor', 'inv-202603-harbor', 'Hi Owen,

Invoice 2603-63 for Northstar Scale plan is attached. The total is 356.00 USD, due 2026-04-11.

Noor Alvarez'),
('mail-inv-202603-lumen', 'thread-inv-202603-lumen', 'Invoice 2603-71 — Lumen Labs', 'noor-alvarez', 'priya-raman', '2026-03-14 09:15:00', 'SENT, Finance', 'lumen', 'inv-202603-lumen', 'Hi Priya,

Invoice 2603-71 for Northstar Scale plan is attached. The total is 412.00 USD, due 2026-04-30.

Noor Alvarez'),
('mail-inv-202604-ember', 'thread-inv-202604-ember', 'Invoice 2604-42 — Ember Commerce', 'noor-alvarez', 'ravi-okonkwo', '2026-04-05 09:15:00', 'SENT, Finance', 'ember', 'inv-202604-ember', 'Hi Ravi,

Invoice 2604-42 for Northstar Growth plan is attached. The total is 289.00 USD, due 2026-05-05.

Noor Alvarez'),
('mail-inv-202604-fieldnote', 'thread-inv-202604-fieldnote', 'Invoice 2604-18 — Fieldnote Studio', 'noor-alvarez', 'marta-silva', '2026-04-08 09:15:00', 'SENT, Finance', 'fieldnote', 'inv-202604-fieldnote', 'Hi Marta,

Invoice 2604-18 for Northstar Team plan is attached. The total is 99.00 USD, due 2026-05-08.

Noor Alvarez'),
('mail-inv-202604-harbor', 'thread-inv-202604-harbor', 'Invoice 2604-63 — Harbor Mobility', 'noor-alvarez', 'owen-price', '2026-04-11 09:15:00', 'SENT, Finance', 'harbor', 'inv-202604-harbor', 'Hi Owen,

Invoice 2604-63 for Northstar Scale plan is attached. The total is 356.00 USD, due 2026-05-11.

Noor Alvarez'),
('mail-inv-202604-lumen', 'thread-inv-202604-lumen', 'Invoice 2604-71 — Lumen Labs', 'noor-alvarez', 'priya-raman', '2026-04-14 09:15:00', 'SENT, Finance', 'lumen', 'inv-202604-lumen', 'Hi Priya,

Invoice 2604-71 for Northstar Scale plan is attached. The total is 412.00 USD, due 2026-05-30.

Noor Alvarez'),
('mail-inv-202605-ember', 'thread-inv-202605-ember', 'Invoice 2605-42 — Ember Commerce', 'noor-alvarez', 'ravi-okonkwo', '2026-05-05 09:15:00', 'SENT, Finance', 'ember', 'inv-202605-ember', 'Hi Ravi,

Invoice 2605-42 for Northstar Growth plan is attached. The total is 289.00 USD, due 2026-06-05.

Noor Alvarez'),
('mail-inv-202605-fieldnote', 'thread-inv-202605-fieldnote', 'Invoice 2605-18 — Fieldnote Studio', 'noor-alvarez', 'marta-silva', '2026-05-08 09:15:00', 'SENT, Finance', 'fieldnote', 'inv-202605-fieldnote', 'Hi Marta,

Invoice 2605-18 for Northstar Team plan is attached. The total is 99.00 USD, due 2026-06-08.

Noor Alvarez'),
('mail-inv-202605-harbor', 'thread-inv-202605-harbor', 'Invoice 2605-63 — Harbor Mobility', 'noor-alvarez', 'owen-price', '2026-05-11 09:15:00', 'SENT, Finance', 'harbor', 'inv-202605-harbor', 'Hi Owen,

Invoice 2605-63 for Northstar Scale plan is attached. The total is 356.00 USD, due 2026-06-11.

Noor Alvarez'),
('mail-inv-202605-lumen', 'thread-inv-202605-lumen', 'Invoice 2605-71 — Lumen Labs', 'noor-alvarez', 'priya-raman', '2026-05-14 09:15:00', 'SENT, Finance', 'lumen', 'inv-202605-lumen', 'Hi Priya,

Invoice 2605-71 for Northstar Scale plan is attached. The total is 412.00 USD, due 2026-06-30.

Noor Alvarez'),
('mail-inv-202606-ember', 'thread-inv-202606-ember', 'Invoice 2606-42 — Ember Commerce', 'noor-alvarez', 'ravi-okonkwo', '2026-06-05 09:15:00', 'SENT, Finance', 'ember', 'inv-202606-ember', 'Hi Ravi,

Invoice 2606-42 for Northstar Growth plan is attached. The total is 289.00 USD, due 2026-07-05.

Noor Alvarez'),
('mail-inv-202606-fieldnote', 'thread-inv-202606-fieldnote', 'Invoice 2606-18 — Fieldnote Studio', 'noor-alvarez', 'marta-silva', '2026-06-08 09:15:00', 'SENT, Finance', 'fieldnote', 'inv-202606-fieldnote', 'Hi Marta,

Invoice 2606-18 for Northstar Team plan is attached. The total is 99.00 USD, due 2026-07-08.

Noor Alvarez'),
('mail-inv-202606-harbor', 'thread-inv-202606-harbor', 'Invoice 2606-63 — Harbor Mobility', 'noor-alvarez', 'owen-price', '2026-06-11 09:15:00', 'SENT, Finance', 'harbor', 'inv-202606-harbor', 'Hi Owen,

Invoice 2606-63 for Northstar Scale plan is attached. The total is 356.00 USD, due 2026-07-11.

Noor Alvarez'),
('mail-inv-202606-lumen', 'thread-inv-202606-lumen', 'Invoice 2606-71 — Lumen Labs', 'noor-alvarez', 'priya-raman', '2026-06-14 09:15:00', 'SENT, Finance', 'lumen', 'inv-202606-lumen', 'Hi Priya,

Invoice 2606-71 for Northstar Scale plan is attached. The total is 412.00 USD, due 2026-07-30.

Noor Alvarez'),
('mail-inv-202607-ember', 'thread-inv-202607-ember', 'Invoice 2607-42 — Ember Commerce', 'noor-alvarez', 'ravi-okonkwo', '2026-07-05 09:15:00', 'SENT, Finance', 'ember', 'inv-202607-ember', 'Hi Ravi,

Invoice 2607-42 for Northstar Growth plan is attached. The total is 289.00 USD, due 2026-08-05.

Noor Alvarez'),
('mail-inv-202607-fieldnote', 'thread-inv-202607-fieldnote', 'Invoice 2607-18 — Fieldnote Studio', 'noor-alvarez', 'marta-silva', '2026-07-08 09:15:00', 'SENT, Finance', 'fieldnote', 'inv-202607-fieldnote', 'Hi Marta,

Invoice 2607-18 for Northstar Team plan is attached. The total is 99.00 USD, due 2026-08-08.

Noor Alvarez'),
('mail-inv-202607-harbor', 'thread-inv-202607-harbor', 'Invoice 2607-63 — Harbor Mobility', 'noor-alvarez', 'owen-price', '2026-07-11 09:15:00', 'SENT, Finance', 'harbor', 'inv-202607-harbor', 'Hi Owen,

Invoice 2607-63 for Northstar Scale plan is attached. The total is 356.00 USD, due 2026-08-11.

Noor Alvarez'),
('mail-inv-202607-lumen', 'thread-inv-202607-lumen', 'Invoice 2607-71 — Lumen Labs', 'noor-alvarez', 'priya-raman', '2026-07-14 09:15:00', 'SENT, Finance', 'lumen', 'inv-202607-lumen', 'Hi Priya,

Invoice 2607-71 for Northstar Scale plan is attached. The total is 412.00 USD, due 2026-08-30.

Noor Alvarez'),
('mail-inv-4471', 'thread-inv-4471', 'Invoice 4471 — Lumen Labs', 'noor-alvarez', 'priya-raman', '2026-08-14 09:15:00', 'SENT, Finance', 'lumen', 'inv-4471', 'Hi Priya,

Invoice 4471 for Northstar Scale plan — August is attached. The total is 412.00 USD, due 2026-08-30.

Noor Alvarez'),
('mail-fern-chair', 'thread-chair-delivery', 'Delivery window for Theo''s chair', 'fern-ellery', 'maya-chen', '2026-08-20 12:14:00', 'INBOX, Operations', NULL, NULL, 'Hello Maya,

The courier moved the delivery to Monday between 08:00 and 10:00. The desk riser is in the same shipment. No signature is required.

Fern'),
('mail-david-brief', 'thread-lumen-renewal', 'Draft Lumen renewal brief — needs the technical paragraph', 'david-banerjee', 'maya-chen', '2026-08-20 16:28:00', 'INBOX, Customers', 'lumen', NULL, 'Commercial section is done. Usage grew 38% since February and they added the compliance workspace in June.

I left the export incident paragraph marked in yellow. Please replace it after Jon decides whether the fix is in 2.8.

David'),
('mail-newsletter', 'thread-newsletter-aug21', 'CloudHarbor weekly: queues, regions, and maintenance', 'adil-hassan', 'maya-chen', '2026-08-21 05:00:00', 'INBOX, Newsletters', NULL, NULL, 'This week: queue visibility metrics, a new Paris region, and planned maintenance in Toronto. Northstar''s London workloads are not affected.

You receive this because you are an account owner.'),
('mail-priya-export', 'thread-lumen-export', 'Export is still timing out on our scheduled account run', 'priya-raman', 'maya-chen', '2026-08-21 07:42:00', 'INBOX, UNREAD, Customers', 'lumen', NULL, 'Hi Maya,

The manual retry Samira suggested finished, but last night''s scheduled export stopped at exactly two minutes again. We are using the same saved export with 52,184 rows.

I have a renewal review on Tuesday. I do not need a final fix before then, but I do need a clear workaround and an honest date.

Priya'),
('mail-noor-invoice-note', 'thread-invoice-4471-internal', 'Lumen account note before Tuesday', 'noor-alvarez', 'maya-chen', '2026-08-21 08:03:00', 'INBOX, UNREAD, Finance', 'lumen', 'inv-4471', 'Maya,

For the renewal brief: invoice 4471 is open for 412.00 USD and due on 30 August. It is not late. Priya confirmed the billing address last week, so there is no finance action unless it remains open after month-end.

Noor'),
('mail-maya-priya-reply', 'thread-lumen-export', 'Re: Export is still timing out on our scheduled account run', 'maya-chen', 'priya-raman', '2026-08-21 08:26:00', 'SENT, Customers', 'lumen', NULL, 'Hi Priya,

We reproduced the difference between manual and scheduled runs. The scheduler is passing the old two-minute limit to the worker.

We are testing the focused fix against larger exports and cancellation today. Samira will send you a safe workaround before 15:00, even if the release date is not final by then.

Maya');
CREATE TABLE documents (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  owner_person_id TEXT REFERENCES people(id),
  modified_at TEXT NOT NULL,
  content TEXT NOT NULL
);
INSERT INTO documents (id, name, owner_person_id, modified_at, content) VALUES
('doc-lumen-renewal', 'Lumen renewal brief — working draft.md', 'david-banerjee', '2026-08-20 16:25:00', '# Lumen Labs renewal

Usage is up 38% since February. Compliance workspace added in June.

## Export incident

TODO: Replace after engineering go/no-go. Do not promise 2.8 until load and cancellation tests pass.

## Billing

Invoice 4471: 412.00 USD, open, due 30 August. Not overdue.'),
('doc-theo-onboarding', 'Theo — first week.md', 'imani-brooks', '2026-08-19 15:39:00', '# Theo''s first week

- [x] Laptop
- [x] Email and chat
- [ ] Staging access — owner not assigned
- [x] Architecture session with Jon
- [x] Pairing block with Hana
');
COMMIT;
PRAGMA foreign_keys = ON;
